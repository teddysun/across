## Trojan Docker Image by Teddysun

[Trojan][1] is An unidentifiable mechanism that helps you bypass [GFW](https://en.wikipedia.org/wiki/Great_Firewall).

Trojan features multiple protocols over `TLS` to avoid both active/passive detections and ISP `QoS` limitations.

Docker images are built for quick deployment in various computing cloud providers.

For more information on docker and containerization technologies, refer to [official document][2].

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][3].

## Pull the image

```bash
$ docker pull teddysun/trojan
```

This pulls the latest release of Trojan.

It can be found at [Docker Hub][4].

## Start a container

You **must create a configuration file**  `/etc/trojan/config.json` in host at first:

```
$ mkdir -p /etc/trojan
```

A sample in JSON like below:

```
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "password1",
        "password2"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/path/to/certificate.crt",
        "key": "/path/to/private.key",
        "key_password": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "prefer_ipv4": false,
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
```

An online documentation can be found [here](https://trojan-gfw.github.io/trojan/)

There is an example to start a container that listen on port `443`, run as a Trojan server like below:

```bash
$ docker run -d -p 443:443 --name trojan --restart=always -v /etc/trojan:/etc/trojan teddysun/trojan
```

**Warning**: The port number `443` must be same as configuration and opened in firewall.

[1]: https://github.com/trojan-gfw/trojan
[2]: https://docs.docker.com/
[3]: https://docs.docker.com/install/
[4]: https://hub.docker.com/r/teddysun/trojan/