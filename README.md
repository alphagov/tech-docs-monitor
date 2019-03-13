# Tech Docs Template - page expiry notifier

This repo is part of the [tech-docs-template][template], and is used in
conjunction with the [page expiry feature][expiry] that is part of the
[tech-docs-gem][gem]

Travis CI will run the script once a day during weekdays.
It will look at the pages API for your site, find all pages that have expired, and post a Slack message to the owner of each page to let them know that it needs reviewing.

[template]: https://github.com/alphagov/tech-docs-template
[expiry]: https://alphagov.github.io/tech-docs-manual/#last-reviewed-on-and-review-in
[gem]: https://github.com/alphagov/tech-docs-gem

## Usage

### `alphagov` users

If you are part of the `alphagov` GitHub organisation you can enable the notifier by raising a PR to add your published documentation to the [`.travis.yml` file][travis]:

```
matrix:
  - SITE_PAGE_API_URL=https://www.docs.verify.service.gov.uk/api/pages.json
  - SITE_PAGE_API_URL=https://gds-way.cloudapps.digital/api/pages.json
  - SITE_PAGE_API_URL=https://<YOUR_PUBLISHED_DOCS>/api/pages.json
```

[travis]: https://github.com/alphagov/tech-docs-monitor/blob/master/.travis.yml

### Configure Travis CI

If you are not part of the `alphagov` GitHub organisation, you can still configure Travis CI to automatically deploy the notifier:

1. Fork the `tech-docs-monitor` repository
1. Get an [incoming Slack webhook][webhook] for the notifier
1. Run [`travis encrypt`][encrypt] to add the encrypted webhook to your `.travis.yml` file
1. Add your published documentation page API URL to `env.matrix` in your `.travis.yml` file

[encrypt]: https://docs.travis-ci.com/user/encryption-keys/#usage
[webhook]: https://api.slack.com/incoming-webhooks

### General configuration

If you want to use something other than Travis CI to deploy the notifier, you must make sure all its environment variables are defined:

* `SITE_PAGE_API_URL`: The full URL to your site's `/api/pages.json` file.
* `SLACK_WEBHOOK_URL`: The Slack webhook URL to allow messages to be posted.
* `REALLY_POST_TO_SLACK`: Messages will only be posted to Slack if the value of
  this var is `1`.

## Licence

The gem is available as open source under the terms of the [MIT License](LICENCE).
