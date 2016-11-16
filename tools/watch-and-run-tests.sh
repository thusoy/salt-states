#!/bin/sh

TEST_COMMAND='./test --exitfirst --failed-first'

$TEST_COMMAND

./venv/bin/watchmedo shell-command \
    --patterns="*.py;*.sls" \
    --recursive \
    --wait \
    --drop \
    --command "$TEST_COMMAND" \
    salt/
