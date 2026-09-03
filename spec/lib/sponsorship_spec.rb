require 'rails_helper'

RSpec.describe Sponsorship::GithubSponsorship do
  def stub_sponsors(nodes)
    stub_request(:post, 'https://api.github.com/graphql')
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { data: { organization: { sponsorshipsAsMaintainer: { nodes: nodes } } } }.to_json
      )
  end

  let(:nodes) do
    [
      { sponsorEntity: { login: 'plantlover' }, tier: { monthlyPriceInDollars: 10 } },
      { sponsorEntity: { login: 'agrocorp' }, tier: { monthlyPriceInDollars: 100 } }
    ]
  end

  describe '.get_sponsors' do
    it 'maps sponsor logins to their tier' do
      stub_sponsors(nodes)

      expect(described_class.get_sponsors).to eq('plantlover' => 10, 'agrocorp' => 100)
    end

    it 'returns nil without sponsors' do
      stub_sponsors([])

      expect(described_class.get_sponsors).to be_nil
    end
  end

  describe '.reassign_sponsor_status' do
    it 'sets the tier of current sponsors and clears ex-sponsors' do
      sponsor = create(:user, github_username: 'plantlover')
      ex_sponsor = create(:user, github_username: 'gonesponsor', sponsored_tier: '25')
      stub_sponsors(nodes)

      described_class.reassign_sponsor_status

      expect(sponsor.reload.sponsored_tier).to eq('10')
      expect(ex_sponsor.reload.sponsored_tier).to be_nil
    end
  end
end

RSpec.describe Sponsorship::UpdateSponsorWorker do
  it 'delegates to the sponsorship reassignment' do
    allow(Sponsorship::GithubSponsorship).to receive(:reassign_sponsor_status)

    described_class.new.perform

    expect(Sponsorship::GithubSponsorship).to have_received(:reassign_sponsor_status)
  end
end
