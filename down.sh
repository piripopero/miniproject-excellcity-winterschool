#!/bin/bash
set -e

dockerCmd="docker compose"
if (( $# == 2 )); then
    dockerCmd="docker-compose"
fi
${dockerCmd} down -v --remove-orphans 