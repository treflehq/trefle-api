# == Schema Information
#
# Table name: foreign_sources
#
#  id                 :bigint           not null, primary key
#  copyright_template :text
#  inserted_at        :datetime         not null
#  name               :string(255)
#  slug               :string(255)
#  url                :string(255)
#  created_at         :datetime
#  updated_at         :datetime         not null
#
# Indexes
#
#  foreign_sources_name_index  (name) UNIQUE
#  foreign_sources_slug_index  (slug) UNIQUE
#
class ForeignSource < ApplicationRecord

  has_many :foreign_sources_plants

  extend FriendlyId
  friendly_id :name, use: :slugged

end
