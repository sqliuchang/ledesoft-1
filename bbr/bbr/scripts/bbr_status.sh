#!/bin/sh

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh

bbrmode=`sysctl -n net.ipv4.tcp_congestion_control`
fwlocal=`cat /etc/openwrt_release|grep DISTRIB_RELEASE|cut -d "'" -f 2|cut -d "V" -f 2`
checkversion=`versioncmp $fwlocal 2.18`

get_mode_name() {
	case "$1" in
		cubic)
			echo "默认cubic"
		;;
		bbr)
			echo "原版bbr"
		;;
		tcp_bbr_mod)
			echo "魔改bbr"
		;;
		tcp_bbr_nql)
			echo "魔改bbr→南琴浪版"
		;;
		tcp_bbr_tsunami)
			echo "魔改bbr→Yankee版"
		;;
		bbrplus)
			echo "进阶版BBR→Plus"
		;;
		*)
			echo "$1"
		;;
	esac
}

[ "$checkversion" == "1" ] && {
	http_response "<font color='#ff5500'>仅支持2.18及以后的版本调整TCP BBR拥塞控制算法，当前版本仅能配置连接数！</font>"
	exit 0
}

http_response "当前TCP拥塞控制算法【$(get_mode_name $bbrmode)】"
