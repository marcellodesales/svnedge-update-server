#!/bin/sh
#
# Cron job that cleans up dev update server repos, taking care of
# daemon stop/start.
#
# Added to run weekly on cu025:
#
# 12 0 * * 0 /opt/update-server/cleanup-repo-cron.sh > /dev/null 2>&1
#

if [ "root" != "$USER" ]; then
    echo "Must be run as 'root' user.  sudo is your friend."
    exit
fi

/sbin/service httpd stop

/sbin/runuser updator /opt/update-server/recreate-repos.sh

/sbin/service update-server restart

/sbin/service httpd start
