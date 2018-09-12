require_relative './lib/runner'

task default: ["notify:expired"]

namespace :notify do
  pages_url = ENV.fetch("SITE_PAGE_API_URL")
  slack_url = ENV.fetch("SLACK_WEBHOOK_URL")
  live = ENV.fetch("REALLY_POST_TO_SLACK", 0) == "1"

  runner = Notifier.new(pages_url, slack_url, live)

  desc "Notifies of all pages which have expired"
  task :expired do
    runner.notify_expired
  end

  desc "Notifies of all pages which will expire soon"
  task :expires, :timeframe do |_, args|
    args.with_defaults(timeframe: "in 1 month")
    runner.notify_expires_within(args[:timeframe])
  end
end
