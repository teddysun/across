## Brook Docker Image by Teddysun

[Brook][1] is a cross-platform proxy/VPN software which can help you get through firewalls.

Docker images are built for quick deployment in various computing cloud providers.

For more information on docker and containerization technologies, refer to [official document][2].

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][3].

## Pull the image

```bash
$ docker pull teddysun/brook
```

This pulls the latest release of Brook.

It can be found at [Docker Hub][4].

## Start a container

You **must set environment variable** `ARGS` at first.

There is an example to start a container that listen on port `9000`, password is `password0` (both TCP and UDP) run as a brook server like below:

```bash
$ docker run -d -p 9000:9000 -p 9000:9000/udp --name brook --restart=always -e "ARGS=server -l :9000 -p password0" teddysun/brook
```

**Warning**: The port number must be same as environment variable and opened in firewall.

[1]: https://github.com/txthinking/brook
[2]: https://docs.docker.com/
[3]: https://docs.docker.com/install/
[4]: https://hub.docker.com/r/teddysun/brook/