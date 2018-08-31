require 'http'
require 'json'
require 'active_support'
require 'active_support/core_ext'

class Runner
  def run
    payloads = message_payloads

    puts "== JSON Payload:"
    puts JSON.pretty_generate(payloads)

    if Date.today.saturday? || Date.today.sunday?
      puts "SKIPPING POST: Not posting anything, this is not a working day"
      return
    end

    if ENV['REALLY_POST_TO_SLACK'] != "1"
      puts "SKIPPING POST: Not posting anything, this is a dry run"
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
          .map do |page|
            "- <#{page["url"]}|#{page["title"]}>"
          end
        [owner, messages]
      end
  end

  def message_payloads
    messages_per_channel.map do |channel, messages|
      number_of = messages.size == 1 ? "I've found a page that is due for review" : "I've found #{messages.size} pages that are due for review"

      message = <<~doc
        Hello :wave:, this is your friendly manual spaniel. #{number_of}:

        #{messages.join("\n")}

        Read <https://docs.publishing.service.gov.uk/manual/review-page.html|how to review a page> in the docs.
      doc

      puts "== Message to #{channel}"
      puts message

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
