require 'http'
require 'json'
require 'date'
require 'chronic'

class Notifier
  def initialize(pages_url, slack_url, live)
    @pages_url = pages_url
    @slack_url = slack_url
    @live = !!live
  end

  def notify_expired
    filter = ->(review_by) { review_by <= Date.today }
    msgs = messages_per_channel(filter)
    payloads = message_payloads(msgs,
        "I've found a page that is due for review",
        "I've found %s pages that are due for review")
    notify(payloads)
  end

  def notify_expires_within(timeframe)
    expires = Chronic.parse(timeframe).to_date
    filter = ->(review_by) { review_by > Date.today && review_by <= expires }
    msgs = messages_per_channel(filter)
    payloads = message_payloads(msgs,
        "I've found a page that will expire on or before #{expires.to_date}",
        "I've found %s pages that will expire on or before #{expires.to_date}")
    notify(payloads)
  end

  private

  def notify(payloads)
    puts "== JSON Payload:"
    puts JSON.pretty_generate(payloads)

    if Date.today.saturday? || Date.today.sunday?
      puts "SKIPPING POST: Not posting anything, this is not a working day"
      return
    end

    unless post_to_slack?
      puts "SKIPPING POST: Not posting anything, this is a dry run"
      return
    end

    message_payloads.each do |message_payload|
      HTTP.post(@slack_url, body: JSON.dump(message_payload))
    end
  end

  def pages
    JSON.parse(HTTP.get(@pages_url))
  end

  def messages_per_channel(filter = ->(_) { true })
    pages
      .reject { |page| page["review_by"] == nil }
      .select { |page| filter.call(Date.parse(page["review_by"])) }
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

  def message_payloads(messages_per_channel, msg_for_one, msg_for_other)
    messages_per_channel.map do |channel, messages|
      number_of = messages.size == 1 ? msg_for_one : msg_for_other
      number_of = number_of % [messages.size]

      message = <<~doc
        Hello :paw_prints:, this is your friendly manual spaniel. #{number_of}:

        #{messages.join("\n")}
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

  def post_to_slack?
    @live
  end
end
