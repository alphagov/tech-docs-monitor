require_relative './../lib/notifier'

require "spec_helper"
require "vcr"
require "webmock/rspec"
require "timecop"

# Mock notification type that includes all pages
class AllPages
  def include?(_)
    true
  end

  def line_for(page)
    "- <#{page.url}|#{page.title}>"
  end

  def singular_message
    "I've found a page"
  end

  def multiple_message
    "I've found %s pages"
  end
end

class NoHowToPages
  def include?(page)
    !page.title.start_with? "How"
  end
end

RSpec.describe Notifier, vcr: "fresh" do
  before do
    @pages_url = "https://gds-way.cloudapps.digital/api/pages.json"
    Timecop.freeze(Time.local(2018, 9, 12, 0, 0, 0))
  end

  describe "#pages" do
    it "builds an array of pages" do
      pages = Notifier.new(nil, @pages_url, nil, nil).pages
      pages.is_a? Array
      expect(pages).to all(be_a Page)
    end
  end

  describe "#pages_per_channel" do
    it "correctly groups pages" do
      grouped_pages = Notifier.new(AllPages.new, @pages_url, nil, nil).pages_per_channel
      expect(grouped_pages.length).to eq 2

      channel, pages = grouped_pages.first
      expect(channel).to eq "#gds-way"
      expect(pages.length).to eq 18

      channel, pages = grouped_pages.last
      expect(channel).to eq "@foobarx"
      expect(pages.length).to eq 1
    end

    it "correctly orders pages within groups" do
      grouped_pages = Notifier.new(AllPages.new, @pages_url, nil, nil).pages_per_channel
      _, pages = grouped_pages.first
      expect(pages.first.review_by).to be <= pages.last.review_by
    end

    it "filters pages as expected" do
      grouped_pages = Notifier.new(NoHowToPages.new, @pages_url, nil, nil).pages_per_channel
      _, pages = grouped_pages.first
      expect(pages.length).to eq 6
    end
  end

  context "checking for expired pages" do
    before do
      @notifier = Notifier.new(Notification::Expired.new, @pages_url, "", false)
    end

    describe "#message_payloads" do
      it "generates the correct message" do
        payloads = @notifier.message_payloads(@notifier.pages_per_channel)

        expect(payloads).to match([
          {
            username: "Daniel the Manual Spaniel",
            icon_emoji: ":daniel-the-manual-spaniel:",
            text: "Hello :paw_prints:, this is your friendly manual spaniel. I've found 5 pages that are due for review:\n\n- <https://gds-way.cloudapps.digital/standards/supporting-services.html|Support Operations> (42 days ago)\n- <https://gds-way.cloudapps.digital/standards/dns-hosting.html|How to manage DNS records for your service> (11 days ago)\n- <https://gds-way.cloudapps.digital/standards/how-to-do-penetration-tests.html|How to do penetration tests> (11 days ago)\n- <https://gds-way.cloudapps.digital/standards/publish-opensource-code.html|How to publish open source code> (11 days ago)\n- <https://gds-way.cloudapps.digital/standards/sending-email.html|How to send email notifications> (11 days ago)\n",
            mrkdwn: true,
            channel: "#gds-way",
          },
          {
            username: "Daniel the Manual Spaniel",
            icon_emoji: ":daniel-the-manual-spaniel:",
            text: "Hello :paw_prints:, this is your friendly manual spaniel. I've found a page that is due for review:\n\n- <https://gds-way.cloudapps.digital/standards/tracking-dependencies.html|How to manage third party software dependencies> (2862 days ago)\n",
            mrkdwn: true,
            channel: "@foobarx",
          }
        ])
      end

      it "applies any configured overrides when generating the message" do
        overridden_message_prefix = "Hello :wave:, this is your friendly Docs as Code Monitor."
        allow(ENV).to receive(:fetch).with("OVERRIDE_SLACK_MESSAGE_PREFIX", anything)
                                  .and_return(overridden_message_prefix)

        overridden_slack_channel = "#team-custom-channel"
        allow(ENV).to receive(:fetch).with("OVERRIDE_SLACK_CHANNEL", anything)
                                  .and_return(overridden_slack_channel)

        overridden_slack_username = "edd.grant"
        allow(ENV).to receive(:fetch).with("OVERRIDE_SLACK_USERNAME", anything)
                                  .and_return(overridden_slack_username)

        overridden_slack_icon_emoji = ":information_source:"
        allow(ENV).to receive(:fetch).with("OVERRIDE_SLACK_ICON_EMOJI", anything)
                                  .and_return(overridden_slack_icon_emoji)


        payloads = @notifier.message_payloads(@notifier.pages_per_channel)

        expect(payloads).to match([
          {
            username: overridden_slack_username,
            icon_emoji: overridden_slack_icon_emoji,
            text: "#{overridden_message_prefix} I've found 5 pages that are due for review:\n\n- <https://gds-way.cloudapps.digital/standards/supporting-services.html|Support Operations> (42 days ago)\n- <https://gds-way.cloudapps.digital/standards/dns-hosting.html|How to manage DNS records for your service> (11 days ago)\n- <https://gds-way.cloudapps.digital/standards/how-to-do-penetration-tests.html|How to do penetration tests> (11 days ago)\n- <https://gds-way.cloudapps.digital/standards/publish-opensource-code.html|How to publish open source code> (11 days ago)\n- <https://gds-way.cloudapps.digital/standards/sending-email.html|How to send email notifications> (11 days ago)\n",
            mrkdwn: true,
            channel: overridden_slack_channel,
          },
          {
            username: overridden_slack_username,
            icon_emoji: overridden_slack_icon_emoji,
            text: "#{overridden_message_prefix} I've found a page that is due for review:\n\n- <https://gds-way.cloudapps.digital/standards/tracking-dependencies.html|How to manage third party software dependencies> (2862 days ago)\n",
            mrkdwn: true,
            channel: overridden_slack_channel,
          }
        ])
      end

      it "limits the number of pages sent to slack" do
          limited_notifier = Notifier.new(Notification::Expired.new, @pages_url, "", false, 3)
          payloads = limited_notifier.message_payloads(limited_notifier.pages_per_channel)

          expect(payloads).to match([
            {
              username: "Daniel the Manual Spaniel",
              icon_emoji: ":daniel-the-manual-spaniel:",
              text: "Hello :paw_prints:, this is your friendly manual spaniel. I've found 3 pages that are due for review:\n\n- <https://gds-way.cloudapps.digital/standards/supporting-services.html|Support Operations> (42 days ago)\n- <https://gds-way.cloudapps.digital/standards/dns-hosting.html|How to manage DNS records for your service> (11 days ago)\n- <https://gds-way.cloudapps.digital/standards/how-to-do-penetration-tests.html|How to do penetration tests> (11 days ago)\n",
              mrkdwn: true,
              channel: "#gds-way",
            },
            {
              username: "Daniel the Manual Spaniel",
              icon_emoji: ":daniel-the-manual-spaniel:",
              text: "Hello :paw_prints:, this is your friendly manual spaniel. I've found a page that is due for review:\n\n- <https://gds-way.cloudapps.digital/standards/tracking-dependencies.html|How to manage third party software dependencies> (2862 days ago)\n",
              mrkdwn: true,
              channel: "@foobarx",
            }
          ])
        end
    end
  end

  context "checking for pages nearing expiration" do
    before do
      notification = Notification::WillExpireBy.new(Date.parse("2018-10-12"))
      @notifier = Notifier.new(notification, @pages_url, "", false)
    end

    describe "#message_payloads" do
      it "generates the correct message" do
        payloads = @notifier.message_payloads(@notifier.pages_per_channel)

        expect(payloads).to match([
          {
            username: "Daniel the Manual Spaniel",
            icon_emoji: ":daniel-the-manual-spaniel:",
            text: "Hello :paw_prints:, this is your friendly manual spaniel. I've found 2 pages that will expire on or before 2018-10-12:\n\n- <https://gds-way.cloudapps.digital/standards/logging.html|How to store and query logs> (in 18 days)\n- <https://gds-way.cloudapps.digital/standards/monitoring.html|How to monitor your service> (in 18 days)\n",
            mrkdwn: true,
            channel: "#gds-way",
          }
        ])
      end

      it "allows overriding the slack channel" do
        ENV['OVERRIDE_SLACK_CHANNEL'] = '#override'
        payloads = @notifier.message_payloads(@notifier.pages_per_channel)

        expect(payloads).to match([
          {
            username: "Daniel the Manual Spaniel",
            icon_emoji: ":daniel-the-manual-spaniel:",
            text: "Hello :paw_prints:, this is your friendly manual spaniel. I've found 2 pages that will expire on or before 2018-10-12:\n\n- <https://gds-way.cloudapps.digital/standards/logging.html|How to store and query logs> (in 18 days)\n- <https://gds-way.cloudapps.digital/standards/monitoring.html|How to monitor your service> (in 18 days)\n",
            mrkdwn: true,
            channel: "#override",
          }
        ])
      end
    end
  end

  describe "#run" do
    before do
      ENV.delete("SLACK_TOKEN")

      @slack_webhook = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
      @slack_api = "https://slack.com/api/chat.postMessage"

      VCR.configure do |config|
        config.ignore_hosts "slack.com", "hooks.slack.com"
      end
    end

    after do
      VCR.configure do |config|
        config.unignore_hosts "slack.com", "hooks.slack.com"
      end
    end

    it "posts to Slack" do
      notifier = Notifier.new(AllPages.new, @pages_url, @slack_webhook, true)
      notifier.run
      expect(a_request(:post, @slack_webhook)).to have_been_made.times(2)
    end

    it "does not post to Slack if not live" do
      notifier = Notifier.new(AllPages.new, @pages_url, @slack_webhook, false)
      notifier.run
      expect(a_request(:post, @slack_webhook)).not_to have_been_made
    end

    it "uses the Slack API if SLACK_TOKEN is set" do
      slack_token = "xoxb-xxxxxxx"
      stub_const("ENV", {"SLACK_TOKEN" => slack_token})
      api_request = stub_request(:post, @slack_api)
        .to_return(body: '{"ok":true}', headers: {"Content-Type": "application/json; charset=utf-8"})

      notifier = Notifier.new(AllPages.new, @pages_url, @slack_webhook, true)
      notifier.run

      # We want to use the chat.postMessage API instead of webhooks
      expect(a_request(:post, @slack_webhook)).not_to have_been_made
      expect(api_request.with(headers: {"Authorization" => "Bearer #{slack_token}"}))
        .to have_been_made.times(2)
    end

    it "raises an error if SLACK_TOKEN is invalid" do
      slack_token = "xoxb-xxxxxxx"
      stub_const("ENV", {"SLACK_TOKEN" => slack_token})
      stub_request(:post, @slack_api)
        .to_return(body: '{"ok":false,"error":"invalid_auth"}', headers: {"Content-Type": "application/json; charset=utf-8"})

      notifier = Notifier.new(AllPages.new, @pages_url, @slack_url, true)

      expect {
        notifier.run
      }.to raise_error("Unable to post to Slack: SLACK_TOKEN is not valid")
    end

    it "prints a warning if post returns error" do
      slack_token = "xoxb-xxxxxxx"
      stub_const("ENV", {"SLACK_TOKEN" => slack_token})
      stub_request(:post, @slack_api)
        .to_return(body: '{"ok":false,"error":"channel_not_found"}', headers: {"Content-Type": "application/json; charset=utf-8"})

      notifier = Notifier.new(AllPages.new, @pages_url, @slack_url, true)

      expect {
        notifier.run
      }.to output(/Unable to post to Slack: channel_not_found/).to_stdout
    end
  end
end
