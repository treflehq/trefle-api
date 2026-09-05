module Quality
  # Terminal rendering of a single snapshot, kept out of the rake task.
  module SnapshotReport
    ROW = '  %-32<name>s %6.1<fill>f%% filled  %6<implausible>d implausible  %6<conflicts>d conflicts'.freeze

    def self.print(date)
      DataQualitySnapshot.on(date).global.where.not(attribute_name: nil)
        .sort_by {|s| s.fill_rate || 0 }
        .each do |snapshot|
          puts format(ROW, name: snapshot.attribute_name, fill: snapshot.fill_rate || 0,
                           implausible: snapshot.implausible_count, conflicts: snapshot.conflict_count)
        end
    end
  end
end
