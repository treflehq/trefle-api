require 'yaml'
require 'terminal-table'
require 'httparty'

# A multi-value correction field is published as `anyOf` (an array, a single
# value, or several values joined by "|"). The table wants one row, so describe
# it from the branch carrying the enum. Without this every multi-value field
# -- duration, the colors, the months, edible_part -- rendered as an empty cell
# with no type and no list of accepted values.
def unwrap_any_of(val)
  return val unless val.is_a?(Hash) && val['anyOf']

  val['anyOf'].find {|branch| branch['enum'] } || val['anyOf'].first
end

def gen_description(val)
  val = unwrap_any_of(val)
  base = [
    val['description']
  ]

  base << "Can be: #{val['enum'].compact.map {|e| "`#{e}`" }.to_sentence}." if val['enum']
  base.compact.join("\n")
end

def gen_type(val)
  val = unwrap_any_of(val)
  return "array of #{val.dig('items', 'type').pluralize}" if val['type'] == 'array' && val.dig('items', 'type')

  val['type']
end

def parse_json_resp(k, val, fk = nil)
  return nil unless k

  elts = [
    [fk, k].compact.join('.')
  ]

  val.each {|pk, pv| elts << parse_json_resp(pk, pv, [*fk, k]) } if val.is_a?(Hash)
  if val.is_a?(Array)
    e = val.first
    elts << parse_json_resp("#{k}[]", e, [*fk]) if e
  end
  elts.compact.flatten.flatten
end

def parse_tree(k, val, fk = nil, level = 0)
  return if level > 1

  elts = [
    {
      name: [fk, k].compact.join('.'),
      type: gen_type(val),
      description: gen_description(val)
    }
  ]

  val['properties'].each {|pk, pv| elts << parse_tree(pk, pv, [*fk, k], level + 1) } if val['type'] == 'object' && val['properties']
  val['items']['properties'].each {|pk, pv| elts << parse_tree(pk, pv, [*fk, "#{k}[]"], level + 1) } if val['type'] == 'array' && val['items'] && val['items']['properties']
  elts
end

# The generated spec refers to shared schemas ($ref) rather than inlining them,
# so a walker that only follows `properties` stops at the reference and reports
# every key behind it as undocumented. Inline them first.
def resolve_refs(node, root, seen = [])
  return node.map {|v| resolve_refs(v, root, seen) } if node.is_a?(Array)
  return node unless node.is_a?(Hash)

  resolve_hash_refs(node, root, seen)
end

def resolve_hash_refs(node, root, seen)
  ref = node['$ref']
  return node.transform_values {|v| resolve_refs(v, root, seen) } unless ref
  return node if seen.include?(ref) # a self-referencing schema would loop

  target = ref.delete_prefix('#/').split('/').inject(root) {|acc, key| acc && acc[key] }
  resolve_refs(node.except('$ref').merge(target || {}), root, seen + [ref])
end

def group_categories(keys)
  a = keys.group_by {|e| e[:name].split('.').first }
  keys.group_by {|e| a[e[:name].split('.').first].length > 1 ? e[:name].split('.').first : :root }
end

namespace :doc do # rubocop:todo Metrics/BlockLength

  desc 'Check fields between API and swagger'
  task check: :environment do
    data = SpeciesSerializer.new.serialize(Species.where.not(average_height_cm: nil).first).to_h
    schema = YAML.load_file(Rails.root.join('public/swagger/v1/swagger.yaml'))
    schema = resolve_refs(schema, schema)

    json_elts = data.map {|k, val| parse_json_resp(k, val) }.flatten.sort
    swag_elts = schema['components']['schemas'].slice('species').map do |_name, attrs|
      attrs['properties'].map {|n, a| parse_tree(n, a, nil, -10) }.flatten.compact.map {|e| e[:name] }
    end.flatten.compact.sort

    json_elts = json_elts.reject {|e| e.match(/\[\]$/) }
      .reject {|e| e.match(/^\./) }
      .reject {|e| e.match(/^common_names\./) }
      .reject {|e| e.match(/^distribution\./) }

    puts 'Missing elements in swagger:'.red
    (json_elts - swag_elts).each do |e|
      puts "- #{e}".red
    end
    puts 'Missing elements in json response:'.blue
    (swag_elts - json_elts).each do |e|
      puts "- #{e}".blue
    end
  end

  desc 'Generate species
markdown specs from swagger'
  task generate_spec: :environment do # rubocop:todo Metrics/BlockLength

    md = []
    md << <<~DESC
      ---
      id: plants-fields
      title: Plants fields
      ---

      When you query a species (or a plant), you will have a lot of fields to dig into. This is a simplified version of the [reference](/reference) that tries to explain a bit what each fields represents.

      :::tip In doubt, refer to the reference
      This documentation is way lighter than the reference, and do not show all the fields. If you have any doubt, please check the [reference](/reference).
      :::
    DESC

    schema = YAML.load_file(Rails.root.join('public/swagger/v1/swagger.yaml'))
    schema['components']['schemas'].slice('species').map do |name, attrs|
      md << "\n## #{name.humanize}\n"

      root_keys = attrs['properties'].map {|n, a| parse_tree(n, a) }.flatten.compact
      group_categories(root_keys).each do |field_name, keys|

        if field_name != :root
          elt = keys.filter {|e| e[:name] == field_name }&.first
          md << "\n### #{field_name}\n"
          md << "\n#{elt[:description]}\n" if elt && elt[:description]&.length.to_i > 0
        end

        keys.first.keys
        values = keys.reject {|e| e[:name] == field_name }

        # puts "Headings: "
        # pp headings

        # puts "Values: "
        # pp values

        table = Terminal::Table.new do |t|
          t.headings = %w[field description]
          t.rows = values.map do |e|
            ["**#{e[:name].gsub("#{field_name}.", '')}** (#{e[:type]})", e[:description].gsub("\n", '<br />')]
          end

          t.style = { border_top: false, border_bottom: false, border_i: '|' }
        end

        md << table.to_s
      end
    end

    File.write('SPECS.md', md.join("\n"))
  end

  desc 'Generate correcrtion fields markdown specs from swagger'
  task generate_correction_spec: :environment do

    md = []
    schema = YAML.load_file(Rails.root.join('public/swagger/v1/swagger.yaml'))
    attrs = schema['components']['schemas']['request_body_correction']['properties']['correction']

    keys = attrs['properties'].map {|n, a| parse_tree(n, a) }.flatten.compact

    keys.first.keys
    values = keys

    table = Terminal::Table.new do |t|
      t.headings = %w[field description]
      t.rows = values.map do |e|
        ["**#{e[:name]}** (#{e[:type]})", e[:description].gsub('"|"', '"\|" ').gsub("\n", ' <br />')]
      end

      t.style = { border_top: false, border_bottom: false, border_i: '|' }
    end

    md << table.to_s

    File.write('CORRECTION_SPECS.md', md.join("\n"))
  end

end
