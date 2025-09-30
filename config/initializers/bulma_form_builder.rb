# config/initializers/bulma_form_builder.rb

# There are a few things to mention:
# 1) See the article at the URL for sample code with screenshots and more information.
#    URL: https://medium.com/@dyanagi/a-bulma-form-builder-for-ruby-on-rails-applications-aef780808bab
# 2) This may not have covered all form controls.

# Form builder for Bulma
# Reference: https://bulma.io/documentation/form/
class BulmaFormBuilder < ActionView::Helpers::FormBuilder
  # Label for most types of input tags (text, password, email...)
  def label_default(method, text = nil, options = {}, &block)
    label(method, text, merge_class(options, 'label'), &block)
  end

  def label(method, text = nil, options = {}, &block)
    super(method, text, merge_class(options, 'label'), &block)
  end

  def label_check_box(method, text = nil, options = {}, &block)
    label(method, text, merge_class(options, 'checkbox'), &block)
  end

  def label_radio(method, text = nil, options = {}, &block)
    label(method, text, merge_class(options, 'radio'), &block)
  end

  def text_field(method, options = {})
    options[:placeholder] ||= true
    div_control(class: options[:control_class]) do
      super(method, merge_class(options, 'input'))
    end
  end

  def number_field(method, options = {})
    div_control(class: options[:control_class]) do
      super(method, merge_class(options, 'input'))
    end
  end

  def text_area_field(method, options = {})
    div_control(class: options[:control_class]) do
      super(method, merge_class(options, 'input'))
    end
  end

  def text_field_with_label(method, options = {})
    label_default(method) + text_field(method, options)
  end

  # Email field with an icon
  def email_field(method, options = {})
    div_control_for_icons do
      super(method, merge_class(options, 'input')) + email_icon
    end
  end

  # Email field with an icon, plus the label for it
  def email_field_with_label(method, options = {})
    label_default(method) + email_field(method, options)
  end

  # Password field with an icon
  def password_field(method, options = {})
    div_control_for_icons do
      super(method, merge_class(options, 'input')) + password_icon
    end
  end

  # Password field with an icon, plus the label for it
  def password_field_with_label(method, options = {})
    label_default(method) + password_field(method, options)
  end

  def select_with_label(method, choices = nil, options = {}, html_options = {}, &block)
    label_default(method) + select(method, choices, options, html_options, &block)
  end

  def simple_select(method, choices = nil, options = {}, html_options = {}, &block)
    label(method, class: 'select') do
      select(method, choices, options, html_options, &block)
    end
  end

  def multiple_select(method, choices = nil, options = {}, html_options = {}, &block)
    @template.content_tag(:div, class: 'select is-multiple') do
      select(method, choices, options, html_options, &block)
    end
  end

  def time_zone_select_with_label(method, priority_zones = nil, options = {}, html_options = {})
    label_default(method) + time_zone_select(method, priority_zones, options, html_options)
  end

  def time_zone_select(method, priority_zones = nil, options = {}, html_options = {})
    label(method, class: 'select') do
      super
    end
  end

  # Submit button without colour
  def submit(value = nil, options = {})
    div_control(class: options[:control_class]) do
      super(value, merge_class(options, 'button'))
    end
  end

  # Submit button with the primary colour for most forms
  def submit_primary(value = nil, options = {})
    submit(value, merge_class(options, 'is-primary'))
  end

  private

  # @param options [Hash]
  # @param value [String]
  def merge_class_attribute_value(options, value)
    new_options = options.clone
    new_options[:class] = [value, new_options[:class]].join(' ')
    new_options
  end

  alias merge_class merge_class_attribute_value

  def div_check_box
    @template.content_tag(:div, class: 'checkbox') do
      yield
    end
  end

  def div_control(options = {})
    @template.content_tag(:div, merge_class(options, 'control')) do
      yield
    end
  end

  def div_control_for_icons
    @template.content_tag(:div, class: 'control has-icons-left') do
      yield
    end
  end

  def email_icon
    @template.content_tag(:span, class: 'icon is-left') do
      @template.content_tag(:i, '', class: 'fas fa-envelope')
    end
  end

  def password_icon
    @template.content_tag(:span, class: 'icon is-left') do
      @template.content_tag(:i, '', class: 'fas fa-lock')
    end
  end
end
