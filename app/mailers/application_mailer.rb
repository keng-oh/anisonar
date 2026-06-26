class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "from@example.com"),
          reply_to: ENV.fetch("MAILER_REPLY_TO", "from@example.com")
  layout "mailer"
end
