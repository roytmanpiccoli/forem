class AppSecrets
  SETTABLE_SECRETS = %w[
    SLACK_CHANNEL
    SLACK_DEPLOY_CHANNEL
    SLACK_WEBHOOK_URL
  ].freeze

  def self.[](key)
    result = Vault.kv(namespace).read(key)&.data&.fetch(:value) if vault_enabled?
    result ||= ApplicationConfig[key]

    result
  rescue Vault::VaultError
    ApplicationConfig[key]
  end

  def self.[]=(key, value)
    Vault.kv(namespace).write(key, value: value)
  end

  def self.vault_enabled?
    ENV["VAULT_TOKEN"].present?
  end

  def self.namespace
    ENV["VAULT_SECRET_NAMESPACE"]
  end
  private_class_method :namespace
end
