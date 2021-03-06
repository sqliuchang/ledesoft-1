#!/bin/sh

alias echo_date='echo $(date +%Y年%m月%d日\ %X)'
export KSROOT=/koolshare
source /koolshare/scripts/base.sh
eval `dbus export netdata_`
logfile="/tmp/upload/netdata_log.txt"
lockfile="/tmp/netdata.locker"
echo "" > $logfile

sleep 1

update_opkg(){
	[ ! -f "/tmp/opkg-lists/koolshare_x64_base" -o ! -f "/tmp/opkg-lists/koolshare_x64_core" -o ! -f "/tmp/opkg-lists/koolshare_x64_packages"  ] && {
		echo_date "获取支持环境最新版本信息"
		opkg update >/dev/null 2>&1
		if [ "$?" -eq 0 ] ; then
			echo_date "最新版本信息已成功获取，准备下载安装"
		else
			echo_date "获取最新版本信息失败，你的网络可能有问题，请重试！"
			rm -rf $lockfile
			echo XU6J03M6 >> $logfile
			exit 0
		fi
	}
}

check_opkg(){
	echo_date "开始检测固件内路由监控支持环境"
	echo_date "====================================================="
	local hbipk ipknum
	ipknum="1"
	hbipk="netdata"
	for hbipk in $hbipk
	do
		local ipkinstall=$(opkg list-installed | grep "$hbipk")
		if [ -z "$ipkinstall" ]; then
			update_opkg
			echo_date "安装支持环境-$ipknum"
			opkg install $hbipk >/dev/null 2>&1
			if [ "$?" -eq 0 ] ; then
				echo_date "支持环境-$ipknum已安装，检测通过"
			else
				echo_date "安装支持环境-$ipknum失败，你的网络可能有问题，请重试！"
				rm -rf $lockfile
				echo XU6J03M6 >> $logfile
				exit 0
			fi
		else
			echo_date "支持环境-$ipknum已安装，检测通过"		
		fi
	ipknum=`expr $ipknum + 1`
	done
}

gen_config(){
	sed -i "/default port/c        default port =  $netdata_port" /etc/netdata/netdata.conf
}

open_port(){
	local IPT="iptables -I"
	$IPT zone_wan_input 2 -p tcp -m tcp --dport $netdata_port -m comment --comment "!softcenter: netdata" -j ACCEPT
}

close_port(){
	local IPD="iptables -D"
	$IPD zone_wan_input -p tcp -m tcp --dport $netdata_port -m comment --comment "!softcenter: netdata" -j ACCEPT >/dev/null 2>&1
}

start_netdata(){
	echo_date "设置配置文件"
	gen_config
	echo_date "开始运行路由监控服务"
	/etc/init.d/netdata enable 2>&1
	/etc/init.d/netdata start 2>&1
	[ "$netdata_wan" == "1" ] && {
		echo_date "打开防火墙端口"
		open_port >/dev/null 2>&1
	}
	echo_date "============================================"
	echo_date "all done enjoy！"
}

stop_netdata(){
	echo_date "============================================"
	echo_date "             Koolshare LEDE X64 软件中心 路由监控    "
	echo_date "============================================"
	echo_date "关闭已经运行的组件"
	/etc/init.d/netdata  disable >/dev/null 2>&1
	/etc/init.d/netdata  stop >/dev/null 2>&1
	close_port
	echo_date ""
}

creat_start_up(){
	[ ! -L "/etc/rc.d/S99netdata.sh" ] && ln -sf /koolshare/init.d/S99netdata.sh /etc/rc.d/S99netdata.sh
}

if [ "$netdata_enable" == "1" ]; then
	if [ -f "/tmp/netdata.locker" ];then
		#前正在进行更新，点击按钮会给用户切换到日志界面继续观察日志
		exit 0
	else
		touch $lockfile
		# wait for httpdb to read
		sleep 1
		# begain to update
		stop_netdata >> $logfile 2>&1
		check_opkg >> $logfile 2>&1
		start_netdata >> $logfile 2>&1
		creat_start_up
		echo XU6J03M6 >> $logfile
		rm -rf $lockfile
	fi
else
	stop_netdata >> $logfile
	echo XU6J03M6 >> $logfile
	http_response '服务已关闭！页面将在3秒后刷新'
	rm -rf $lockfile
fi
