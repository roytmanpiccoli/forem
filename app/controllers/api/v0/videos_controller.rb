module Api
  module V0
    class VideosController < ApiController
      before_action :set_cache_control_headers, only: %i[index]

      INDEX_ATTRIBUTES_FOR_SERIALIZATION = %i[
        id video path title video_thumbnail_url user_id video_duration_in_seconds video_source_url
      ].freeze
      private_constant :INDEX_ATTRIBUTES_FOR_SERIALIZATION

      def index
        page = params[:page]
        per_page = (params[:per_page] || 24).to_i
        num = [per_page, 1000].min

        @video_articles = Article.with_video
          .includes([:user])
          .select(INDEX_ATTRIBUTES_FOR_SERIALIZATION)
          .order(hotness_score: :desc)
          .page(page).per(num)

        set_surrogate_key_header "videos", Article.table_key, @video_articles.map(&:record_key)
      end
    end
  end
end
