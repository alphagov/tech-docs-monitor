#!/usr/bin/env bash

set -eu

: ${TRAVIS_EVENT_TYPE:?Not running on Travis}

bundle check || bundle install

case "$TRAVIS_EVENT_TYPE" in
  pull_request)
    echo "Running tests and not posting anywhere"
    bundle exec rspec
    REALLY_POST_TO_SLACK="0" SLACK_WEBHOOK_URL="http://none.local" bundle exec rake notify:expired
    ;;
  pr|push)
    echo "Running tests and posting to #bot-testing"
    bundle exec rspec
    OVERRIDE_SLACK_CHANNEL="#bot-testing" bundle exec rake notify:expired
    ;;
  cron)
    bundle exec rake notify:expired
    ;;
  *)
    echo "TRAVIS_EVENT_TYPE was $TRAVIS_EVENT_TYPE - something's wrong :(" >/dev/stderr
    ;;
esac 
