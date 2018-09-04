require_relative './lib/runner'

task :run do
  pages_url = ENV.fetch("SITE_PAGE_API_URL")
  slack_url = ENV.fetch("SLACK_WEBHOOK_URL")
  live = ENV.fetch("REALLY_POST_TO_SLACK", 0) == "1"

  Runner.new(pages_url, slack_url, live).run
end
