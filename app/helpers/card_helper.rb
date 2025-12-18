# Card component helper
# Renders a reusable card with optional header, body, and footer sections.
#
# @param variant [Symbol] :default or :dark
# @param options [Hash] Additional HTML attributes for the card container
# @yield Block containing card sections
#
# Usage:
#   <%= card do %>
#     <%= card_body do %>
#       <p>Simple card content</p>
#     <% end %>
#   <% end %>
#
#   <%= card variant: :dark do %>
#     <%= card_header do %>
#       <%= card_title "My Title" %>
#     <% end %>
#     <%= card_body do %>
#       <p>Content here</p>
#     <% end %>
#     <%= card_footer do %>
#       <button>Action</button>
#     <% end %>
#   <% end %>
module CardHelper
  def card(variant: :default, **options, &block)
    classes = [ "card" ]
    classes << "card-dark" if variant == :dark
    classes << options.delete(:class) if options[:class]

    content_tag(:div, class: classes.join(" "), **options, &block)
  end

  def card_header(**options, &block)
    classes = [ "card-header", options.delete(:class) ].compact.join(" ")
    content_tag(:div, class: classes, **options, &block)
  end

  def card_title(text = nil, **options, &block)
    classes = [ "card-title", options.delete(:class) ].compact.join(" ")
    content_tag(:h2, text, class: classes, **options, &block)
  end

  def card_body(**options, &block)
    classes = [ "card-body", options.delete(:class) ].compact.join(" ")
    content_tag(:div, class: classes, **options, &block)
  end

  def card_footer(**options, &block)
    classes = [ "card-footer", options.delete(:class) ].compact.join(" ")
    content_tag(:div, class: classes, **options, &block)
  end
end
