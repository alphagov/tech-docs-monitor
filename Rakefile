require_relative './lib/notifier'
require 'chronic'

task default: ["notify:expired"]

namespace :notify do
  pages_urls = [
    "https://ministryofjustice.github.io/hmpps-integration-api-docs/api/pages.json",
    "https://ministryofjustice.github.io/nvvs-devops/api/pages.json",
    "https://runbooks.cloud-platform.service.justice.gov.uk/api/pages.json",
    "https://technical-documentation.data-platform.service.justice.gov.uk/api/pages.json",
    "https://technical-guidance.service.justice.gov.uk/api/pages.json",
    "https://user-guide.cloud-platform.service.justice.gov.uk/api/pages.json",
    "https://user-guide.modernisation-platform.service.justice.gov.uk/api/pages.json",
    "https://runbooks.operations-engineering.service.justice.gov.uk/api/pages.json",
    "https://user-guide.operations-engineering.service.justice.gov.uk/api/pages.json"
  ]

  limits = {
    "https://ministryofjustice.github.io/nvvs-devops/api/pages.json" => 5,
    "https://technical-documentation.data-platform.service.justice.gov.uk/api/pages.json" => 5,
    "https://user-guide.modernisation-platform.service.justice.gov.uk/api/pages.json" => 5
  }

  live = ENV.fetch("REALLY_POST_TO_SLACK", 0) == "1"
  slack_url = ENV["SLACK_WEBHOOK_URL"]
  slack_token = ENV["SLACK_TOKEN"]

  if live && (!slack_url && !slack_token) then
    fail "If you want to post to Slack you need to set SLACK_TOKEN or SLACK_WEBHOOK_URL"
  end

  desc "Notifies of all pages which have expired"
  task :expired do
    notification = Notification::Expired.new

    pages_urls.each do |page_url|
      puts "== #{page_url}"

      Notifier.new(notification, page_url, slack_url, live, limits.fetch(page_url, -1)).run
    end
  end

  desc "Notifies of all pages which will expire soon"
  task :expires, :timeframe do |_, args|
    args.with_defaults(timeframe: "in 1 month")
    expire_by = Chronic.parse(args[:timeframe]).to_date
    notification = Notification::WillExpireBy.new(expire_by)

    pages_urls.each do |page_url|
      puts "== #{page_url}"

      Notifier.new(notification, page_url, slack_url, live).run
    end
  end
end
