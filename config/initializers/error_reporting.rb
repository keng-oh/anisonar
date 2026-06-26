Rails.application.config.after_initialize do
  Rails.error.subscribe(Notifications::ErrorReporter)
end
