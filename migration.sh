#!/bin/bash

# Set the source database connection info in a secrets file where it can be
# read by settings.migrate-on-pantheon.php

# CHANGEABLES
export SITE_ENV="botcivi8.dev"
export PANTHEON_D7_SITE="botcivi7"
export PANTHEON_D7_BRANCH="migratetest"


terminus drush $SITE_ENV -- status
terminus  env:wake $PANTHEON_D7_SITE.$PANTHEON_D7_BRANCH
export D7_MYSQL_URL=$(terminus connection:info $PANTHEON_D7_SITE.$PANTHEON_D7_BRANCH --field=mysql_url)
echo $D7_MYSQL_URL
terminus secrets:set $SITE_ENV migrate_source_db__url $D7_MYSQL_URL --clear

export PANTHEON_D7_URL="http://$PANTHEON_D7_BRANCH-$PANTHEON_D7_SITE.pantheonsite.io"

# Run a cache clear to take time. Otherwise immediately enabling modules
# after a code push might not work.
terminus env:clear-cache  $SITE_ENV
# terminus drush $SITE_ENV -- en -y migrate_plus migrate_tools migrate_upgrade
terminus connection:set $SITE_ENV sftp
terminus drush $SITE_ENV -- cache-rebuild
terminus drush $SITE_ENV -- config-export -y
terminus drush $SITE_ENV -- cache-rebuild

export D7_MYSQL_URL=$(terminus connection:info $PANTHEON_D7_SITE.$PANTHEON_D7_BRANCH --field=mysql_url)
terminus drush $SITE_ENV -- migrate-upgrade --configure-only --legacy-db-key=upgrade --legacy-root=$PANTHEON_D7_URL
# terminus drush $SITE_ENV -- migrate-upgrade --legacy-db-url=$D7_MYSQL_URL --configure-only  --legacy-db-key=migrate --legacy-root=$PANTHEON_D7_URL

# These cache rebuilds might not be necessary but I have seen odd errors
# related to migration registration go away after cache-rebuild.
# terminus drush $SITE_ENV -- cache-rebuild
terminus drush $SITE_ENV -- config-export -y
terminus drush $SITE_ENV -- cache-rebuild

terminus drush $SITE_ENV -- migrate-status

#terminus site code diffstat
# @todo commit the code change. But there seems to be a multidev bug preventing
# Terminus from seeing the code change. Terminus will only report a code change
# in terminus site code diffstat after the dashboard is refreshed.
