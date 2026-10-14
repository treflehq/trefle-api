require 'rails_helper'

RSpec.describe ImageLicence do
  let(:plantnet) { 'https://bs.plantnet.org/image/o/82ab92fa3ee75b8de8f8def2315d38ac929fe79e' }
  let(:kew) { '© copyright of the Board of Trustees of the Royal Botanic Gardens, Kew.' }

  def derive(copyright, url = plantnet)
    described_class.derive(copyright: copyright, image_url: url)
  end

  describe 'Pl@ntNet copyrights' do
    {
      'cc-by-sa' => ['CC-BY-SA', 'https://creativecommons.org/licenses/by-sa/', true],
      'cc-by' => ['CC-BY', 'https://creativecommons.org/licenses/by/', true],
      'cc-by-nc' => ['CC-BY-NC', 'https://creativecommons.org/licenses/by-nc/', false],
      'cc-by-nc-sa' => ['CC-BY-NC-SA', 'https://creativecommons.org/licenses/by-nc-sa/', false],
      'gpl' => ['GPL', nil, true],
      '©' => ['LicenseRef-All-Rights-Reserved', nil, false]
    }.each do |code, (licence, url, commercial)|
      it "reads (#{code}) as #{licence}" do
        expect(derive("Taken Mar 14, 2022 by Jane Doe (#{code})")).to eq(
          licence: licence, licence_url: url, author: 'Jane Doe',
          commercial_use_allowed: commercial,
          thumbnail_url: 'https://bs.plantnet.org/image/s/82ab92fa3ee75b8de8f8def2315d38ac929fe79e'
        )
      end
    end

    it 'leaves the undocumented "public" code unknown but keeps the author' do
      expect(derive('Taken Jan 1, 1900 by Jane Doe (public)')).to include(
        licence: nil, licence_url: nil, commercial_use_allowed: nil, author: 'Jane Doe'
      )
    end

    it 'keeps parentheses that belong to the author name' do
      expect(derive('Taken Aug 10, 2007 by EOL − J. E.(Jed) and Bonnie McClellan (cc-by-nc-sa)'))
        .to include(author: 'EOL − J. E.(Jed) and Bonnie McClellan', licence: 'CC-BY-NC-SA')
      expect(derive('Taken Mar 14, 2022 by ( ˘-˘)っ♨ Эвелина (cc-by-sa)'))
        .to include(author: '( ˘-˘)っ♨ Эвелина', licence: 'CC-BY-SA')
    end

    it 'drops an author that is only an account number' do
      expect(derive('Taken Apr 17, 2019 by 1 (cc-by-sa)')).to include(author: nil, licence: 'CC-BY-SA')
    end

    it 'reads nothing from an unknown licence code' do
      expect(derive('Taken Apr 17, 2019 by Jane Doe (cc0)')).to include(licence: nil, author: nil, commercial_use_allowed: nil)
    end
  end

  it 'reads the Kew line as all rights reserved, with no author' do
    expect(derive(kew, 'https://d2seqvvyy3b8p2.cloudfront.net/a27ee708a34e68c50b1aa3657c18fa90.jpg')).to eq(
      licence: 'LicenseRef-All-Rights-Reserved', licence_url: nil, author: nil,
      commercial_use_allowed: false, thumbnail_url: nil
    )
  end

  it 'builds the POWO asset thumbnail' do
    url = 'https://storage.googleapis.com/powop-assets/PPA/0401_0450/h0434x_fullsize.jpg'
    expect(derive(kew, url)[:thumbnail_url]).to eq('https://storage.googleapis.com/powop-assets/PPA/0401_0450/h0434x_thumbnail.jpg')
  end

  it 'guesses nothing from an unknown copyright or host' do
    expect(derive('Wikipedia 2022', 'https://upload.wikimedia.org/a.jpg')).to eq(
      licence: nil, licence_url: nil, author: nil, commercial_use_allowed: nil, thumbnail_url: nil
    )
    expect(derive(nil, 'https://bs.plantnet.org/image/m/abc')).to include(licence: nil, thumbnail_url: nil)
  end
end
