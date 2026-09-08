require 'rails_helper'

RSpec.describe CitationHelper, type: :helper do
  before do
    allow(ENV).to receive(:[]).and_call_original
  end

  describe '#citation_doi' do
    it 'is nil when TREFLE_DOI is unset' do
      allow(ENV).to receive(:[]).with('TREFLE_DOI').and_return(nil)
      expect(helper.citation_doi).to be_nil
    end

    it 'is blank-safe when TREFLE_DOI is an empty string' do
      allow(ENV).to receive(:[]).with('TREFLE_DOI').and_return('')
      expect(helper.citation_doi).to be_nil
    end

    it 'returns the configured DOI' do
      allow(ENV).to receive(:[]).with('TREFLE_DOI').and_return('10.5281/zenodo.1234567')
      expect(helper.citation_doi).to eq('10.5281/zenodo.1234567')
    end
  end

  describe '#citation_url' do
    it 'falls back to the plain site URL with no DOI' do
      allow(ENV).to receive(:[]).with('TREFLE_DOI').and_return(nil)
      expect(helper.citation_url).to eq('https://trefle.io')
    end

    it 'resolves through doi.org when a DOI is configured' do
      allow(ENV).to receive(:[]).with('TREFLE_DOI').and_return('10.5281/zenodo.1234567')
      expect(helper.citation_url).to eq('https://doi.org/10.5281/zenodo.1234567')
    end
  end

  describe 'the three formats stay consistent with each other' do
    before { allow(ENV).to receive(:[]).with('TREFLE_DOI').and_return(nil) }

    it 'all name the same title, year and licence' do
      year = helper.citation_year

      expect(helper.citation_text).to include('Trefle: a global plants API').and include(year.to_s).and include('CC-BY-4.0')
      expect(helper.citation_apa).to include('Trefle: a global plants API').and include(year.to_s)
      expect(helper.citation_bibtex).to include('Trefle: a global plants API').and include(year.to_s).and include('CC-BY-4.0')
    end

    it 'omits the doi field from BibTeX with no DOI configured' do
      expect(helper.citation_bibtex).not_to include('doi')
    end

    it 'includes the doi field in BibTeX once a DOI is configured' do
      allow(ENV).to receive(:[]).with('TREFLE_DOI').and_return('10.5281/zenodo.1234567')
      expect(helper.citation_bibtex).to include('doi = {10.5281/zenodo.1234567}')
    end
  end
end
