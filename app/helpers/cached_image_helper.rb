# Helper for displaying cached Airtable images in views.
module CachedImageHelper
  # Returns an image tag for a cached Airtable image.
  # If the image isn't cached yet, returns a placeholder and queues a background job.
  #
  # @param airtable_id [String] The Airtable record ID
  # @param original_url [String] The original Airtable image URL
  # @param options [Hash] Options passed to image_tag (alt, class, etc.)
  # @return [String] HTML image tag
  def cached_image_tag(airtable_id, original_url, **options)
    cached_url = CachedImage.url_for(airtable_id, original_url)

    if cached_url
      image_tag(cached_url, **options)
    else
      # Return placeholder while image is being cached
      content_tag(:div, class: "image-placeholder #{options[:class]}") do
        content_tag(:span, "Loading...")
      end
    end
  end
end
