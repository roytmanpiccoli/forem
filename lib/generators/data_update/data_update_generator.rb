class DataUpdateGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)
  class_option :spec, type: :boolean, default: true

  def create_data_update_file
    template("data_update.rb.tt", script_path)

    return unless options["spec"]

    template(
      "data_update_spec.rb.tt",
      File.join("spec", "lib", "data_update_scripts", class_path, "#{file_name}_spec.rb"),
    )
  end

  def script_path
    @script_path ||= begin
      script_name = "#{Time.current.utc.strftime('%Y%m%d%H%M%S')}_#{file_name}.rb"
      File.join("lib", "data_update_scripts", class_path, script_name)
    end
  end
end
