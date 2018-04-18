#!/bin/sh

# Prerequsites:
# 1. Each node should have 2 hdd, by default the script uses /dev/sdb.
# 2. The deploy node(mine is macOS) should be able to ssh to each node without password.

# Configure 3 NODEs with their hostnames
NODE1=   # ceph_01
NODE2=   # ceph_02
NODE3=   # ceph_03

# Use your monitor(NODE1)'s IP range
PUBLIC_NETWORK=   # 172.16.219.0/24

mkdir ceph-cluster
cd ceph-cluster
ceph-deploy new $NODE1

echo "public network = $PUBLIC_NETWORK" >> ceph.conf

export CEPH_DEPLOY_REPO_URL=http://mirrors.163.com/ceph/debian-luminous
export CEPH_DEPLOY_GPG_URL=http://mirrors.163.com/ceph/keys/release.asc

ceph-deploy install $NODE1 $NODE2 $NODE3
ceph-deploy mon create-initial
ceph-deploy admin $NODE1 $NODE2 $NODE3

ceph-deploy mgr create $NODE1

# create OSD disk
ceph-deploy osd create $NODE1:/dev/sdb
ceph-deploy osd create $NODE2:/dev/sdb
ceph-deploy osd create $NODE3:/dev/sdb

# Expand cluster

# Add a metadata server
ceph-deploy mds create $NODE1

# Add monitors
ceph-deploy mon add $NODE2
ceph-deploy mon add $NODE3

# Add managers
ceph-deploy mgr create $NODE2 $NODE3

# Add an rgw instance
ceph-deploy rgw create $NODE1
