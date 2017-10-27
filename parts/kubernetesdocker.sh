#!/usr/bin/env bash

repo="$@"

retrycmd_if_failure() {
	for i in 1 2 3 4 5; do
		$@;
		[ $? -eq 0  ] && break || sleep 5;
	done
}

apt-mark hold walinuxagent
retrycmd_if_failure apt-get update
retrycmd_if_failure apt-get install -y apt-transport-https ca-certificates nfs-common

retrycmd_if_failure curl --max-time 60 -fsSL https://aptdocker.azureedge.net/gpg | apt-key add -

echo "deb ${repo} ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list
echo -e "Package: docker-engine\nPin: version {{WrapAsVariable "dockerEngineVersion"}}\nPin-Priority: 550\n" > /etc/apt/preferences.d/docker.pref

retrycmd_if_failure apt-get update
retrycmd_if_failure apt-get install -y ebtables
retrycmd_if_failure apt-get install -y docker-engine

systemctl restart docker

/usr/lib/apt/apt.systemd.daily

apt-mark unhold walinuxagent
