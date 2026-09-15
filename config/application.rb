require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require "action_mailbox/engine"
# require "action_text/engine"
require 'action_view/railtie'
# require "action_cable/engine"
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TrefleAdmin
  class Application < Rails::Application

    # Keep in step with the release tags (git tag vX.Y.Z). It is published as
    # `info.version` of the OpenAPI spec, so a stale value here ships a stale
    # version number on docs.trefle.io/reference.
    VERSION = '2.6.0'.freeze

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    config.eager_load_paths << Rails.root.join('lib')

    # Requests reach this app through the k8s ingress, which forwards from
    # its own in-cluster address (see #331 -- the reported spoof event
    # carried `X-Forwarded-For: 10.42.0.1`, a Flannel/k3s pod-network
    # address). Rails' built-in ActionDispatch::RemoteIp::TRUSTED_PROXIES
    # already covers RFC1918 space, which is why this rarely changes
    # anything in practice -- it's set explicitly (rather than relying on
    # that implicit default) so the trust boundary is documented and so
    # request specs can exercise it deterministically. Extend, don't
    # replace: passing a custom list to RemoteIp *replaces* the default
    # rather than adding to it.
    config.action_dispatch.trusted_proxies = ActionDispatch::RemoteIp::TRUSTED_PROXIES + [
      IPAddr.new('10.42.0.0/16')
    ]
  end
end
