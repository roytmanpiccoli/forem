module Articles
  class Builder
    LINE_BREAK = "\n".freeze

    def initialize(user, tag, prefill)
      @user = user
      @tag = tag
      @prefill = prefill

      @editor_version2 = @user&.setting&.editor_version == "v2"
    end

    def self.call(...)
      new(...).call
    end

    # the Builder returns a pair of [article, store_location]
    # => store_location can be either true or false
    #
    # @note [@jeremyf] I renamed the boolean return value from
    #       needs_authorization to store_location.  Why? because in the
    #       ArticlesController#new action (the one place that instantiates the
    #       Articles::Builder) when "needs_authorization" was true, we'd call
    #       authorize(Article).  But at the time of writing, the implementation
    #       details of ArticlePolicy#new? always returned true.  So the
    #       "needs_authorization" was in fact behaving as a "should we store
    #       this location or not?"  Hence the rename and "switching the
    #       polarity" of the boolean.
    #
    # @see https://github.com/forem/forem/issues/16529 for snapshot of past
    #      state
    def call
      return [tag_user_editor_v2, false] if tag && editor_version2
      return [tag_user, false] if tag&.submission_template.present? && user
      return [prefill_user_editor_v2, false] if prefill.present? && editor_version2
      return [prefill_user, false] if prefill.present? && user
      return [tag_article, true] if tag
      return [user_editor_v2, true] if editor_version2

      [user_editor_v1, true]
    end

    private

    attr_reader :user, :tag, :prefill, :editor_version2

    def tag_user_editor_v2
      submission_template = tag.submission_template_customized(user.name).to_s

      Article.new(
        body_markdown: submission_template.split("---").last.to_s.strip,
        cached_tag_list: tag.name,
        processed_html: "",
        user_id: user.id,
        title: normalized_text(submission_template, "title:"),
      )
    end

    def tag_user
      Article.new(
        body_markdown: tag.submission_template_customized(user.name),
        processed_html: "",
        user_id: user.id,
      )
    end

    def prefill_user_editor_v2
      Article.new(
        body_markdown: prefill.split("---").last.to_s.strip,
        cached_tag_list: normalized_text(prefill, "tags:"),
        processed_html: "",
        user_id: user.id,
        title: normalized_text(prefill, "title:"),
      )
    end

    def prefill_user
      Article.new(
        body_markdown: prefill,
        processed_html: "",
        user_id: user.id,
      )
    end

    def tag_article
      Article.new(
        body_markdown: "---\ntitle: \npublished: false\ndescription: \ntags: #{tag.name}\n---\n\n",
        processed_html: "",
        user_id: user&.id,
      )
    end

    def user_editor_v2
      Article.new(user_id: user.id)
    end

    def user_editor_v1
      body = "---\ntitle: \npublished: false\ndescription: " \
             "\ntags: \n//cover_image: https://direct_url_to_image.jpg\n---\n\n"

      Article.new(
        body_markdown: body,
        processed_html: "",
        user_id: user&.id,
      )
    end

    def normalized_text(source, split_pattern)
      text = source.split(split_pattern).second.to_s
      text.split(LINE_BREAK).first.to_s.strip
    end
  end
end
