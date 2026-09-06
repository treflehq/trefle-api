module Scopes
  # The corrections controller advertises filters and sorts, but the model
  # carried neither the Filterable machinery nor the scopes it calls — so every
  # filter[...] and order[...] on /api/v1/corrections returned a 500.
  module RecordCorrections
    extend ActiveSupport::Concern

    included do
      scope :filter_by_user_id, ->(v) { where(user_id: v) }
      scope :filter_by_record_id, ->(v) { where(record_id: v) }
      scope :filter_by_record_type, ->(v) { where(record_type: v) }
      scope :filter_by_warning_type, ->(v) { where(warning_type: v) }
      scope :filter_by_accepted_by, ->(v) { where(accepted_by: v) }
      scope :filter_by_source_reference, ->(v) { where(source_reference: v) }

      # Enums accept their names; an unknown name would otherwise raise inside
      # ActiveRecord rather than return an empty set.
      scope :filter_by_change_status, ->(v) { where(change_status: known_enum(:change_status, v)) }
      scope :filter_by_change_type, ->(v) { where(change_type: known_enum(:change_type, v)) }
      scope :filter_by_source_type, ->(v) { where(source_type: known_enum(:source_type, v)) }
    end

    class_methods do
      # Keeps only names the enum actually defines. An unrecognised name yields
      # no rows, which is the honest answer to "corrections whose status is
      # banana" — not an exception.
      def known_enum(name, values)
        allowed = public_send(name.to_s.pluralize).keys
        [*values].map(&:to_s) & allowed
      end
    end
  end
end
