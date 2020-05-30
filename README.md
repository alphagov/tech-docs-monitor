# Tech Docs Template - page expiry notifier

This repo is part of the [tech-docs-template][template], and is used in
conjunction with the [page expiry feature][expiry] that is part of the
[tech-docs-gem][gem]

Concourse CI will run the script once a day during weekdays.
It will look at the pages API for your site, find all pages that have expired, and post a Slack message to the owner of each page to let them know that it needs reviewing.

[template]: https://github.com/alphagov/tech-docs-template
[expiry]: https://alphagov.github.io/tech-docs-manual/#last-reviewed-on-and-review-in
[gem]: https://github.com/alphagov/tech-docs-gem

## Usage

### `alphagov` users

If you are part of the `alphagov` GitHub organisation you can enable the notifier by raising a PR to add your published documentation to the [`Rakefile`][Rakefile]:

```
pages_urls = [
  "https://gds-way.cloudapps.digital/api/pages.json",
  "https://docs.publishing.service.gov.uk/api/pages.json",
  "your-docs-site.cloudapps.digital"
]
```

[Rakefile]: https://github.com/alphagov/tech-docs-monitor/blob/master/Rakefile

### General configuration

The following environment variables are necessary:

* `SITE_PAGE_API_URL`: The full URL to your site's `/api/pages.json` file.
* `SLACK_WEBHOOK_URL`: The Slack webhook URL to allow messages to be posted.
* `REALLY_POST_TO_SLACK`: Messages will only be posted to Slack if the value of
  this var is `1`.

## Licence

The gem is available as open source under the terms of the [MIT License](LICENCE).
