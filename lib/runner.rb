require 'http'
require 'json'

class Runner
  def run
    if Date.today.saturday? || Date.today.sunday?
      puts "Not posting anything, this is not a working day"
      return
    end

    if ENV['REALLY_POST_TO_SLACK'] != "1"
      puts "Not posting anything, this is a dry run"
      return
    end

    message_payloads.each do |message_payload|
      HTTP.post(ENV.fetch("BADGER_SLACK_WEBHOOK_URL"), body: JSON.dump(message_payload))
    end
  end

  def message_payloads
    docs = JSON.parse(HTTP.get('https://docs.publishing.service.gov.uk/api/page-freshness.json'))
    messages_per_channel = {}

    docs["expired_pages"].each do |page|
      messages_per_channel[page["owner_slack"]] ||= []
      messages_per_channel[page["owner_slack"]] << "- <#{page["url"]}|#{page["title"]}> should be reviewed now"
    end

    docs["expiring_soon"].each do |page|
      messages_per_channel[page["owner_slack"]] ||= []
      messages_per_channel[page["owner_slack"]] << "- <#{page["url"]}|#{page["title"]}> should be reviewed before #{page["review_by"]}"
    end

    messages_per_channel.map do |channel, messages|
      message = <<~doc
        Hello :wave:, this is your friendly donkey of documentation.

        #{messages.join("\n")}
      doc

      {
        username: "Donkey of Docs",
        icon_emoji: ":donkeywork:",
        text: message,
        mrkdwn: true,
        channel: channel,
      }
    end
  end
end
