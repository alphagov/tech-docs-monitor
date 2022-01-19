require 'chronic'

require_relative './expired'
require_relative './will_expire_by'
require_relative '../notifier'

SLACK_URL = ENV.fetch("SLACK_WEBHOOK_URL")
LIVE = ENV.fetch("REALLY_POST_TO_SLACK", 0) == "1"

def main(event:, context:)
  event = {"limits" => {}}.merge(event)
  puts "Event Received: #{event}"

  if event.fetch(:run_expired_page_check.to_s, false)
    expired(event)
    end
  if event.fetch(:run_expire_by_page_check.to_s, false)
    expired_by(event)
  end
end

def expired(event)
  puts "Checking for expired pages."
  notification = Notification::Expired.new
  event[:page_urls.to_s].each do |page_url|
    Notifier.new(notification, page_url, SLACK_URL, LIVE, event[:limits.to_s].fetch(page_url, -1)).run
  end
end

def expired_by(event)
  expire_by = Chronic.parse(event.fetch(:timeframe.to_s, "in 1 month")).to_date
  puts "Checking for pages which will have expired by #{expire_by}."
  notification = Notification::WillExpireBy.new(expire_by)

  event[:page_urls.to_s].each do |page_url|
    Notifier.new(notification, page_url, SLACK_URL, LIVE).run
  end
end