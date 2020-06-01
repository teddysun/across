## Trojan-Go Docker Image by Teddysun

[Trojan-Go][1] is An unidentifiable mechanism that helps you bypass [GFW](https://en.wikipedia.org/wiki/Great_Firewall).

Trojan-Go features multiple protocols over `TLS` to avoid both active/passive detections and ISP `QoS` limitations.

Docker images are built for quick deployment in various computing cloud providers.

For more information on docker and containerization technologies, refer to [official document][2].

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][3].

## Pull the image

```bash
$ docker pull teddysun/trojan-go
```

This pulls the latest release of trojan-go.

It can be found at [Docker Hub][4].

## Start a container

You **must create a configuration file**  `/etc/trojan-go/config.json` in host at first:

```
$ mkdir -p /etc/trojan-go
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
        "your_awesome_password"
    ],
    "ssl": {
        "cert": "server.crt",
        "key": "server.key",
        "sni": "your-domain-name.com",
        "fallback_port": 1234
    }
}
```

An online documentation can be found [here](https://p4gefau1t.github.io/trojan-go/)

There is an example to start a container that use host network, run as a trojan-go server like below:

```bash
$ docker run -d --network host --name trojan-go --restart=always -v /etc/trojan-go:/etc/trojan-go teddysun/trojan-go
```

[1]: https://github.com/p4gefau1t/trojan-go
[2]: https://docs.docker.com/
[3]: https://docs.docker.com/install/
[4]: https://hub.docker.com/r/teddysun/trojan-go/