#!/bin/bash
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

RUN_AS=dedsert
APPNAME=$(basename $0)
WORKDIR=$(dirname $(dirname $(readlink -e $0)))
PIDDIR=/var/run/$RUN_AS
PIDFILE=$PIDDIR/$APPNAME.pid
CONFIG=$WORKDIR/config/application.json
CMD=mamba-admin
OPTS="--syslog "
LOCKDIR=/var/lock/dedsert

exec > >(tee >(logger -t $APPNAME))
exec 2> >(tee >(logger -t $APPNAME -p user.err) >&2)

# imports
[ -f /etc/default/$APPNAME ] && source /etc/default/$APPNAME
# [ -f /etc/init.d/functions ] && . /etc/init.d/functions
# [ -f /lib/lsb/init-functions ] && . /lib/lsb/init-functions

die() {
    echo $@ >&2
    exit 1
}

get_virtualenv() {
    path_list="$WORKDIR $WORKDIR/.."
    activate_cmd=$(
        find -L $path_list -iname '*env' -o -iname '*environment' -type d -executable \
             -exec find {}/bin -name activate \; -quit
    )
    export VIRTUAL_ENV=$(dirname $(dirname $activate_cmd))
    [ -n $VIRTUAL_ENV ]
}

is_running() {
    [ -f $PIDFILE ] || return 1
    [ -r $PIDFILE ] || die Cannot read $PIDFILE
    ps $(cat $PIDFILE) &>/dev/null
}

create_dir() {
    sudo mkdir -p $1 || die Needs to run as SU the first time to create dirs
    sudo chown dedsert:dedsert $1 || die
    sudo chmod g+wxs $1 || die
}

init_lock() {
    [ -d $LOCKDIR ] || create_dir $LOCKDIR
    LOCK=$LOCKDIR/$APPNAME
    if ! lockfile -r 0 $LOCK &>/dev/null; then
       [ -f $LOCK ] && die Already running || die Cannot write to $LOCK
    fi
    trap "rm -f $LOCK" 0
}

run_as() {
    if (( $(id -u $RUN_AS) == $(id -u) )); then
        return 0
    else
        sudo -u $RUN_AS true ||
            die You need to be run me as the $RUN_AS user
		echo Running as the $RUN_AS user
        sudo -i -u $RUN_AS $@
        exit $?
    fi
}

do_start() {
    if is_running; then
        echo Already running
        return 0
    fi
    echo Starting...
    [ -n "$VIRTUAL_ENV" ] || get_virtualenv || die failed to get a virtualenv
    [ -d $PIDDIR ] || create_dir $PIDDIR
    uid=$(id -u $RUN_AS)
    gid=$(id -g $RUN_AS)
    opts="-d $WORKDIR --prefix=$APPNAME --pidfile=$PIDFILE \
          --syslog --prefix=$APPNAME -u $uid -g $gid $OPTS --umask 0022"
    cd $WORKDIR
    $VIRTUAL_ENV/bin/twistd $opts $APPNAME ||
        die Error: Check the application log
    sleep 3
    is_running || die Failed to start. Unknown reason.
    echo Started successfuly
    exit 0
}

do_stop() {
    if ! is_running; then
        echo Not running
        return 0
    fi
    echo Stopping...
    kill $(cat $PIDFILE) || return 1
    sleep 3
    is_running && die Failed to stop! try $0 kill
    echo Stopped successfully
    return 0
}

do_forcestop() {
    do_stop && return 0
    echo Failed to stop. Sending SIGKILL...
    kill -9 $(cat $PIDFILE) || die
    sleep 3
    is_running ||
        (echo Stopped successfully | exit 0) &&
        die Failed to kill!
}

# this should run as su at least once to create the directories below
[ -d $LOCKDIR ] || create_dir $LOCKDIR
[ -d $PIDDIR ] || create_dir $PIDDIR

# prevent mamba-admin start
if [ ! -f $WORKDIR/twistd.pid ]; then
    touch $WORKDIR/twistd.pid
    sudo chmod 000 $WORKDIR/twistd.pid
fi

# rerun itself as the RUN_AS user
id $RUN_AS &>/dev/null || die User $RUN_AS doesnt exist
run_as $0 $@

# In the end, there can be only one
init_lock

case "$1" in
    start)
        do_start
        ;;
    stop)
        do_stop
        ;;
    forcestop)
        do_forcestop
        ;;
    restart)
        do_stop
        do_start
        ;;
    *)
        die "Usage: $0 {start|stop|forcestop|restart}"
        ;;
esac

exit 0
