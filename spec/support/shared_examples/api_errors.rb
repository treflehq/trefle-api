require 'rspec/expectations'

# Asserts the single documented error envelope every /api error response
# shares: `{ error: true, code:, message:, messages:, details: }`. `messages`
# is a deprecated alias kept alongside `message` for one deprecation cycle
# (see issue #216) -- existing clients that read the old key keep working.
#
# Usage: perform the request in a `before` block, then
#   it_behaves_like 'renders API errors', status: :not_found, code: 'not_found'
RSpec.shared_examples 'renders API errors' do |status:, code:|
  it "renders the API error envelope for a #{status} response" do
    expect(response).to have_http_status(status)
    expect(response.content_type).to match(%r{application/json})

    body = JSON.parse(response.body)

    expect(body['error']).to eq(true)
    expect(body['code']).to eq(code)
    expect(body['message']).to be_present
    expect(body['messages']).to eq(body['message'])
  end
end
