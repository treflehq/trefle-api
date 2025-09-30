Rails.application.config.session_store :cookie_store, key: "_trefle#{Rails.env.development? ? '_d' : ''}_session", domain: :all
