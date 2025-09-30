# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  account_type           :string(255)
#  admin                  :boolean          default(FALSE)
#  confirmation_sent_at   :datetime
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string(255)
#  email                  :string(255)
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0)
#  github_username        :string
#  inserted_at            :datetime         not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string(255)
#  locked_at              :datetime
#  name                   :string(255)
#  organization_image_url :string(255)
#  organization_name      :string(255)
#  organization_url       :string(255)
#  password_hash          :string(255)
#  provider               :string
#  public_profile         :boolean
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string(255)
#  sign_in_count          :integer          default(0)
#  sponsored_tier         :string
#  sponsorship_checked_at :datetime
#  token                  :string(255)
#  uid                    :string
#  unconfirmed_email      :string
#  unlock_token           :string(255)
#  created_at             :datetime
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  users_email_index                    (email) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable #, :confirmable
  devise :omniauthable, omniauth_providers: [:github]

  include Gravtastic
  gravtastic

  has_many :record_corrections, dependent: :nullify
  has_many :user_queries, dependent: :destroy

  before_create :assign_token

  ACCOUNT_TYPES = %i[
    individual
    nonprofit
    company
    other
  ].freeze

  def assign_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def regenerate_token!
    update(token: SecureRandom.urlsafe_base64(32))
  end

end
