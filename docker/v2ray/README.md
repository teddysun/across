## V2Ray Docker Image by Teddysun

[V2Ray][1] is a platform for building proxies to bypass network restrictions.

It secures your network connections and thus protects your privacy.

Docker images are built for quick deployment in various computing cloud providers.

For more information on docker and containerization technologies, refer to [official document][2].

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][3].

## Pull the image

```bash
$ docker pull teddysun/v2ray
```

This pulls the latest release of V2Ray.

It can be found at [Docker Hub][4].

## Start a container

You **must create a configuration file**  `/etc/v2ray/config.json` in host at first:

```
$ mkdir -p /etc/v2ray
```

A sample in JSON like below:

```
{
  "inbounds": [{
    "port": 9000,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "11c2a696-0366-4524-b8f0-9a9c21512b02",
          "level": 1,
          "alterId": 64
        }
      ]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }]
}
```

Or generate a configuration file online by [https://tools.sprov.xyz/v2ray/](https://tools.sprov.xyz/v2ray/)

There is an example to start a container that listen on port `9000`, run as a V2Ray server like below:

```bash
$ docker run -d -p 9000:9000 --name v2ray --restart=always -v /etc/v2ray:/etc/v2ray teddysun/v2ray
```

**Warning**: The port number must be same as configuration and opened in firewall.

[1]: https://github.com/v2fly/v2ray-core
[2]: https://docs.docker.com/
[3]: https://docs.docker.com/install/
[4]: https://hub.docker.com/r/teddysun/v2ray/