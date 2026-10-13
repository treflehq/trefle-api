# Reads config/ecological_indicators.yml — the Ellenberg-type classes behind
# the light, humidity, nutriments and salinity columns — so every page spells
# a class the same way ("7 / 9 · half-light to light") and none of them
# invents a measurement for it.
module EcologicalIndicators
  class << self

    def config
      @config ||= YAML.load_file(Rails.root.join('config/ecological_indicators.yml'))
    end

    # Used by tests to force a reload
    def reset!
      @config = nil
    end

    # The one-line reminder shown next to the values: an indicator describes
    # where the species grows, not what a plant tolerates.
    def note
      config['note']
    end

    # Indicator specs keyed by species column name.
    def fields
      config['indicators']
    end

    def field(name)
      fields[name.to_s]
    end

    def field?(name)
      fields.key?(name.to_s)
    end

    # "half-light to light" for light 7; nil when the field is not an
    # indicator or the value is not one of its classes.
    def class_label(name, value)
      spec = field(name)
      klass = to_class(value)
      return nil if spec.nil? || klass.nil?

      spec['classes'][klass]
    end

    # "7 / 9 · half-light to light"; the bare value when it has no class.
    def describe(name, value)
      label = class_label(name, value)
      return value.to_s if label.nil?

      "#{to_class(value)} / #{field(name)['max']} · #{label}"
    end

    # What the explore page ships to the browser: the same table, plus the note.
    def to_h
      { 'note' => note, 'indicators' => fields }
    end

    private

    # Facts may carry the class as 7, 7.0 or "7"; anything else is no class.
    def to_class(value)
      number = Float(value.to_s)
      number.to_i if number == number.to_i
    rescue ArgumentError, TypeError
      nil
    end

  end
end
