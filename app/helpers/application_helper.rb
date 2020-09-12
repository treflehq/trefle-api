module ApplicationHelper
  include Pagy::Frontend

  def sortable_link(attr, path, params)
    nparams = params.to_unsafe_h.merge({
      'order' => { attr => (params.dig(:order, attr) == 'asc' ? :desc : :asc) }
    })
    # nparams = params.permit(
    #   :search, order: {}
    # ).to_h.merge({
    #   'order' => { attr => (params.dig(:order, attr) == 'asc' ? :desc : :asc) }
    # })
    link_to(attr.to_s.humanize, send(path, nparams))
  end

  def field_desc(obj, name, ftype = nil)
    tag.p class: 'elt' do
      tag.strong("#{name.to_s.humanize}: ") + field_v(obj.send(name), name, ftype)
    end
  end

  def table_desc(obj, name)
    field_v(obj[name], name)
  end

  def field_v(val, name, ftype = nil)
    case ftype
    when nil
      return tag.span('null', class: 'null-elt') if val.nil?
      return tag.span(val.to_s(:short)) if name.to_s.ends_with?('_at')
      # rubocop:todo Style/MultipleComparison
      return tag.span(val.to_s, class: "bool-elt #{val}-elt") if val == true || val == false

      # rubocop:enable Style/MultipleComparison
      tag.span(val.to_s, class: "#{val.class.to_s.underscore}-elt")
    when :flags
      tag.span(val.to_a.join(', '), class: "#{val.class.to_s.underscore}-elt")
    else
      tag.span(val.to_s, class: "#{val.class.to_s.underscore}-elt")
    end
  end

  def active_class_for(active_controller: nil, class_name: 'has-text-link')
    cname = "#{controller.class.to_s.underscore.gsub('_controller', '')}##{action_name}"
    puts "cname: #{cname}"
    return class_name if active_controller && (cname == active_controller || cname =~ /#{active_controller}/)

    ""
  end
end
