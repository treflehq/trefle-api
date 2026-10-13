# Builds the SVG of Management::ChartsHelper (kept out of app/helpers, which
# Rails includes into every view as modules). `view` is the view context, for
# its tag builder and number formatting.
class SvgChart
  WIDTH = 720
  PADDING = { top: 12, right: 12, bottom: 26, left: 44 }.freeze
  MAX_X_LABELS = 8

  def initialize(view, labels:, series:, height:, unit: nil, from_zero: true)
    @view = view
    @labels = labels
    @series = series
    @height = height
    @unit = unit
    @from_zero = from_zero
  end

  def columns
    group = plot_width / [@labels.size, 1].max
    column = [(group * 0.8) / @series.size, 1].max
    marks = @labels.each_index.flat_map do |i|
      left = PADDING[:left] + (i * group) + (group * 0.1)
      bars = @series.each_with_index.map {|s, j| bar(s, i, left + (j * column), column) }
      bars << x_label(i, left + (group * 0.4))
    end
    figure(marks)
  end

  def lines
    marks = @series.flat_map {|s| line(s) }
    marks += @labels.each_index.map {|i| x_label(i, x_at(i)) }
    figure(marks)
  end

  private

  def tag
    @view.tag
  end

  def number(value)
    "#{@view.number_with_delimiter(value)}#{@unit}"
  end

  def values
    @values ||= @series.flat_map {|s| s[:values] }.compact
  end

  def top
    @top ||= @from_zero ? round_up(values.max.to_f) : values.max.to_f.ceil
  end

  def bottom
    @bottom ||= @from_zero ? 0 : values.min.to_f.floor
  end

  # A round axis top: 1, 2 or 5 times a power of ten.
  def round_up(value)
    return 0 if value <= 0

    magnitude = 10**Math.log10(value).floor
    [1, 2, 5, 10].map {|f| f * magnitude }.find {|candidate| candidate >= value }
  end

  def plot_width
    WIDTH - PADDING[:left] - PADDING[:right]
  end

  def plot_height
    @height - PADDING[:top] - PADDING[:bottom]
  end

  def baseline
    PADDING[:top] + plot_height
  end

  def y_at(value)
    span = [top - bottom, 1].max
    baseline - ((value - bottom).to_f / span * plot_height)
  end

  def x_at(index)
    step = @labels.size > 1 ? plot_width.to_f / (@labels.size - 1) : 0
    PADDING[:left] + (index * step)
  end

  def bar(serie, index, left, width)
    value = serie[:values][index].to_i
    y = y_at(value)
    tag.rect(x: left.round(1), y: y.round(1), width: [width - 1, 1].max.round(1), height: (baseline - y).round(1),
             class: "chart__mark #{serie[:css]}") { tag.title(caption(serie, index, value)) }
  end

  def line(serie)
    points = serie[:values].each_with_index.filter_map {|value, i| [i, value] unless value.nil? }
    path = points.map {|i, value| "#{x_at(i).round(1)},#{y_at(value).round(1)}" }.join(' ')
    dots = points.map do |i, value|
      tag.circle(cx: x_at(i).round(1), cy: y_at(value).round(1), r: 3, class: "chart__dot #{serie[:css]}") do
        tag.title(caption(serie, i, value))
      end
    end
    [tag.polyline(points: path, class: "chart__line #{serie[:css]}"), *dots]
  end

  def caption(serie, index, value)
    "#{@labels[index]} · #{serie[:name]}: #{number(value)}"
  end

  def x_label(index, left)
    every = (@labels.size / MAX_X_LABELS.to_f).ceil.clamp(1, nil)
    return unless (index % every).zero?

    tag.text(@labels[index], x: left.round(1), y: baseline + 16, class: 'chart__axis-label', 'text-anchor': 'middle')
  end

  def axis
    [
      tag.line(x1: PADDING[:left], x2: WIDTH - PADDING[:right], y1: baseline, y2: baseline, class: 'chart__axis'),
      tag.line(x1: PADDING[:left], x2: WIDTH - PADDING[:right], y1: PADDING[:top], y2: PADDING[:top], class: 'chart__grid'),
      y_label(top, PADDING[:top] + 4),
      y_label(bottom, baseline + 4)
    ]
  end

  def y_label(value, top_px)
    tag.text(number(value), x: PADDING[:left] - 6, y: top_px, class: 'chart__axis-label', 'text-anchor': 'end')
  end

  def figure(marks)
    svg = tag.svg(@view.safe_join(axis + marks.compact), viewBox: "0 0 #{WIDTH} #{@height}", class: 'chart', role: 'img',
                                                         'aria-label': @series.pluck(:name).join(', '))
    legend = tag.div(@view.safe_join(@series.map {|s| tag.span(s[:name], class: "chart__key #{s[:css]}") }), class: 'chart__legend')
    tag.figure(@view.safe_join([svg, legend]), class: 'chart-figure')
  end
end
