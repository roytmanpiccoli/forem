class AddAttributesToPodcasts < ActiveRecord::Migration[4.2]
  def change
    add_column :podcasts, :twitter_username, :string
    add_column :podcasts, :website_url, :string
    add_column :podcasts, :main_color_hex, :string
  end
end
