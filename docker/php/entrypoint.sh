#!/bin/bash
set -e

uid=$(stat -c %u /home/app)
gid=$(stat -c %g /home/app)

if [ $uid == 0 ] && [ $gid == 0 ]; then
    chmod 777 -Rf /home
else
    # Change www-data's uid & guid to be the same as directory in host
    sed -ie "s/`id -u www-data`:`id -g www-data`/$uid:$gid/g" /etc/passwd

    mkdir -p /var/log/php && chown -Rf $uid:$gid /var/log/php
    chown -Rf $uid:$gid /home
fi

if [ $# -eq 0 ]; then
    php-fpm
else
    exec gosu $user "$@"
fi