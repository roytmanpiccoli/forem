# Be sure to restart your server when you modify this file.

# See: https://github.com/sass/sassc-ruby/issues/197
Rails.application.config.assets.configure do |env|
  env.export_concurrent = false
end

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.1"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules")

Rails.application.config.assets.paths << Rails.root.join("app/assets/xml")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w[markdown-it.min.js markdownlint-browser.min.js]
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
