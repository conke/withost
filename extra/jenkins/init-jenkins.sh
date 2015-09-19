#!/bin/sh

if [ $USER != 'jenkins' ]; then
	echo "must run as jenkins!"
	exit 1
fi

cd /var/lib/jenkins || exit 1

if [ ! -e .ssh/id_rsa ]; then
	if [ ! -d .ssh ]; then
		mkdir .ssh
		chmod 700 .ssh
	fi
	ssh-keygen -P '' -f .ssh/id_rsa || exit 1
	echo
fi

pid=`jps | awk '$2 == "jenkins.war" {print $1}'`
if [ -z "$pid" ]; then
	echo "Jenkins is not running!"
	exit 1
fi

info="Waiting for Jenkins ready ..."
echo $info
count=1
while [ "$info" != "INFO: Jenkins is fully up and running" ]
do
	curr=`grep ^INFO /var/log/jenkins/jenkins.log | tail -n 1`
	if [ "$info" != "$curr" ]; then
		info="$curr"
		echo $info
	fi

	((count++))
	if [ $count -eq 60 ]; then
		echo "Jenkins service timeount!"
		exit 1
	fi

	sleep 1
done
echo

# FIXME
port=8580

plugins=(git gitlab-plugin python perl)

len=${#plugins[@]}
max=$((len*2))
try=1
cur=0
loop=1

while [ ${#plugins[@]} -gt 0 -a $try -le $max ]
do
	plugin=${plugins[$cur]}
	echo "[$try/$max][$loop.$((cur+1))] installing $plugin ... "
	java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar \
		-s http://localhost:$port/ install-plugin $plugin
	if [ $? -eq 0 ]; then
		unset plugins[$cur]
	else
		((cur++))
	fi

	if [ $cur -ge ${#plugins[@]} ]; then
		cur=0
		((loop++))
	fi

	((try++))
	echo

	sleep 1
done

if [ ${#plugins[@]} -eq $len ]; then
	exit 1
elif [ ${#plugins[@]} -gt 0 ]; then
	echo "plugins failed to be installed: ${plugins[@]}"
else
	echo "all plugins installed successfully!"
fi

echo
