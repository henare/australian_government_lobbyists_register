#!/bin/bash
./scraper.rb
git add .
git commit "Adding changes scraped at `date`"
git push origin master
