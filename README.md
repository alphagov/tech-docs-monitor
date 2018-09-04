# Tech Docs Template - page expiry notifier

This repo is part of the [tech-docs-template][template](), and is used in
conjunction with the [page expiry feature][expiry] that is part of the
[tech-docs-gem][gem]

Running the script will look at the pages API for your site, find all pages
that have expired, and post a Slack message to the owner of each page to let
them know that it needs reviewing.

[template]: https://github.com/alphagov/tech-docs-template
[expiry]: https://alphagov.github.io/tech-docs-manual/#page-expiry-and-review-notices
[gem]: https://github.com/alphagov/tech-docs-gem

## Usage

```ruby
bundle install
rake run
```

## Configuration

This notifier is configured using environment variables. All variables must be
defined:

* `SITE_PAGE_API_URL`: The full URL to your site's `/api/pages.json` file.
* `SLACK_WEBHOOK_URL`: The Slack webhook URL to allow messages to be posted.
* `REALLY_POST_TO_SLACK`: Messages will only be posted to Slack if the value of
  this var is `1`.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
