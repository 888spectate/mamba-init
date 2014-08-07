#!/bin/sh
# Robert Oliveira <olivecoder@gmail.com>
# run as sudo


SCRIPTSDIR=$(dirname $(readlink -e $0))
INIT_DIR=${0%/*}
replace_app_user() {
    sed -i "/RUN_AS=/d" $SCRIPTSDIR/default;
    echo "RUN_AS=$USER" >> $SCRIPTSDIR/default;
}	
multiple_mamba_app() {
	for i in `ls $DIR/*/config/application.json`; do
		APPDIR=${i%/*/*} ;
		CONFIG=$APPDIR/config/application.json
		APPNAME=$(get_mamba_app_name)
   		cp $SCRIPTSDIR $APPDIR -ar
		ln -sf $APPDIR/$INIT_DIR/init.sh /home/raldea/dedsert_applications/etc/init.d/$APPNAME
		cp $APPDIR/$INIT_DIR/default /home/raldea/dedsert_applications/etc/default/$APPNAME
	 done
exit 0
}
different_mamba_dir() {
   if [ -d "$DIR" ]; then 
	CONFIG=$DIR/config/application.json
	APPNAME=$(get_mamba_app_name)
   	cp $SCRIPTSDIR $DIR -ar
	ln -sf $DIR/$INIT_DIR/init.sh /home/raldea/dedsert_applications/etc/init.d/$APPNAME
	cp $DIR/$INIT_DIR/default /home/raldea/dedsert_applications/etc/default/$APPNAME
  fi
exit 0                                                                              
}


get_mamba_app_name() {
    cat $CONFIG |
    python -c "import json, sys; print json.load(sys.stdin)['name']"
}
simple_install() {
	CONFIG=$SCRIPTSDIR/../config/application.json
	APPNAME=$(get_mamba_app_name)
	ln -sf $SCRIPTSDIR/init.sh /home/raldea/dedsert_applications/etc/init.d/$APPNAME
	cp $SCRIPTSDIR/default /home/raldea/dedsert_applications/etc/default/$APPNAME
}

rm -rf $SCRIPTSDIR/.git
if [ -z "$*" ]; then
$(simple_install)
fi
while getopts u:m:d: option; do
 case "${option}" in
	 u)
	 USER=${OPTARG}
	 $(replace_app_user)
	 ;;
	 m)
	 DIR=${OPTARG}
	 $(multiple_mamba_app)
	 ;;
	 d)
	 DIR=${OPTARG}
	 $(different_mamba_dir)
	 ;;
	 *)
	 $(simple_install)
	 ;;
  esac
 done
shift $((OPTIND-1))
