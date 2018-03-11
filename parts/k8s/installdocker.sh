#!/usr/bin/env bash

repo="$1"
version=$2

retrycmd_if_failure() {
	for i in 1 2 3 4 5; do
		$@;
		[ $? -eq 0  ] && break || sleep 5;
	done
}

apt_get_update() {
	for i in $(seq 1 100); do
		apt-get update 2>&1 | grep -x "[WE]:.*"; [ $? -ne 0  ] && break || sleep 1;
	done
	echo "Executed apt-get update $i times"
}

retrycmd_if_failure_no_stats() {
	retries=$1;
	wait=$2;
	shift && shift;
	for i in $(seq 1 $retries); do
		${@}; [ $? -eq 0  ] && break || sleep $wait;
	done;
}

retrycmd_if_failure 120 1 nc -zw1 aptdocker.azureedge.net 443

apt-mark hold walinuxagent

apt_get_update
retrycmd_if_failure apt-get install -y \
	apt-transport-https \
	ca-certificates \
	nfs-common

retrycmd_if_failure_no_stats 180 1 curl -fsSL https://aptdocker.azureedge.net/gpg > /tmp/aptdocker.gpg
cat /tmp/aptdocker.gpg | apt-key add -

echo "deb ${repo} ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list
echo -e "Package: docker-engine\nPin: version ${version}\nPin-Priority: 550\n" > /etc/apt/preferences.d/docker.pref

apt_get_update
retrycmd_if_failure apt-get install -y \
	ebtables \
	docker-engine

/usr/lib/apt/apt.systemd.daily

apt-mark unhold walinuxagent

touch /opt/azure/containers/dockerinstall.complete
