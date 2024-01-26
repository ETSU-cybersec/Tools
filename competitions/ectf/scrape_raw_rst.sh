#!/bin/bash
# Author: Reid Bandy
# This script should get all of the .rst files from the ectf-website along with images and other files. This is useful
# for grepping through the all of the files for keywords.

wget --recursive \
    --no-clobber \
    --continue \
    --convert-links \
    --no-netrc \
    --show-progress \
    --limit-rate=50k \
    --timeout=30 \
    --random-wait \
    --html-extension \
    --wait="1" \
    --domains ectfmitre.gitlab.io \
    --reject ".css,.html,.js" \
    --tries=2 \
    --timeout=10 \
    -D "202[0-9],about,_static" \
    --no-parent https://ectfmitre.gitlab.io/ectf-website
