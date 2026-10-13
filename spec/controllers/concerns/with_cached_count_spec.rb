require 'rails_helper'

# #367: boundary coverage for MAX_PAGE_DEPTH. The request specs in
# error_envelope_spec.rb only exercise MAX_PAGE_DEPTH + 1 (rejected); on a
# small test dataset, asserting the *accepted* boundary through a real
# request would just trade the depth guard's error for Pagy::OverflowError's
# (too few pages exist), which proves nothing about the `>` vs `>=`
# distinction this guard actually depends on. Testing pagy_get_vars directly
# isolates that boundary from Pagy's own page/count logic.
RSpec.describe WithCachedCount do
  let(:including_class) do
    Class.new do
      include WithCachedCount
      attr_reader :params

      def initialize(params)
        @params = ActionController::Parameters.new(params)
      end
    end
  end

  def build(page:, per_page: nil)
    including_class.new({ page: page.to_s, per_page: per_page&.to_s }.compact)
  end

  it 'accepts a page exactly at MAX_PAGE_DEPTH' do
    instance = build(page: WithCachedCount::MAX_PAGE_DEPTH)

    expect { instance.pagy_get_vars(Species.none, {}) }.not_to raise_error
  end

  it 'rejects a page one past MAX_PAGE_DEPTH' do
    instance = build(page: WithCachedCount::MAX_PAGE_DEPTH + 1)

    expect { instance.pagy_get_vars(Species.none, {}) }.to raise_error(WithCachedCount::PageDepthExceededError)
  end

  # #217: the page size is client-controlled, so the cap is also a row horizon
  # (MAX_OFFSET): the same 50,000 rows whatever the page size.
  it 'accepts the deepest page that stays within MAX_OFFSET at 100 items per page' do
    instance = build(page: WithCachedCount::MAX_OFFSET / 100, per_page: 100)

    expect { instance.pagy_get_vars(Species.none, {}) }.not_to raise_error
  end

  it 'rejects the page past MAX_OFFSET at 100 items per page, naming the deepest one' do
    instance = build(page: (WithCachedCount::MAX_OFFSET / 100) + 1, per_page: 100)

    expect { instance.pagy_get_vars(Species.none, {}) }
      .to raise_error(WithCachedCount::PageDepthExceededError, /deepest page at this page size is #{WithCachedCount::MAX_OFFSET / 100}/)
  end

  it 'passes the page size to Pagy as :items' do
    instance = build(page: 1, per_page: 42)

    expect(instance.pagy_get_vars(Species.none, {})[:items]).to eq(42)
  end
end
