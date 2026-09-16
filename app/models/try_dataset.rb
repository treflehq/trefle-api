# == Schema Information
#
# Table name: try_datasets
#
#  id           :integer          not null, primary key
#  dataset_id   :integer          not null
#  dataset_name :string
#  contributor  :string
#  reference    :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_try_datasets_on_dataset_id                (dataset_id)
#  index_try_datasets_on_dataset_id_and_reference  (dataset_id,reference) UNIQUE
#

# One dataset contributed to TRY, with the credit CC BY owes it.
#
# TRY is published under CC BY, and its release notes ask for two citations:
# the TRY reference itself (carried on the ForeignSource) and the reference of
# each contributing dataset. A SpeciesFact records which datasets fed it; this
# is what those numbers resolve to.
#
# Seeded from db/data/try_datasets.yml, extracted from the exports. The exports
# are 30 GB and live nowhere but a laptop, so the register is committed rather
# than derived at boot — the credit has to outlive the files it came from.
class TryDataset < ApplicationRecord

  validates :dataset_id, presence: true

  scope :for_dataset, ->(id) { where(dataset_id: id) }

  # A dataset TRY ships with no citable publication. 139 of 727 — still owed
  # credit, so the contributor and dataset name carry it instead.
  scope :without_reference, -> { where(reference: [nil, '']) }

  def self.register_path
    Rails.root.join('db/data/try_datasets.yml')
  end

  # The citation line for one dataset: its reference when it has one, and
  # otherwise the contributor and dataset name, which is all the export gives.
  def credit
    return reference if reference.present?

    [contributor, dataset_name].compact_blank.join(' — ').presence
  end

end
