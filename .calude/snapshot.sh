#!/bin/bash
# snapshot.sh — runs once during /warm to build the snapshot baseline.
# Output of this script is what gets baked into the persisted snapshot.
# Edit this file, then commit and push to keep changes.
# See also: .calude/boot.sh (runs after every snapshot restore).
set -euo pipefail

changed Gemfile.lock licensed.gemspec && bundle install

if [ -x script/setup ]; then
  script/setup || true
fi