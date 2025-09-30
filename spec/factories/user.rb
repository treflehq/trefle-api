FactoryBot.define do
  factory :user, class: User do
    sequence(:name) {|n| "#{Faker::Internet.username}-#{n}" }
    email { Faker::Internet.email(name: name) }
    password { Faker::Internet.password }
    password_confirmation { password }

    admin { false }

    # before(:create, &:confirm)

    factory :admin, class: User do
      admin { true }
    end
  end
end
