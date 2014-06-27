#!/bin/sh
# Robert Oliveira <olivecoder@gmail.com>
# run as sudo

get_mamba_app_name() {
    cat $CONFIG |
    python -c "import json, sys; print json.load(sys.stdin)['name']"
}

SCRIPTSDIR=$(dirname $(readlink -e $0))
CONFIG=$SCRIPTSDIR/../config/application.json
APPNAME=$(get_mamba_app_name)

ln -sf $SCRIPTSDIR/init.sh /etc/init.d/$APPNAME
cp $SCRIPTSDIR/default /etc/default/$APPNAME
