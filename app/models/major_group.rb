# == Schema Information
#
# Table name: major_groups
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  slug        :string(255)
#  inserted_at :datetime         not null
#  updated_at  :datetime         not null
#  created_at  :datetime
#
# Indexes
#
#  major_groups_name_index  (name) UNIQUE
#  major_groups_slug_index  (slug) UNIQUE
#

class MajorGroup < ApplicationRecord
end
