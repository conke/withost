#!/usr/bin/env bash

if [ ! -d /opt/openstack-ansible ]; then
    git clone https://git.openstack.org/openstack/openstack-ansible \
        /opt/openstack-ansible || exit 1
fi

cd /opt/openstack-ansible && \
git checkout stable/queens || exit 1

sed -i '/PasswordAuthentication/d' tests/bootstrap-aio.yml

# # FIXME
# disks=(`fdisk -l | grep '^Disk /dev' | awk '{print $2}'`)
# rootd=`awk '$2=="/" {print $1}' /proc/mounts`
#
# if [ ${#disks[@]} -gt 1 ]; then
# 	for disk in ${disks[@]/:/}; do
# 		if [ ${rootd#$disk} == $rootd ]; then
# 			export BOOTSTRAP_OPTS="bootstrap_host_data_disk_device=${disk/\/dev\//}"
# 			break
# 		fi
# 	done
# fi
#
# echo "BOOTSTRAP_OPTS = $BOOTSTRAP_OPTS"

mkdir -vp ~/.pip
cat > ~/.pip/pip.conf << _EOF_
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/
[install]
trusted-host = mirrors.aliyun.com
_EOF_

export BOOTSTRAP_OPTS="bootstrap_host_ubuntu_repo=http://mirrors.aliyun.com/ubuntu/"
# export ANSIBLE_ROLE_FETCH_MODE='galaxy'

scripts/bootstrap-ansible.sh || exit 1

sed -i '/^lxc_image_cache_server_mirrors:/a \ \ - https://mirrors.tuna.tsinghua.edu.cn/lxc-images' \
    /etc/ansible/roles/lxc_hosts/defaults/main.yml || exit 1

sed -i 's/retries: 60/retries: 600/' \
    /etc/ansible/roles/lxc_hosts/tasks/lxc_cache_preparation_systemd_new.yml || exit 1

sed -i 's/async: 300/async: 3000/' \
    /etc/ansible/roles/lxc_hosts/tasks/lxc_cache_prestage.yml || exit 1

# mkdir -vp /etc/openstack_deploy/conf.d/
# cp -v etc/openstack_deploy/conf.d/ceph.yml.aio /etc/openstack_deploy/conf.d/ceph.yml
# export SCENARIO='ceph'
scripts/bootstrap-aio.sh || exit 1

cd /opt/openstack-ansible/playbooks || exit 1

retries=3
for y in hosts infrastructure openstack; do
	i=0
	while [ $i -lt $retries ]; do
		echo "openstack-ansible setup-$y.yml ($i/$retries)"
		openstack-ansible setup-$y.yml && break
		((i++))
	done
	[ $i -eq $retries ] && exit 1
done

# openstack-ansible -e galera_ignore_cluster_state=true galera-install.yml || exit 1
