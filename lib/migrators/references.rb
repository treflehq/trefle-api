# Will help up migrate our new flags
module Migrators
  class References

    def self.run
      {
        'Apium graveolens var. graveolens': 'Apium graveolens',
        'Benincasa fistulosa': 'Tinda',
        'Brassica rapa subsp. chinensis': 'Bok_choy',
        'Brassica rapa var. perviridis': 'Komatsuna',
        'Cnidoscolus aconitifolius subsp. aconitifolius': 'Cnidoscolus aconitifolius',
        'Echites panduratus': 'Fernaldia pandurata',
        "Allium ampeloprasum var. ampeloprasum": 'Elephant_garlic',
        "Allium ampeloprasum var. sectivum": 'Pearl_onion',
        "Beta vulgaris subsp. vulgaris": 'Beta_vulgaris',
        "Brassica oleracea var. alboglabra": 'Gai_lan',
        "Brassica oleracea var. botrytis": 'Cauliflower',
        "Brassica oleracea var. italica": 'Broccoli',
        "Brassica rapa subsp. narinosa": 'Tatsoi',
        "Brassica rapa subsp. nipposinica": 'Mizuna',
        "Brassica rapa subsp. rapa": 'Turnip',
        "Dioscorea cayenensis": 'Dioscorea_cayennensis',
        "Lactuca sativa var. augustana": 'Lettuce',
        "Sicyos edulis": 'Chayote'
      }.map do |sci, name|
        link_to_wikipedia(Species.find_by(scientific_name: sci), name)
      end
    end

    def self.link_to_wikipedia(species, wiki_name)
      fs = ForeignSource.where(name: 'Wikipedia').first_or_create!(
        slug: 'wikipedia_en',
        url: 'https://en.wikipedia.org/',
        copyright_template: "Wikipedia #{Date.current.year}"
      )
      fs = ForeignSourcesPlant.where(species: species, foreign_source: fs).first_or_create!(fid: wiki_name)
      fs.update(fid: wiki_name)
    end

  end
end
