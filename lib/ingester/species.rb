require 'httparty'
require 'colorize'

module Ingester
  class IngesterException < RuntimeError

  end

  class Species

    # Data is a hash like:
    # {
    #   "scientific_name": "Picea abies var. abies",
    #   "rank": "var",
    #   "author": "",
    #   "genus": "Picea",
    #   "status": "accepted",
    #   "confidence": 92
    # }
    def initialize(data, **options)
      pp options
      @data = data&.deep_symbolize_keys&.compact
      # @data[:scientific_name] = "Mama mia"
      @dry_run = options[:dry_run] || false
      @species = ::Species.friendly.find(options[:species_id]) if options[:species_id]

      return unless @data

      check!
      # @TODO perform checks on data here
    end

    def check!
      raise IngesterException, 'No scientific name' if @data[:scientific_name].blank? && @species.nil?
    end

    def ingest!
      return unless @data

      # We get or create the species to change
      @species ||= ::Species.where(scientific_name: @data[:scientific_name]).first

      @species ||= ::Species.new(scientific_name: @data[:scientific_name])

      # If something goes wrong here, we want to go back to the initial state
      # @species.transaction do

      # We apply all the data we have on it
      assign_attributes!

      # We update it (or juste return the changes if dry run)
      save_or_return!
      # end
    end

    def assign_attributes!
      resolve_core_informations!
      resolve_genus!
      resolve_measurements!
      resolve_flags!
      resolve_images!
      resolve_sources!
      resolve_common_names!
      resolve_texts!
      resolve_floats!
      resolve_numbers!
      resolve_bools!
      resolve_enums!
    end

    def save_or_return!
      puts "\nIngesting:".green

      puts @data.to_yaml.green

      puts 'Got: '.green
      puts @species.changes.inspect.green
      puts "\n".green

      if @dry_run # rubocop:todo Style/GuardClause

        return return_hash(@species.changes)
      else

        puts '=========== Before save: ==========='
        puts "  changes: #{@species.changes}"

        # binding.pry
        changes = @species.changes
        a = @species.save

        changes = @species.saved_changes unless @species.saved_changes.empty?

        puts '=========== After save: ==========='
        puts "  saved_changes: #{@species.saved_changes}"

        if a
          puts '[Ingester] Ingested !'
        else
          puts "[Ingester] Errors while saving: #{@species.errors.full_messages}"
        end
      end

      return_hash(changes)
    end

    # :image_url,
    # :source_gbif,
    # :source_openfarm,
    # :planting_row_spacing_cm,
    # :planting_spread_cm

    # Will resolve scientific_name, author and cie
    def resolve_core_informations!
      {
        scientific_name: @data[:scientific_name],
        rank: @data[:rank],
        year: @data[:year],
        author: @data[:author]
      }.compact.map {|k, v| @species.send("#{k}=", v) }
    end

    # Will try to match genus or create a new one
    def resolve_genus!
      Converter::Genus.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert measurement like fields
    def resolve_measurements!
      Converter::Measurement.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert flags like fields
    def resolve_flags!
      Converter::Flag.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert images
    def resolve_images!
      Converter::Image.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert sources
    def resolve_sources!
      Converter::Source.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert common names
    def resolve_common_names!
      Converter::CommonName.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert text
    def resolve_texts!
      Converter::Text.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert float
    def resolve_floats!
      Converter::Float.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert number
    def resolve_numbers!
      Converter::Number.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert bool
    def resolve_bools!
      Converter::Boolean.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert enum
    def resolve_enums!
      Converter::Enum.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    def return_hash(changes = nil)
      {
        id: @species&.id,
        saved: @species&.persisted?,
        changes: changes || @species&.saved_changes,
        valid: @species&.valid?,
        errors: @species&.errors&.full_messages
      }
    end

  end
end
