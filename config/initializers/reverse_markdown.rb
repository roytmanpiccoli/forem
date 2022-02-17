Rails.application.reloader.to_prepare do
  Dir.glob(Rails.root.join("app/lib/reverse_markdown/converters/*.rb")).each do |filename|
    require_dependency filename
  end
end
