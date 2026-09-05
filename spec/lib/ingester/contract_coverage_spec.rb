require 'rails_helper'

# The traits contract and the converters have to agree. A field can be declared
# arbitrated in config/traits.yml and still be unreachable, because no converter
# picks its key out of the incoming hash — in which case a source can send it
# and it is silently dropped. That is how `phylum` went missing: GBIF sends it,
# the contract expected it, nothing converted it.
RSpec.describe 'Ingester contract coverage' do

  # Assigned straight from the hash by Ingester::Species#resolve_core_informations!
  let(:core_direct) { %w[scientific_name rank year author] }

  # Handled by a converter that does not advertise a FIELDS list:
  # Converter::CommonName reads :common_name, Converter::Image the image keys.
  let(:converter_without_fields_list) { %w[common_name] }

  # Derived by the model rather than claimed by a source: main_image_url is
  # picked from the species' images (Species#complete_cache_fields), so a
  # source neither can nor should set it.
  let(:model_derived) { %w[main_image_url] }

  def converter_fields
    measurement = Ingester::Converter::Measurement::FIELDS.flat_map do |metric|
      unit = Ingester::Converter::Measurement::DEFAULT_MEASUREMENTS[metric.to_sym]
      ["#{metric}_#{unit}", "#{metric}_value", "#{metric}_unit"]
    end

    [
      Ingester::Converter::Text::FIELDS,
      Ingester::Converter::Number::FIELDS,
      Ingester::Converter::Float::FIELDS,
      Ingester::Converter::Boolean::FIELDS,
      Ingester::Converter::Enum::FIELDS,
      Ingester::Converter::Flag::FIELDS
    ].flatten.map(&:to_s) + measurement
  end

  it 'can actually ingest every field it claims to arbitrate' do
    reachable = converter_fields + core_direct + converter_without_fields_list + model_derived
    unreachable = Traits.arbitrated_fields - reachable

    expect(unreachable).to be_empty,
                           'these fields are arbitrated but no converter reads them, so a ' \
                           "source sending them would be silently ignored: #{unreachable.join(', ')}"
  end

  it 'only declares fields that exist as columns' do
    expect(Traits.fields.keys - Species.column_names).to be_empty
  end

  it 'ingests phylum, which GBIF sends and nothing used to convert' do
    species = create(:species)

    Ingester::Species.new({ source_gbif: '1', phylum: 'Tracheophyta' }, species_id: species.id).ingest!

    expect(species.reload.phylum).to eq('Tracheophyta')
  end

end
