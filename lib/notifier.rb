require 'http'
require 'json'
require 'date'

require_relative './page'
require_relative './notification/expired'
require_relative './notification/will_expire_by'

class Notifier
  def initialize(notification, pages_url, slack_url, live)
    @notification = notification
    @pages_url = pages_url
    @slack_url = slack_url
    @live = !!live
  end

  def run
    payloads = message_payloads(pages_per_channel)

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

    payloads.each do |message_payload|
      HTTP.post(@slack_url, body: JSON.dump(message_payload))
    end
  end

  def pages
    JSON.parse(HTTP.get(@pages_url)).map { |data| Page.new(data) }
  end

  def pages_per_channel
    pages
      .reject { |page| page.review_by.nil? }
      .select { |page| @notification.include?(page) }
      .group_by { |page| page.owner }
      .map do |owner, pages|
        [owner, pages.sort_by { |page| page.review_by }]
      end
  end

  def message_payloads(grouped_pages)
    grouped_pages.map do |channel, pages|
      number_of = pages.size == 1 ? @notification.singular_message : @notification.multiple_message
      number_of = number_of % [pages.size]

      page_lines = pages.map do |page|
        @notification.line_for(page)
      end

      message = <<~doc
        Hello :paw_prints:, this is your friendly manual spaniel. #{number_of}:

        #{page_lines.join("\n")}
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
