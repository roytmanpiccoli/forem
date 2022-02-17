module Images
  module Optimizer
    def self.call(img_src, **kwargs)
      return img_src if img_src.blank? || img_src.starts_with?("/")

      if imgproxy_enabled?
        imgproxy(img_src, **kwargs)
      elsif cloudinary_enabled?
        cloudinary(img_src, **kwargs)
      else
        img_src
      end
    end

    DEFAULT_CL_OPTIONS = {
      type: "fetch",
      height: nil,
      width: nil,
      crop: "limit",
      quality: "auto",
      flags: "progressive",
      fetch_format: "auto",
      sign_url: true
    }.freeze

    def self.cloudinary(img_src, **kwargs)
      options = DEFAULT_CL_OPTIONS.merge(kwargs).compact_blank

      if img_src&.include?(".gif")
        options[:quality] = 66
      end

      ActionController::Base.helpers.cl_image_path(img_src, options)
    end

    DEFAULT_IMGPROXY_OPTIONS = {
      height: nil,
      width: nil,
      max_bytes: 500_000, # Keep everything under half of one MB.
      auto_rotate: true,
      resizing_type: nil
    }.freeze

    def self.imgproxy(img_src, **kwargs)
      translated_options = translate_cloudinary_options(kwargs)
      options = DEFAULT_IMGPROXY_OPTIONS.merge(translated_options).compact_blank
      Imgproxy.config.endpoint ||= get_imgproxy_endpoint
      Imgproxy.url_for(img_src, options)
    end

    def self.translate_cloudinary_options(options)
      if options[:crop] == "fill"
        options[:resizing_type] = "fill"
      end

      options[:crop] = nil
      options[:fetch_format] = nil
      options
    end

    def self.imgproxy_enabled?
      Imgproxy.config.key.present? && Imgproxy.config.salt.present?
    end

    def self.cloudinary_enabled?
      config = Cloudinary.config

      config.cloud_name.present? && config.api_key.present? && config.api_secret.present?
    end

    def self.get_imgproxy_endpoint
      if Rails.env.production?
        # Use /images with the same domain on Production as
        # our default configuration
        URL.url("images")
        # ie. https://forem.dev/images
      else
        # On other environments, rely on ApplicationConfig for a
        # more flexible configuration
        # ie. default imgproxy endpoint is localhost:8080
        ApplicationConfig["IMGPROXY_ENDPOINT"] || "http://localhost:8080"
      end
    end
  end
end
