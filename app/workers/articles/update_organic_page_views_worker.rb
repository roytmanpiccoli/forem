module Articles
  class UpdateOrganicPageViewsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority,
                    lock: :until_executing,
                    on_conflict: :replace,
                    retry: false

    GOOGLE_REFERRER = "https://www.google.com/".freeze

    def perform(article_id)
      article = Article.find(article_id)
      google_page_views = article.page_views.where(referrer: GOOGLE_REFERRER)
      update_params = {}

      organic_count = google_page_views.sum(:counts_for_number_of_views)
      if organic_count > article.organic_page_views_count
        update_params[:organic_page_views_count] = organic_count
      end

      past_week_count = sum_page_views(google_page_views, 1.week.ago)
      update_params[:organic_page_views_past_week_count] = past_week_count

      past_month_count = sum_page_views(google_page_views, 1.month.ago)
      update_params[:organic_page_views_past_month_count] = past_month_count

      article.update_columns(update_params)
    end

    private

    def sum_page_views(relation, timeframe)
      relation.where(created_at: timeframe..).sum(:counts_for_number_of_views)
    end
  end
end
