# Tech Docs Template - page expiry notifier

This repo is part of the [tech-docs-template][template], and is used in
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
rake notify:expired
rake notify:expires
```

## Deployment

Heroku is the simplest option.  The script can run quite happily on a free dyno
using the Heroku Scheduler add-on.

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

Note: the above will deploy the app to your Heroku account, and add the
Scheduler add-on, but _won't_ configure it to run.  To do this, go to your
[dashboard](https://dashboard.heroku.com/apps), find the appropriate app, open
the Scheduler add-on, and add a new job that runs `rake notify:expired` or `rake notify:expires` once a day.

## Configuration

This notifier is configured using environment variables. All variables must be
defined:

* `SITE_PAGE_API_URL`: The full URL to your site's `/api/pages.json` file.
* `SLACK_WEBHOOK_URL`: The Slack webhook URL to allow messages to be posted.
* `REALLY_POST_TO_SLACK`: Messages will only be posted to Slack if the value of
  this var is `1`.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
