class TwitterTimelineTag < LiquidTagBase
  include ActionView::Helpers::AssetTagHelper
  PARTIAL = "liquids/twitter_timeline".freeze

  URL_REGEXP = %r{\Ahttps://twitter\.com/[a-zA-Z0-9]+/timelines/\d+\Z}

  REGISTRY_REGEXP = %r{https://twitter\.com/[a-zA-Z0-9]+/timelines/\d+}

  SCRIPT = <<~JAVASCRIPT.freeze
    <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
  JAVASCRIPT

  def self.script
    SCRIPT
  end

  def initialize(_tag_name, link, _parse_context)
    super
    @href = parse_link(link)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        href: @href
      },
    )
  end

  private

  def parse_link(link)
    href = ActionController::Base.helpers.strip_tags(link).strip
    raise_error unless valid_link?(href)
    href
  end

  def valid_link?(link)
    link.match?(URL_REGEXP)
  end

  def raise_error
    raise StandardError, I18n.t("liquid_tags.twitter_timeline_tag.invalid_url")
  end
end

Liquid::Template.register_tag("twitter_timeline", TwitterTimelineTag)

UnifiedEmbed.register(TwitterTimelineTag, regexp: TwitterTimelineTag::REGISTRY_REGEXP)
