#!/bin/sh

alias echo_date='echo $(date +%Y年%m月%d日\ %X)'
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh

pidnetdata=`pidof netdata`

if [ -n "$pidnetdata" ]; then
	http_response "路由监控已运行&nbsp;&nbsp; (pid: $pidnetdata)"
else
	http_response "<font color='#FF0000'>路由监控未运行</font>"
fi
