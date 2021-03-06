#!/bin/sh
export KSROOT=/koolshare
source /koolshare/scripts/base.sh
alias echo_date='echo $(date +%Y年%m月%d日\ %X)'
eval `dbus export bbr_`
fwlocal=`cat /etc/openwrt_release|grep DISTRIB_RELEASE|cut -d "'" -f 2|cut -d "V" -f 2`
checkversion=`versioncmp $fwlocal 2.18`

set_conn(){
  local localconn=`sysctl -n net.netfilter.nf_conntrack_max`
  [ "$localconn" != "$bbr_conn" ] && {
    sed -i '/net\.netfilter\.nf_conntrack_max/d' /etc/sysctl.conf
    echo "net.netfilter.nf_conntrack_max=$bbr_conn" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
	}
}

set_mode() {
	case "$1" in
		*bbr*)
			modprobe $1
			echo "$1" > /etc/modules.d/bbr
			echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
			echo "net.ipv4.tcp_congestion_control=$1" >> /etc/sysctl.conf
		;;
		*)
			echo "net.ipv4.tcp_congestion_control=$1" >> /etc/sysctl.conf
		;;
	esac
}

start_bbr(){
  local localmode=`sysctl -n net.ipv4.tcp_congestion_control`
  [ "$localmode" != " $bbr_mode" ] && {
    sed -i '/net\.ipv4\.tcp_congestion_control/d' /etc/sysctl.conf
    sed -i '/net\.core\.default_qdisc=fq/d' /etc/sysctl.conf
    $(set_mode $bbr_mode)
    sysctl -w net.ipv4.tcp_congestion_control=$bbr_mode >/dev/null 2>&1
    sysctl -p >/dev/null 2>&1
  }
}

rm_old_mod(){
    if [ "$bbr_mode" == "bbr" ]; then
        local bbrmode=`lsmod |grep bbr | grep -vw tcp_bbr | cut -d " " -f1`
    else    
        local bbrmode=`lsmod |grep bbr | grep -vw $bbr_mode | cut -d " " -f1`
    fi
    [ -n "$bbrmode" ] && {
      for bbrmode1 in $bbrmode
      do
        rmmod $bbrmode1
        echo 删除$bbrmode1
      done
    }
}

set_conn
[ "$checkversion" == "1" ] || start_bbr
rm_old_mod
http_response '服务已开启！页面将在3秒后刷新'
