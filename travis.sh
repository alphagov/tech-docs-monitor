#!/usr/bin/env bash

set -eu

: ${TRAVIS_EVENT_TYPE:?Not running on Travis}

bundle check || bundle install

case "$TRAVIS_EVENT_TYPE" in
  pull_request)
    echo "Running tests and not posting anywhere"
    bundle exec rspec
    REALLY_POST_TO_SLACK="0" bundle exec rake notify:expired
    ;;
  pr|pull_request|push)
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
