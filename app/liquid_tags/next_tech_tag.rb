class NextTechTag < LiquidTagBase
  PARTIAL = "liquids/nexttech".freeze
  REGISTRY_REGEXP = %r{https?://nt.dev/s/}

  def initialize(_tag_name, share_url, _parse_context)
    super
    @token = parse_share_url(share_url)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        token: @token
      },
    )
  end

  private

  # Returns the share token from the end of the share URL.
  def parse_share_url(share_url)
    clean_share_url = ActionController::Base.helpers.strip_tags(share_url).delete(" ").gsub(/\?.*/, "")
    unless valid_share_url?(clean_share_url)
      raise StandardError, I18n.t("liquid_tags.next_tech_tag.invalid_url")
    end

    clean_share_url.split("/").last
  end

  # Examples of valid share URLs:
  #   - https://nt.dev/s/123456abcdef
  #   - http://nt.dev/s/123456abcdef/
  #   - nt.dev/s/123456abcdef
  def valid_share_url?(share_url)
    (share_url =~ %r{^(?:(?:http|https)://)?nt\.dev/s/[a-z0-9]{12}/{0,1}$})&.zero?
  end
end

Liquid::Template.register_tag("nexttech", NextTechTag)

UnifiedEmbed.register(NextTechTag, regexp: NextTechTag::REGISTRY_REGEXP)
