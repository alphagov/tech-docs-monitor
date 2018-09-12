require_relative './../lib/runner'

require "spec_helper"
require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
end

RSpec.describe Notifier do
  it "generates the correct message" do
    VCR.use_cassette "fresh" do
      payloads = Notifier.new("https://gds-way.cloudapps.digital/api/pages.json", "", false).message_payloads

      expect(payloads).to match([
        {
          username: "Daniel the Manual Spaniel",
          icon_emoji: ":daniel-the-manual-spaniel:",
          text: "Hello :paw_prints:, this is your friendly manual spaniel. I've found 5 pages that are due for review:\n\n- <https://gds-way.cloudapps.digital/standards/supporting-services.html|Support Operations>\n- <https://gds-way.cloudapps.digital/standards/dns-hosting.html|How to manage DNS records for your service>\n- <https://gds-way.cloudapps.digital/standards/how-to-do-penetration-tests.html|How to do penetration tests>\n- <https://gds-way.cloudapps.digital/standards/publish-opensource-code.html|How to publish open source code>\n- <https://gds-way.cloudapps.digital/standards/sending-email.html|How to send email notifications>\n",
          mrkdwn: true,
          channel: "#gds-way",
        },
        {
          username: "Daniel the Manual Spaniel",
          icon_emoji: ":daniel-the-manual-spaniel:",
          text: "Hello :paw_prints:, this is your friendly manual spaniel. I've found a page that is due for review:\n\n- <https://gds-way.cloudapps.digital/standards/tracking-dependencies.html|How to manage third party software dependencies>\n",
          mrkdwn: true,
          channel: "@foobarx",
        }
      ])
    end
  end
end
