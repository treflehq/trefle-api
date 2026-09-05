module Quality
  # Terminal rendering of Quality::Evolution, kept out of the rake task so the
  # task stays a one-liner and this stays testable.
  module EvolutionReport
    HEADER = '%-12<date>s %10<rate>s %9<change>s %14<filled>s %12<conflicts>s'.freeze
    ROW = '%-12<date>s %9<rate>s%% %9<change>s %14<filled>s %12<conflicts>s'.freeze

    def self.print(days: 30)
      evolution = Quality::Evolution.new(days: days)
      series = evolution.series

      if series.size < 2
        puts "Only #{series.size} snapshot so far — the daily job builds this up."
        return
      end

      print_series(series)
      print_moves(evolution.field_moves)
    end

    def self.print_series(series)
      puts format(HEADER, date: 'date', rate: 'fill rate', change: 'change',
                          filled: 'filled cells', conflicts: 'conflicts')
      previous = nil
      series.each do |point|
        puts format(ROW, date: point.date.to_s, rate: point.fill_rate,
                         change: change_label(previous, point),
                         filled: point.filled_count.to_s,
                         conflicts: point.conflict_count.to_s)
        previous = point
      end
    end

    def self.change_label(previous, point)
      return '-' unless previous&.fill_rate && point.fill_rate

      diff = (point.fill_rate - previous.fill_rate).round(2)
      diff.positive? ? "+#{diff}" : diff.to_s
    end

    def self.print_moves(moves)
      return if moves.empty?

      puts "\nWhat moved:"
      moves.first(15).each do |move|
        puts format('  %-28<field>s %+<delta>d', field: move.field, delta: move.delta)
      end
    end
  end
end
