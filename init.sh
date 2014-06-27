#!/bin/sh
# Robert Oliveira <olivecoder@gmail.com>

### BEGIN INIT INFO
# Provides:          mamba-application
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start a mamba application at boot time
# Description:       Active the virtualenv and start the application located
#                    in the same directory structure as the init script.
### END INIT INFO

get_mamba_app_name() {
    cat $CONFIG |
    python -c "import json, sys; print json.load(sys.stdin)['name']"
}

RUN_AS=ec2-user
WORKDIR=$(dirname $(dirname $(readlink -e $0)))
PIDFILE=$WORKDIR/twistd.pid
CONFIG=$WORKDIR/config/application.json
APPNAME=$(get_mamba_app_name)
CMD=mamba-admin

. /etc/default/$APPNAME

log_action_msg() {
    echo $*
}

[ -f /etc/init.d/functions ] && . /etc/init.d/functions
[ -f /lib/lsb/init-functions ] && . /lib/lsb/init-functions


get_virtualenv() {
    find $WORKDIR -name "*env" -type d -exec \
        find {}/bin -name activate \;
}

user_shell() {
    if [ $(id -u) -eq 0 ]; then
        su $RUN_AS -c sh
    else
        sh
    fi
}

mamba_admin_exec() {
    user_shell << EOF
        cd $WORKDIR
        . $(get_virtualenv)
        $CMD $*
EOF
}

do_start() {
    mamba_admin_exec start
}

do_stop() {
    mamba_admin_exec stop
    [ -f "$PIDFILE" ] && rm $PIDFILE
}

case "$1" in
    start)
        log_action_msg "Starting $NAME"
        do_start
        ;;
    stop)
        log_action_msg "Stopping $NAME"
        do_stop
        ;;
    restart)
        log_action_msg "Restarting $NAME"
        do_stop
        do_start
        ;;
    *)
        log_action_msg "Usage: %0 {start|stop|restart}"
        exit 2
        ;;
esac

exit 0
