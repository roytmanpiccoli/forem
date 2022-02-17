module Badges
  class AwardBelovedComment
    BADGE_SLUG = "beloved-comment".freeze

    def self.call(comment_count = 25)
      new(comment_count).call
    end

    def initialize(comment_count)
      @comment_count = comment_count
    end

    def call
      return unless (badge_id = Badge.id_for_slug(BADGE_SLUG))

      Comment.includes(:user).where(public_reactions_count: comment_count..).find_each do |comment|
        achievement = BadgeAchievement.create(
          user_id: comment.user_id,
          badge_id: badge_id,
          rewarding_context_message_markdown: generate_message(comment),
        )
        comment.user.touch if achievement.valid?
      end
    end

    private

    attr_reader :comment_count

    def generate_message(comment)
      I18n.t("services.badges.award_beloved_comment.message", comment: URL.comment(comment))
    end
  end
end
