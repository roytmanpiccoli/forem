class WikipediaTag < LiquidTagBase
  PARTIAL = "liquids/wikipedia".freeze
  REGISTRY_REGEXP = %r{\Ahttps?://([a-z-]+)\.wikipedia.org/wiki/(\S+)\z}
  TEXT_CLEANUP_XPATH = "//div[contains(@class, 'noprint') or contains(@class, 'hatnote')] | " \
                       "//span[@class='mw-ref'] | //figure | //sup".freeze

  def initialize(_tag_name, input, _parse_context)
    super
    @data = get_data(input.strip)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        title: @data[:title],
        extract: @data[:extract],
        url: @data[:url]
      },
    )
  end

  private

  def valid_url?(input)
    input.match?(REGISTRY_REGEXP)
  end

  def get_data(input)
    url = ActionController::Base.helpers.strip_tags(input).strip
    raise StandardError, I18n.t("liquid_tags.wikipedia_tag.invalid_wikipedia_url") unless valid_url?(url)

    uri = Addressable::URI.parse(url)
    lang = uri.host.split(".", 2).first
    title = uri.path.split("/").last
    anchor = uri.fragment

    if anchor
      parse_page_with_anchor(url, lang, title, anchor)
    else
      parse_page(url, lang, title)
    end
  end

  def parse_page_with_anchor(url, lang, title, anchor)
    api_url = "https://#{lang}.wikipedia.org/api/rest_v1/page/mobile-sections/#{title}"
    response = HTTParty.get(api_url, headers: { "user-agent": URL.url("/contact") })
    handle_response_error(response, url)

    text, section_title = get_section_contents(response, anchor, url)
    title = "#{response['lead']['normalizedtitle']} - #{section_title}"

    {
      title: title,
      url: url,
      extract: text_clean_up(text)
    }
  end

  def parse_page(url, lang, title)
    api_url = "https://#{lang}.wikipedia.org/api/rest_v1/page/summary/#{title}"
    response = HTTParty.get(api_url, headers: { "user-agent": URL.url("/contact") })
    handle_response_error(response, url)

    {
      title: response["title"],
      url: url,
      extract: response["extract_html"]
    }
  end

  def handle_response_error(response, input)
    return if response.code == 200

    raise StandardError,
          I18n.t("liquid_tags.wikipedia_tag.article_not_found", input: input, detail: (response["detail"]))
  end

  def get_section_contents(response, anchor, input)
    text = title = ""
    response["remaining"]["sections"].each do |section|
      if section["anchor"] == CGI.unescape(anchor)
        text = section["text"]
        title = section["line"]
      end
    end

    return [text, title] if title.present?

    raise StandardError, I18n.t("liquid_tags.wikipedia_tag.section_not_found", input: input)
  end

  def text_clean_up(text)
    doc = Nokogiri::HTML(text)

    doc.xpath(TEXT_CLEANUP_XPATH).each(&:remove)
    doc.xpath("//a").each { |x| x.replace Nokogiri::XML::Text.new(x.inner_html, x.document) }

    doc.to_html
  end
end

Liquid::Template.register_tag("wikipedia", WikipediaTag)

UnifiedEmbed.register(WikipediaTag, regexp: WikipediaTag::REGISTRY_REGEXP)
