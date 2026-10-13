# Why a reviewer accepted or rejected a correction. Until now the reason was
# appended to `notes`, which the submitter writes and the ingester also uses
# for its refusals; the decision gets its own field.
class AddReviewCommentToRecordCorrections < ActiveRecord::Migration[8.1]
  def change
    add_column :record_corrections, :review_comment, :text
  end
end
