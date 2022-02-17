class JsFiddleTag < LiquidTagBase
  PARTIAL = "liquids/jsfiddle".freeze
  OPTION_REGEXP = /\A(js|html|css|result|,)*\z/
  REGISTRY_REGEXP = %r{\A(http|https)://(jsfiddle\.net)/[a-zA-Z0-9\-/]*\z}

  def initialize(_tag_name, link, _parse_context)
    super
    @link = parse_link(link)
    @build_options = parse_options(link)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        link: @link,
        build_options: @build_options,
        height: 600
      },
    )
  end

  private

  def valid_option(option)
    option.match(OPTION_REGEXP)
  end

  def parse_options(input)
    stripped_link = ActionController::Base.helpers.strip_tags(input)
    _, *options = stripped_link.split

    # Validation
    validated_options = options.filter_map { |option| valid_option(option) }
    unless options.empty? || !validated_options.empty?
      raise StandardError, I18n.t("liquid_tags.js_fiddle_tag.invalid_options")
    end

    validated_options.length.zero? ? "" : validated_options.join(",").concat("/")
  end

  def parse_link(link)
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    the_link = stripped_link.split.first
    raise StandardError, I18n.t("liquid_tags.js_fiddle_tag.invalid_jsfiddle_url") unless valid_link?(the_link)

    the_link
  end

  def valid_link?(link)
    link_no_space = link.delete(" ")
    (link_no_space =~ REGISTRY_REGEXP).zero?
  end
end

Liquid::Template.register_tag("jsfiddle", JsFiddleTag)

UnifiedEmbed.register(JsFiddleTag, regexp: JsFiddleTag::REGISTRY_REGEXP)
