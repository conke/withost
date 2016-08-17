#!/bin/sh

while [ $# -gt 0 ]
do
	case $1 in
	-e|--env)
		env=$2
		shift
		;;
	-j|--jdk)
		jdk=$2
		shift
		;;
	-n|--nodes)
		nodes=$2
		shift
		;;
#	-p|--ppm-path)
#		ppm_path=$2
#		shift
#		;;
	-s|--server)
		server=$2
		shift
		;;
	*)
		echo -e "Invalid option '$1'\n"
		exit 1
		;;
	esac

	shift
done

dir=`dirname $0`

# FIXME
for j in `ls */target/*.jar`
do
	if [ -x $j ]; then
		jar=$j
		break
	fi
done

if [ -z "$jar" ]; then
	echo "No executable jar found!"
	exit 1
fi

if [ ! -e $dir/nginx-local.sh ]; then
	echo "Invalid server '$server'!"
	exit 1
fi

index=1

while [ $index -le $nodes ]
do
	case $env in
	local)
		url="localhost"
		;;
	production)
		url="$server$index.2dupay.com"
		;;
	*)
		url="$server$index.$env.2dupay.com"
		;;
	esac

	echo "deploying $url ..."

	dst=`ssh $url mktemp -d`

	if [ -n "$jdk" ]; then
		scp $jdk $url:$dst
		# FIXME
		scp $dir/../witjee/jdk/install-jdk.sh $url:$dst
		ssh $url sudo $dst/install-jdk.sh $dst/`basename $jdk`
	fi

	scp $jar $url:$dst
	scp $dir/node-local.sh $url:$dst/
	ssh $url sudo $dst/node-local.sh --server $server --jar $dst/`basename $jar` --env $env

	ssh $url rm -rf $dst

	((index++))

	echo
done