#!/bin/bash

# Mocks out sysctl writes for use in docker images where we can't write kernel config, and
# proxies reads down to sysctl proper

if [[ "$*" == *"-w"* ]]; then
    # Handle -w key=value format
    for arg in "$@"; do
        if [[ "$arg" == *"="* ]] && [[ "$arg" != "-w" ]]; then
            echo "${arg/=/ = }"
        fi
    done
    exit 0
elif [[ "$*" == *"="* ]]; then
    # Handle direct key=value format
    for arg in "$@"; do
        if [[ "$arg" == *"="* ]]; then
            echo "$arg"
        fi
    done
    exit 0
else
    exec /sbin/sysctl "$@"
fi
