## Caddy Docker Image by Teddysun

[Caddy][1] is a powerful, enterprise-ready, open source web server with automatic HTTPS written in Go.

Docker images are built for quick deployment in various computing cloud providers.

For more information on docker and containerization technologies, refer to [official document][2].

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][3].

## Pull the image

```bash
$ docker pull teddysun/caddy
```

This pulls the version **v1.0.5** of Caddy.

It can be found at [Docker Hub][4].

## Start a container

You **must create a configuration file**  `/etc/caddy/Caddyfile` in host at first:

```
$ mkdir -p /etc/caddy
```

Mount your site root using the `www` volume, a sample `Caddyfile` like below:

```
:80 {
  root /www
  index index.html
}
```

There is an example to override the default `Caddyfile`, you can mount a new one at `/etc/caddy/Caddyfile` like below:

```bash
$ docker run -d -p 80:80 --name caddy --restart=always -v /etc/caddy:/etc/caddy -v $(pwd)/site:/www teddysun/caddy
```

[1]: https://caddyserver.com/
[2]: https://docs.docker.com/
[3]: https://docs.docker.com/install/
[4]: https://hub.docker.com/r/teddysun/caddy/