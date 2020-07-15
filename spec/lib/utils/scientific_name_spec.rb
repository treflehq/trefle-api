require 'rails_helper'

RSpec.describe Utils::ScientificName do # rubocop:todo Metrics/BlockLength

  {
    ['Scandix pecten-veneris subsp. pecten-veneris', nil] => 'Scandix pecten-veneris subsp. pecten-veneris',
    ['Justicia obtusifolia var. obtusifolia', nil] => 'Justicia obtusifolia var. obtusifolia',
    ['Roystonea regia var. regia', nil] => 'Roystonea regia var. regia',
    ['Isocoma coronopifolia var. coronopifolia', nil] => 'Isocoma coronopifolia var. coronopifolia',
    ['Tragopogon pratensis fo. pratensis', nil] => 'Tragopogon pratensis fo. pratensis',
    ['Cirsium pumilum fo. hillii', nil] => 'Cirsium pumilum fo. hillii',
    ['Euphorbia herniarifolia', nil] => 'Euphorbia herniarifolia',
    ['Euphorbia herniariifolia  Willd. ', 'Willd. Rococo'] => 'Euphorbia herniariifolia',
    ['Draba reptans ssp. stellifera', 'Willd.'] => 'Draba reptans ssp. stellifera',
    ['Melotrefle intortus', nil] => 'Melotrefle intortus',
    ['Echinotrefle horizonthalonius', nil] => 'Echinotrefle horizonthalonius',
    ['Ligusticum scoticum ssp. hultenii', nil] => 'Ligusticum scoticum ssp. hultenii',
    ['Platanthera sparsiflora × tescamnis', nil] => 'Platanthera sparsiflora × tescamnis',
    ['Platydesma cornuta var. cornuta', nil] => 'Platydesma cornuta var. cornuta',
    ['Platythelys sagraeanus', nil] => 'Platythelys sagraeanus',
    ['Platythelys sagraeana (A.Rich.) Garay, 1977', '(A.Rich.) Garay'] => 'Platythelys sagraeana',
    ['Saxifraga nelsoniana ssp. porsildiana', nil] => 'Saxifraga nelsoniana ssp. porsildiana',
    ['×Schedolium loliaceum', nil] => '× Schedolium loliaceum',
    ['×Schedolium loliaceum (Huds.) Holub', 'Holub (Huds.)'] => '× Schedolium loliaceum',
    ['Thelotrefle bicolor var. bicolor', nil] => 'Thelotrefle bicolor var. bicolor',
    ['Schistophragma intermedia', nil] => 'Schistophragma intermedia',
    ['Schistophragma intermedium (A.Gray ex Torr.) Pennell', 'Pennell (A.Gray ex Torr.)'] => 'Schistophragma intermedium',
    ['Thelotrefle bicolor var. schottii', nil] => 'Thelotrefle bicolor var. schottii',
    ['Trifolium mucronatum ssp. lacerum', nil] => 'Trifolium mucronatum ssp. lacerum',
    ['Ivesia lycopodioides ssp. scandularis', nil] => 'Ivesia lycopodioides ssp. scandularis',
    ['Machaeranthera pinnatifida ssp. pinnatifida var. glaberrima', nil] => 'Machaeranthera pinnatifida ssp. pinnatifida var. glaberrima',
    ['Cerasus pumila ssp. besseyi', nil] => 'Cerasus pumila ssp. besseyi',
    ['Teucrium depressum var. densum', nil] => 'Teucrium depressum var. densum',
    ['Pecluma ptilodon var. caespitosum', nil] => 'Pecluma ptilodon var. caespitosum',
    ['Iris ×sancti-cyrii', nil] => 'Iris × sancti-cyrii',
    ['Iris sancti-cyri Rousseau', 'Rousseau (Test)'] => 'Iris sancti-cyri',
    ['Pinus ×hunnewellii [parviflora × strobus]', nil] => 'Pinus × hunnewellii [parviflora × strobus]',
    ['Sclerotrefle whipplei var. roseus', nil] => 'Sclerotrefle whipplei var. roseus',
    ['×Sorbaronia alpina', nil] => '× Sorbaronia alpina',
    ['Sorbaronia alpina C.K.Schneid.', 'C.K.Schneid.'] => 'Sorbaronia alpina',
    ['Viola ×esculenta', nil] => 'Viola × esculenta',
    ['Robinia ×ambigua', nil] => 'Robinia × ambigua',
    ['Alnus ×purpusii', nil] => 'Alnus × purpusii',
    ['Guatteria dioscoreoides', nil] => 'Guatteria dioscoreoides',
    ['Asarum sect. Asarum', nil] => 'Asarum sect. Asarum',
    ['Lecania discreptans', nil] => 'Lecania discreptans'
  }.each do |elts, expected|

    it "Can process #{expected}" do
      result = Utils::ScientificName.format_name(*elts)
      expect(result).to eq(expected)
    end

  end
end
