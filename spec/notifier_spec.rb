require_relative './../lib/notifier'

require "spec_helper"
require "vcr"
require "webmock/rspec"
require "timecop"

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
end

# Mock notification type that includes all pages
class AllPages
  def include?(_)
    true
  end
end

class NoHowToPages
  def include?(page)
    !page.title.start_with? "How"
  end
end

RSpec.describe Notifier, vcr: true do
  before do
    @pages_url = "https://gds-way.cloudapps.digital/api/pages.json"
    VCR.insert_cassette("fresh")
    Timecop.freeze(Time.local(2018, 9, 12, 0, 0, 0))
  end

  after do
    VCR.eject_cassette
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
    end
  end
end
