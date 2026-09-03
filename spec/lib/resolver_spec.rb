require 'rails_helper'

RSpec.describe Resolver::Gbif do
  def stub_omnisearch(name, results)
    stub_request(:get, 'https://www.gbif.org/api/omnisearch')
      .with(query: { locale: 'en', q: name })
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { speciesMatches: { count: results.size, results: results } }.to_json
      )
  end

  def stub_taxon(id, body)
    stub_request(:get, "https://www.gbif.org/api/taxonomy/#{described_class::DATASET_KEY}/#{id}")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body.to_json)
  end

  let(:gbif_entry) do
    {
      key: 2_685_484, speciesKey: 2_685_484, rank: 'SPECIES', confidence: 98,
      synonym: false, scientificName: 'Abies alba Mill.', authorship: 'Mill.',
      kingdom: 'Plantae', taxonomicStatus: 'ACCEPTED', genus: 'Abies',
      publishedIn: 'Gard. Dict. ed. 8: n.º 1 (1768)'
    }
  end

  describe '.resolve_hash' do
    it 'resolves an accepted name' do
      stub_omnisearch('Abies alba', [gbif_entry])
      stub_taxon(2_685_484, gbif_entry)

      result = described_class.resolve_hash('Abies alba')

      expect(result).to include(
        scientific_name: 'Abies alba',
        rank: :species,
        genus: 'Abies',
        source_gbif: 2_685_484,
        status: 'accepted'
      )
    end

    it 'ignores low confidence matches' do
      stub_omnisearch('Abies dubium', [gbif_entry.merge(confidence: 42)])

      expect(described_class.resolve_hash('Abies dubium')).to be_nil
    end

    it 'ignores non-plant kingdoms' do
      stub_omnisearch('Felis catus', [gbif_entry.merge(kingdom: 'Animalia')])
      stub_taxon(2_685_484, gbif_entry.merge(kingdom: 'Animalia'))

      expect(described_class.resolve_hash('Felis catus')).to be_nil
    end

    it 'follows synonyms to the accepted species' do
      stub_omnisearch('Abies pectinata', [gbif_entry.merge(synonym: true, key: 111)])
      stub_taxon(111, { acceptedKey: 2_685_484 })
      stub_taxon(2_685_484, gbif_entry)

      result = described_class.resolve_hash('Abies pectinata')

      expect(result[:scientific_name]).to eq('Abies alba')
    end

    it 'returns nil when GBIF finds nothing' do
      stub_omnisearch('Nothingus atallus', [])

      expect(described_class.resolve_hash('Nothingus atallus')).to be_nil
    end
  end

  describe '.clean_authorship' do
    it 'splits the year out of the authorship' do
      expect(described_class.clean_authorship('Mill., 1768')).to eq(author: 'Mill.', year: '1768')
    end

    it 'keeps a plain author' do
      expect(described_class.clean_authorship('Mill.')).to eq(author: 'Mill.')
    end

    it 'accepts blanks' do
      expect(described_class.clean_authorship(nil)).to eq({})
    end
  end
end

RSpec.describe Resolver::Powo do
  def stub_search(name, results)
    stub_request(:get, 'http://powo.science.kew.org/api/1/search')
      .with(query: { q: name })
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { totalResults: results.size, results: results }.to_json
      )
  end

  let(:powo_entry) do
    {
      name: 'Abies alba', author: 'Mill.', rank: 'Species', kingdom: 'Plantae',
      accepted: true, fqId: 'urn:lsid:ipni.org:names:261578-1'
    }
  end

  describe '.resolve_hash' do
    it 'resolves an accepted name' do
      stub_search('Abies alba', [powo_entry])

      result = described_class.resolve_hash('Abies alba')

      expect(result).to include(
        scientific_name: 'Abies alba',
        rank: :species,
        status: 'accepted',
        source_powo: 'urn:lsid:ipni.org:names:261578-1'
      )
    end

    it 'skips names POWO does not accept' do
      stub_search('Abies pectinata', [powo_entry.merge(accepted: false)])

      expect(described_class.resolve_hash('Abies pectinata')).to be_nil
    end

    it 'returns nil when POWO finds nothing' do
      stub_search('Nothingus atallus', [])

      expect(described_class.resolve_hash('Nothingus atallus')).to be_nil
    end
  end
end
