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
      puts JSON.pretty_generate(message_payloads)
      return
    end

    message_payloads.each do |message_payload|
      HTTP.post(ENV.fetch("BADGER_SLACK_WEBHOOK_URL"), body: JSON.dump(message_payload))
    end
  end

  def page_freshness
    JSON.parse(HTTP.get('https://docs.publishing.service.gov.uk/api/page-freshness.json'))
  end

  def messages_per_channel
    page_freshness["expired_pages"]
      .group_by { |page| page["owner_slack"] }
      .map do |owner, pages|
        messages = pages
          .sort_by { |page| page["review_by"] }
          .first(5)
          .map do |page|
            "<#{page["url"]}|#{page["title"]}> should be reviewed now"
          end
        [owner, messages]
      end
  end

  def message_payloads
    messages_per_channel.map do |channel, messages|
      message = <<~doc
        Hello :wave:, this is your friendly manual spaniel.

        #{messages.join("\n")}
      doc

      {
        username: "Daniel the Manual Spaniel",
        icon_emoji: ":daniel-the-manual-spaniel:",
        text: message,
        mrkdwn: true,
        channel: channel,
      }
    end
  end
end
