require 'http'
require 'json'

class Runner
  def run
    unless Date.today.monday?
      puts "Not posting anything, this is not a Monday"
      # TODO: always post now we're testing
      # return
    end

    if ENV['REALLY_POST_TO_SLACK'] != "1"
      puts "Not posting anything, this is a dry run"
      return
    end

    HTTP.post(ENV.fetch("BADGER_SLACK_WEBHOOK_URL"), body: JSON.dump(message_payload))
  end

  def message_payload
    docs = JSON.parse(HTTP.get('https://docs.publishing.service.gov.uk/api/page-freshness.json'))
    messages = []

    docs["expired_pages"].each do |page|
      messages << "- <#{page["url"]}|#{page["title"]}> should be reviewed now by #{page["owner_slack"]}"
    end

    docs["expiring_soon"].each do |page|
      messages << "- <#{page["url"]}|#{page["title"]}> should be reviewed before #{page["review_by"]} by #{page["owner_slack"]}"
    end

    status = messages.any? ? messages.join("\n") : "All docs are up to date!"

    message = "Hello :wave:, this is your friendly donkey of documentation. \n\n#{status}"

    {
      username: "Donkey of Docs",
      icon_emoji: ":donkeywork:",
      text: message,
      mrkdwn: true,
      channel: '#2ndline',
    }
  end
end
