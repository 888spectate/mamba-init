#!/bin/bash
# Robert Oliveira <olivecoder@gmail.com>
# run as sudo

get_mamba_app_name() {
    cat $CONFIG |
    python -c "import json, sys; print json.load(sys.stdin)['name']"
}

SCRIPTSDIR=$(dirname $(readlink -e $0))
CONFIG=$SCRIPTSDIR/../config/application.json
APPNAME=$(get_mamba_app_name)
DEFAULT=/etc/default/$APPNAME
WORKDIR=$SCRIPTSDIR/..

die() {
    echo ERROR: $@ >&2
    exit 1
}

create_dir() {
    sudo mkdir -p $1 || die Needs to run as SU the first time to create dirs
    sudo chown dedsert:dedsert $1 || die
    sudo chmod g+wxs $1 || die
}

[ "$(id -u)" == "0" ] || die Run me as root/sudo

ln -sf $SCRIPTSDIR/init.sh /etc/init.d/$APPNAME
[ -f $DEFAULT ] || (
	echo RUN_AS=dedsert | sudo tee $DEFAULT >/dev/null
	sudo chown dedsert:dedsert $DEFAULT
)

# prevents mamba-admin start/stop
OLD_PIDFILE=$WORKDIR/twistd.pid
WARNING=/var/local/USE_INIT_SCRIPT_INSTEAD
[ -f $OLD_PIDFILE ] && 
    [ ! -L $OLD_PIDFILE ] && 
        grep -q -P '^\d+$' $OLD_PIDFILE && 
           die $OLD_PIDFILE exists
echo "Use /etc/init.d/$APPNAME $@ instead." >$WARNING
chmod 444 $WARNING
ln -sf $WARNING $OLD_PIDFILE
