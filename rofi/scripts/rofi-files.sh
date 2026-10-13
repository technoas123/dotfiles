#!/usr/bin/env bash

# If a file path is passed from selection, launch it
if [ -n "$1" ]; then
    xdg-open "$1" >/dev/null 2>&1 &
    exit 0
fi

# Fast file indexing: limit depth to 3 levels and exclude heavy build/cache directories
fdfind --type f \
    --max-depth 3 \
    --exclude .git \
    --exclude .cache \
    --exclude .local \
    --exclude .config \
    --exclude node_modules \
    . "$HOME" 2>/dev/null
