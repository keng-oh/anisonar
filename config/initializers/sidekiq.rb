Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  config.on(:startup) do
    Sidekiq::Cron::Job.load_from_hash(YAML.load_file(Rails.root.join("config/cron.yml")))
  end

  config.death_handlers << ->(job, ex) do
    Rails.error.report(ex, handled: false, source: "sidekiq", context: { job_class: job["class"] })
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
