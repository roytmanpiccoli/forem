module DataUpdateScripts
  class IndexFeedContentToElasticsearch
    def run
      # Article.select(:id).find_each do |article|
      #   Search::IndexWorker.set(queue: :low_priority).perform_async(
      #     "Article", article.id
      #   )
      # end

      # PodcastEpisode.select(:id).find_each do |pde|
      #   Search::IndexWorker.set(queue: :low_priority).perform_async(
      #     "PodcastEpisode", pde.id
      #   )
      # end
    end
  end
end
