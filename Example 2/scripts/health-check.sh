#!/usr/bin/env bash
# usage: health-check.sh <url> [attempts] [interval_s]
set -u
url=$1; attempts=${2:-10}; interval=${3:-15}
for i in $(seq 1 "$attempts"); do
  if curl -fsS --max-time 10 "$url" >/dev/null; then echo "healthy ($i/$attempts)"; exit 0; fi
  echo "unhealthy ($i/$attempts)"; sleep "$interval"
done
exit 1
