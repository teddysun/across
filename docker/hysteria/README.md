## Hysteria Docker Image by Teddysun

[Hysteria][1] is a feature-packed proxy & relay utility optimized for lossy, unstable connections, powered by a customized QUIC protocol.

Docker images are built for quick deployment in various computing cloud providers.

For more information on docker and containerization technologies, refer to [official document][2].

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][3].

## Pull the image

```bash
$ docker pull teddysun/hysteria
```

This pulls the latest release of Hysteria.

It can be found at [Docker Hub][4].

## Start a container

You **must create a configuration file**  `/etc/hysteria/server.json` in host at first:

```
$ mkdir -p /etc/hysteria
```

A sample in JSON like below:

```
{
    "listen": ":8998",
    "cert": "/etc/hysteria/cert.crt",
    "key": "/etc/hysteria/private.key",
    "obfs": "dGVkZHlzdW4uY29tCg=="
}
```

And put the `cert.crt`, `private.key` to the `/etc/hysteria/`.

There is an example to start a container that listen on port `8998`, run as a Hysteria server like below:

```bash
$ docker run -d -p 8998:8998 --name hysteria --restart=always -v /etc/hysteria:/etc/hysteria teddysun/hysteria
```

**Warning**: The port number must be same as configuration and opened in firewall.

[1]: https://github.com/HyNetwork/hysteria
[2]: https://docs.docker.com/
[3]: https://docs.docker.com/install/
[4]: https://hub.docker.com/r/teddysun/hysteria/