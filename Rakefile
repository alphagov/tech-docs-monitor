require_relative './lib/notifier'
require 'chronic'

task default: ["notify:expired"]

namespace :notify do
  pages_urls = [
    "https://www.docs.verify.service.gov.uk/api/pages.json",
    "https://gds-way.cloudapps.digital/api/pages.json",
    "https://docs.publishing.service.gov.uk/api/pages.json",
    "https://verify-team-manual.cloudapps.digital/api/pages.json",
    "https://dcs-pilot-docs.cloudapps.digital/api/pages.json",
    "https://dcs-service-manual.cloudapps.digital/api/pages.json",
    "https://docs.payments.service.gov.uk/api/pages.json",
  ]

  slack_url = ENV.fetch("SLACK_WEBHOOK_URL")
  live = ENV.fetch("REALLY_POST_TO_SLACK", 0) == "1"

  desc "Notifies of all pages which have expired"
  task :expired do
    notification = Notification::Expired.new

    pages_urls.each do |page_url|
      Notifier.new(notification, page_url, slack_url, live).run
    end
  end

  desc "Notifies of all pages which will expire soon"
  task :expires, :timeframe do |_, args|
    args.with_defaults(timeframe: "in 1 month")
    expire_by = Chronic.parse(args[:timeframe]).to_date
    notification = Notification::WillExpireBy.new(expire_by)

    pages_urls.each do |page_url|
      Notifier.new(notification, page_url, slack_url, live).run
    end
  end
end
