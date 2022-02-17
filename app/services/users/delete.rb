module Users
  class Delete
    def initialize(user)
      @user = user
    end

    def call
      delete_comments
      delete_articles
      delete_user_activity
      user.unsubscribe_from_newsletters
      EdgeCache::Bust.call("/#{user.username}")
      Users::SuspendedUsername.create_from_user(user) if user.suspended?
      user.destroy
      Rails.cache.delete("user-destroy-token-#{user.id}")
    end

    def self.call(...)
      new(...).call
    end

    private

    attr_reader :user

    def delete_user_activity
      DeleteActivity.call(user)
    end

    def delete_comments
      DeleteComments.call(user)
    end

    def delete_articles
      DeleteArticles.call(user)
    end
  end
end
