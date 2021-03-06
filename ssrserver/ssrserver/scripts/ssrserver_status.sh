#!/bin/sh

alias echo_date1='echo $(date +%Y年%m月%d日\ %X)'
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
date=`echo_date1`

ssrserver_status=`ps|grep server.py|grep -v grep`

if [ -n "$ssrserver_status" ];then
	http_response "【$date】 ShadowsocksR服务器运行正常"
else
	http_response "<font color='#FF0000'>【警告】 服务器未运行！</font>"
fi
