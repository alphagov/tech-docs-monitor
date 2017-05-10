require_relative './../lib/runner'

require "spec_helper"
require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
end

RSpec.describe Runner do
  it "generates the correct message" do
    VCR.use_cassette "fresh" do
      payloads = Runner.new.message_payloads

      expect(payloads).to match([
        {
          username: "Donkey of Docs",
          icon_emoji: ":donkeywork:",
          text: "Hello :wave:, this is your friendly donkey of documentation.\n\n- <https://docs.publishing.service.gov.uk/manual/alerts/asset-master-attachment-processing.html|asset master attachment processing> should be reviewed now\n",
          mrkdwn: true,
          channel: "#2ndline",
        },
        {
          username: "Donkey of Docs",
          icon_emoji: ":donkeywork:",
          text: "Hello :wave:, this is your friendly donkey of documentation.\n\n- <https://docs.publishing.service.gov.uk/manual/ab-testing.html|Run an A/B test> should be reviewed before 2017-04-14\n",
          mrkdwn: true,
          channel: "#taxonomy",
        }
      ])
    end
  end
end
