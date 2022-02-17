if Rails.env.development?
  require "listen"

  # rubocop:disable Metrics/BlockLength
  namespace :pages do
    desc "Automated sync of Page HTML body by listening to changes of local file"
    task :sync, %i[slug filepath] => [:environment] do |_task, args|
      next if Rails.env.production?

      pathname = Pathname.new(args.filepath)

      if !File.file?(pathname) || Page.find_by(slug: args.slug).nil?
        puts "Error: Unable to find Page or local HTML file to sync"
        next
      end

      listener = Listen.to(pathname.dirname, only: /#{pathname.basename}/i) do
        page = Page.find_by(slug: args.slug)

        if page.nil?
          puts "Error: Page with slug '#{args.slug}' not found"
          next
        end

        page.body_html = File.read(pathname.to_s)
        if page.save
          puts "Updated contents of Page now available in '#{page.path}'"
        else
          puts "Error updating Page: #{page.errors.messages}"
        end
      end

      listener.start # not blocking
      puts "Watching file '#{pathname}' for changes... Happy Coding!"
      begin
        sleep
      rescue StandardError
        puts "\nBye :)"
      end
    end
  end
  # rubocop:enable Metrics/BlockLength
end
