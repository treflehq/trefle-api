require 'rails_helper'

# config/traits.yml `sources.default_priority` is the table every arbitration
# reads: Ingester::Species#outranked_for? and Migrators::FactPromotion both
# rank a claim by its position in it. A mistake here does not raise, it just
# decides the wrong winner — so the shape of the list is pinned rather than
# trusted.
RSpec.describe 'Traits source priority' do
  let(:priority) { Traits.source_priority }

  # Catches a literal copy-paste duplicate. It does NOT catch two spellings of
  # the same source (#377 was `wfo` and `world_flora_online`, two different
  # strings) — no string comparison can. That one is pinned explicitly below.
  it 'lists each source exactly once' do
    duplicates = priority.tally.select {|_, count| count > 1 }.keys

    expect(duplicates).to be_empty, "duplicated in sources.default_priority: #{duplicates.join(', ')}"
  end

  it 'is all lower-case, because lookups downcase before matching' do
    expect(priority.reject {|s| s == s.downcase }).to be_empty
  end

  it 'gives every rank a distinct index' do
    expect(priority.length).to eq(priority.uniq.length)
  end

  # #377: `world_flora_online` sat at rank 11 while `wfo` — the string
  # lib/crawlers/world_flora_online.rb actually ingests with — sat at rank 9.
  # Traits.priority_index resolves with Array#index, which returns the first
  # match, so rank 11 was unreachable. Worse, the day anything emitted that
  # spelling, one source would have held two ranks and outranked itself.
  #
  # An alias is invisible to any generic check, so the list is asserted against
  # the strings the ingesters really pass.
  it 'ranks World Flora Online under the slug its crawler ingests with' do
    expect(priority).to include('wfo')
    expect(priority).not_to include('world_flora_online')
  end

  it 'ranks community above every automated source' do
    expect(priority.first).to eq('community')
  end

  # Every source that actually appears in the facts table should have a
  # considered rank. An unlisted one still works — it ties at the bottom and
  # can fill a gap but never win an argument — but that should be a decision,
  # not an oversight.
  it 'documents the sources the ingester passes' do
    ingested = %w[try powo gbif wfo iucn catminat pfaf openfarm wikipedia]

    expect(ingested - priority).to be_empty
  end
end
