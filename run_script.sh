#!/bin/bash
~/.rvm/bin/ruby ./scraper.rb
git add .
git commit -m"Adding changes scraped at `date`"
git push origin master
