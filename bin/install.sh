#!/bin/bash
rm -f node_modules/bitrated-lib
ln -s ../../bitrated-lib node_modules/
rm -f views/pages
ln -s ../../bitrated-pages views/pages
