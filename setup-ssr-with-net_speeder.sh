#!/bin/bash
set -e

echo "输入端口号" && read port
echo "输入密码" && read passwd
echo "输入容器名" && read name

method=('aes-128-ctr' 'aes-192-ctr' 'aes-256-ctr' 'aes-128-cfb' 'aes-192-cfb' 'aes-256-cfb' 'bf-cfb' 'camellia-128-cfb' 'camellia-192-cfb' 'camellia-256-cfb' 'chacha20' 'chacha20-ietf' 'rc4-md5' 'salsa20')
obfs=('plain' 'http_simple' 'http_post' 'random_head' 'tls1.2_ticketauth')
protocol=('orgin' 'auth_sha1_compatible' 'auth_sha1_v2_compatible' 'auth_sha1_v4_compatible' 'auth_aes128_md5_compatible' 'auth_aes128_sha1_compatible')
i=0
for x in ${obfs[@]};
do
	echo $i ${x}

	i=$[i+1]
done
echo "请选择混淆协议的编号"
read a
obfs=${obfs[$a]}



i=0
for x in ${protocol[@]};
do
	echo $i ${x}

	i=$[i+1]
done
echo "请选择协议的编号"
read a
protocol=${protocol[$a]}



i=0
for x in ${method[@]};
do
	echo $i ${x}

	i=$[i+1]
done
echo "method :"
read a
method=${method[$a]}

echo $obfs $protocol $method

docker run -d -p $port:$port/tcp -p $port:$port/udp \
       	-e ROOT_PASS="$passwd" \
	--name $name \
       	lnterface/ssr-with-net_speeder \
	-s 0.0.0.0 \
	-p $port \
	-k $passwd \
	-m $method \
	-o $obfs \
	-O $protocol 
docker logs -f $name
