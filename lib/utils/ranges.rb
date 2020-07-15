module Utils
  module Ranges
    MONTHS = %i[jan feb mar apr may jun jul aug sep oct nov dec].freeze

    def self.interval_to_months(start_month_num, end_month_num)
      start_mo = start_month_num - 1
      end_mo = end_month_num - 1

      months = MONTHS.slice(start_mo..end_mo)
      months = [*MONTHS.slice(start_mo, 12), *MONTHS.slice(0..end_mo)] if end_mo < start_mo
      months
    end
  end
end
