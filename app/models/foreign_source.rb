# == Schema Information
#
# Table name: foreign_sources
#
#  id                 :integer          not null, primary key
#  name               :string(255)
#  slug               :string(255)
#  url                :string(255)
#  inserted_at        :datetime         not null
#  updated_at         :datetime         not null
#  copyright_template :text
#  created_at         :datetime
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
