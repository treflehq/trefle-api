# Small server-rendered SVG charts for the back office: no chart library, no
# JavaScript, readable without a request. Each mark carries a <title>, so
# hovering a column or a point gives its exact value.
#
#   series: [{ name: 'Accepted', css: 'is-accepted', values: [...] }, ...]
module Management::ChartsHelper
  # Grouped columns: one group per label, one column per series.
  def svg_column_chart(labels:, series:, height: 200)
    SvgChart.new(self, labels: labels, series: series, height: height).columns
  end

  # One line per series, a point per label. from_zero: false fits the axis to
  # the values, for a rate that moves by tenths and would look flat on 0-100.
  def svg_line_chart(labels:, series:, height: 160, unit: nil, from_zero: true)
    SvgChart.new(self, labels: labels, series: series, height: height, unit: unit, from_zero: from_zero).lines
  end
end
