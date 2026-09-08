FactoryBot.define do
  factory :user, class: User do
    sequence(:name) {|n| "#{Faker::Internet.username}-#{n}" }
    email { Faker::Internet.email(name: name) }
    password { Faker::Internet.password }
    password_confirmation { password }

    admin { false }
    # Most specs just want a user free to use the web app; a signed-in user
    # with terms_accepted_at blank would otherwise get redirected to the
    # terms-acceptance prompt (see RequiresTermsAcceptance#require_terms_acceptance!).
    # Use `create(:user, accepts_terms: false)` to get a user still pending
    # acceptance.
    accepts_terms { true }

    # before(:create, &:confirm)

    factory :admin, class: User do
      admin { true }
    end
  end
end
