#!/bin/sh

heroku pg:backups capture
curl -o latest.dump `heroku pg:backups public-url`
