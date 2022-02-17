module Badges
  class AwardYearlyClub
    YEARS = {
      1 => "one",
      2 => "two",
      3 => "three",
      4 => "four",
      5 => "five",
      6 => "six",
      7 => "seven"
    }.freeze

    def self.call
      new.call
    end

    def call
      total_years = Time.current.year - Settings::Community.copyright_start_year.to_i
      (1..total_years).each do |i|
        ::Badges::Award.call(
          User.registered.where(created_at: i.year.ago - 2.days...i.year.ago),
          "#{YEARS[i]}-year-club",
          generate_message(i),
        )
      end
    end

    private

    def generate_message(years)
      I18n.t("services.badges.award_yearly_club.message", community: Settings::Community.community_name, count: years)
    end
  end
end
