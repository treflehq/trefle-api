# Renders the small set of FontAwesome icons the site actually uses as inline
# <svg>, instead of loading the 5.8 MB FontAwesome runtime kit (all.min.js)
# that used to scan the DOM for <i class="fad fa-..."> and replace it. See
# issue #231.
#
# The source SVGs (vendored under app/assets/images/icons/<style>/<name>.svg,
# copied from our licensed FontAwesome Pro kit) carry no fill of their own, so
# setting fill="currentColor" here keeps the existing Bulma `has-text-*` color
# utilities working exactly like before, including the duotone secondary-layer
# opacity baked into each duotone source file.
module IconHelper
  ICONS_PATH = Rails.root.join('app/assets/images/icons')

  # Icon sources never change at runtime, so read each one once per process.
  # A plain Hash with a default block (rather than a helper @ivar) keeps this
  # memoization off the view's instance state.
  ICON_SOURCES = Hash.new do |cache, (style, name)|
    cache[[style, name]] = File.read(ICONS_PATH.join(style.to_s, "#{name}.svg"))
  end

  def fa_icon(name, style: :duotone, **html_options)
    svg = ICON_SOURCES[[style, name]].dup
    classes = ['fa-icon', "fa-#{name}", html_options.delete(:class)].compact.join(' ')
    attrs = { class: classes, fill: 'currentColor', 'aria-hidden': 'true' }.merge(html_options)
    attrs_markup = attrs.map {|k, v| %(#{k}="#{ERB::Util.html_escape(v)}") }.join(' ')

    # The markup comes from our own vendored SVG files, not user input.
    svg.sub('<svg ', "<svg #{attrs_markup} ").html_safe # rubocop:disable Rails/OutputSafety
  end
end
