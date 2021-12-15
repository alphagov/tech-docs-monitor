require 'http'
require 'json'
require 'date'
require 'uri'

require_relative './page'
require_relative './notification/expired'
require_relative './notification/will_expire_by'

class Notifier
  def initialize(notification, pages_url, slack_url, live, limit = -1)
    @notification = notification
    @pages_url = pages_url
    @slack_url = slack_url
    @live = !!live
    @limit = limit
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
    JSON.parse(HTTP.get(@pages_url)).map { |data|
      data['url'] = get_absolute_url(data['url'])
      Page.new(data)
    }
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

      page_count = @limit == -1 ? pages.size : [pages.size, @limit].min
      notification_message = page_count == 1 ? @notification.singular_message : @notification.multiple_message
      number_of = notification_message % [page_count]

      page_lines = pages[0..page_count-1].map do |page|
        @notification.line_for(page)
      end

      message_prefix = ENV.fetch('OVERRIDE_SLACK_MESSAGE_PREFIX', "Hello :paw_prints:, this is your friendly manual spaniel.")
      message = <<~doc
        #{message_prefix} #{number_of}:

        #{page_lines.join("\n")}
      doc

      channel = ENV.fetch('OVERRIDE_SLACK_CHANNEL', channel)
      username = ENV.fetch('OVERRIDE_SLACK_USERNAME', "Daniel the Manual Spaniel")
      icon_emoji = ENV.fetch('OVERRIDE_SLACK_ICON_EMOJI', ":daniel-the-manual-spaniel:")

      puts "== Message to #{channel}"
      puts message

      {
        username: username,
        icon_emoji: icon_emoji,
        text: message,
        mrkdwn: true,
        channel: channel,
      }
    end
  end

  def post_to_slack?
    @live
  end

  private

  def get_absolute_url url
    target_uri = URI(url)
    target_path = Pathname.new(target_uri.path)
    source_uri = URI(@pages_url)

    if target_path.relative?
      resulting_path = URI::join(source_uri, target_uri.path).path
    else
      resulting_path = target_uri.path
    end

    if source_uri.scheme == 'https'
      URI::HTTPS.build(scheme: source_uri.scheme, port: source_uri.port, host: source_uri.host, path: resulting_path).to_s
    else
      URI::HTTP.build(scheme: source_uri.scheme, port: source_uri.port, host: source_uri.host, path: resulting_path).to_s
end
  end
end


