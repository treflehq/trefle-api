module Utils
  module ScientificName
    def self.format_name(name, author = nil)
      return name unless name

      name = name.gsub(/(\([A-Z].*)/, '')
      name = name.gsub(/\s#{Regexp.escape(author.split(' ').first)}.*/, '') unless author.blank?
      genus, spe, *rest = name.split(' ')
      rest -= author.split(' ').select {|e| e.length > 3 } unless author.blank?
      rest = rest.reject {|e| e =~ /\d{2,4}/ }

      name = [genus, spe, rest].join(' ')
      name = name.gsub(',', '')
      name = name.split(' ').reject(&:blank?).join(' ')
      name = name.gsub(' x ', ' × ').split('×').join(' × ')
      name = name.split(' ').reject(&:blank?).join(' ')
      name
    end

    def self.tokenize(name)
      name.gsub('-', '_').parameterize.split('-').join(' ').gsub(' x ', ' ').gsub(/^x /, '').strip.gsub('_', '-')
    end
  end
end
