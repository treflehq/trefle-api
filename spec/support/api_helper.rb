require 'rspec/expectations'

module ApiHelper
  def json_request(method, path, **args)
    # Set Json request headers
    args[:headers] = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    }

    # Add JWT token
    if args[:user]
      u = args.delete(:user)
      args[:headers] = Devise::JWT::TestHelpers.auth_headers(args[:headers], u)
    end

    process(method, path, **args)
  end

  def json_get(path, **args)
    json_request(:get, path, **args)
  end

  def json_post(path, **args)
    json_request(:post, path, **args)
  end

  def json_patch(path, **args)
    json_request(:patch, path, **args)
  end

  def json_delete(path, **args)
    json_request(:delete, path, **args)
  end
end
