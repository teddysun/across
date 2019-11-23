## L2TP/IPsec VPN Server Docker Image by Teddysun

Docker image to run a L2TP/IPsec VPN Server, with both `L2TP/IPsec PSK` and `IPSec Xauth PSK`.

Based on Alpine with [libreswan-3.29 (IPsec VPN software)](https://pkgs.alpinelinux.org/package/edge/community/x86_64/libreswan) and [xl2tpd-1.3.15 (L2TP daemon)](https://pkgs.alpinelinux.org/package/edge/main/x86_64/xl2tpd).

Docker images are built for quick deployment in various computing cloud providers.

For more information on docker and containerization technologies, refer to [official document][1].

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][2].

## Pull the image

```bash
$ docker pull teddysun/l2tp
```

This pulls the latest release of L2TP/IPsec VPN Server.
It can be found at [Docker Hub][3].

## Start a container

You **must create a environment file**  `/etc/l2tp.env` in host at first, and sample value is below:

```
VPN_IPSEC_PSK=teddysun.com
VPN_USER=vpnuser
VPN_PASSWORD=vpnpassword
VPN_PUBLIC_IP=
VPN_L2TP_NET=
VPN_L2TP_LOCAL=
VPN_L2TP_REMOTE=
VPN_XAUTH_NET=
VPN_XAUTH_REMOTE=
VPN_DNS1=
VPN_DNS2=
VPN_SHA2_TRUNCBUG=
```

This will create a default user account for L2TP/IPsec VPN login, which can be used by your **multiple devices**.

The IPSec PSK (pre-shared key) is specified by the `VPN_IPSEC_PSK`. 

The **default username** is specified in `VPN_USER`.

The **default password** is specified in `VPN_PASSWORD`.

If your VPS has multiple public IP addresses, maybe public IP need to specified in `VPN_PUBLIC_IP`.

If you want to specify a other private network, maybe need to specified in `VPN_L2TP_NET` (default `192.168.18.0/24`).

If you want to specify a other private network, maybe need to specified in `VPN_XAUTH_NET` (default `192.168.20.0/24`).

If you want to specify a `local ip` for `xl2tpd.conf`, maybe need to specified in `VPN_L2TP_LOCAL` (default `192.168.18.1`).

If you want to specify a `ip range` for `xl2tpd.conf`, maybe need to specified in `VPN_L2TP_REMOTE` (default `192.168.18.10-192.168.18.250`).

If you want to specify a `rightaddresspool` for `ipsec.conf`, maybe need to specified in `VPN_XAUTH_REMOTE` (default `192.168.20.10-192.168.20.250`).

If you want to specify a other DNS servers, maybe need to specified in `VPN_DNS1` and `VPN_DNS2` (default `8.8.8.8`, `8.8.4.4`).

**Android 6 and 7 users**: If you encounter connection issues, you may set `sha2-truncbug=yes` (default is no) in `/etc/ipsec.conf` by adding `VPN_SHA2_TRUNCBUG=yes` to `/etc/l2tp.env` file, then re-create the Docker container.

There is an example to start a container:

```bash
$ docker run -d --privileged -p 500:500/udp -p 4500:4500/udp --name l2tp --restart=always --env-file /etc/l2tp.env -v /lib/modules:/lib/modules teddysun/l2tp
```

**Warning**: The UDP port number `500` and `4500` must be opened in firewall.

## Check container details

If you want to view the container logs:

```bash
$ docker logs l2tp
```

Output log like below:

```
L2TP/IPsec VPN Server with the Username and Password is below:

Server IP: Your Server public IP
IPSec PSK: IPSec PSK (pre-shared key)
Username : VPN username
Password : VPN password

Redirecting to: /etc/init.d/ipsec start
Starting pluto IKE daemon for IPsec: Initializing NSS database

xl2tpd[1]: Not looking for kernel SAref support.
xl2tpd[1]: Using l2tp kernel support.
xl2tpd[1]: xl2tpd version xl2tpd-1.3.15 started on 1d20eaecd9f2 PID:1
xl2tpd[1]: Written by Mark Spencer, Copyright (C) 1998, Adtran, Inc.
xl2tpd[1]: Forked by Scott Balmos and David Stipp, (C) 2001
xl2tpd[1]: Inherited by Jeff McAdams, (C) 2002
xl2tpd[1]: Forked again by Xelerance (www.xelerance.com) (C) 2006-2016
xl2tpd[1]: Listening on IP address 0.0.0.0, port 1701
```

To check the status of your L2TP/IPSec VPN server, you can confirm `ipsec status` to your container like below:

```bash
$ docker exec -it l2tp ipsec status
```

## Manage VPN Users

If you want to add, modify or remove user accounts, please do it simple like below:

### List all users

```bash
$ docker exec -it l2tp l2tpctl -l
```

### Add a user

```bash
$ docker exec -it l2tp l2tpctl -a
```

### Delete a user

```bash
$ docker exec -it l2tp l2tpctl -d
```

### Modify a user password

```bash
$ docker exec -it l2tp l2tpctl -m
```

### Print Libreswan & xl2tpd version

```bash
$ docker exec -it l2tp l2tpctl -v
```

### Print help information

```bash
$ docker exec -it l2tp l2tpctl -h
```


[1]: https://docs.docker.com/
[2]: https://docs.docker.com/install/
[3]: https://hub.docker.com/r/teddysun/l2tp/