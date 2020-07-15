# == Schema Information
#
# Table name: major_groups
#
#  id          :bigint           not null, primary key
#  inserted_at :datetime         not null
#  name        :string(255)
#  slug        :string(255)
#  created_at  :datetime
#  updated_at  :datetime         not null
#
# Indexes
#
#  major_groups_name_index  (name) UNIQUE
#  major_groups_slug_index  (slug) UNIQUE
#
class MajorGroup < ApplicationRecord
end
