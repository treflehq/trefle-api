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
        @params = params
      end
    end
  end

  def build(page:)
    including_class.new(page: page.to_s)
  end

  it 'accepts a page exactly at MAX_PAGE_DEPTH' do
    instance = build(page: WithCachedCount::MAX_PAGE_DEPTH)

    expect { instance.pagy_get_vars(Species.none, {}) }.not_to raise_error
  end

  it 'rejects a page one past MAX_PAGE_DEPTH' do
    instance = build(page: WithCachedCount::MAX_PAGE_DEPTH + 1)

    expect { instance.pagy_get_vars(Species.none, {}) }.to raise_error(WithCachedCount::PageDepthExceededError)
  end
end
