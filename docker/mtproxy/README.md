## MTProxy Docker Image by Teddysun

The [Telegram Messenger MTProto proxy][1] is a zero-configuration container that automatically sets up a proxy server that speaks Telegram's native MTProto.

This Docker Image Based on the work of [alexdoesh](https://github.com/alexdoesh/mtproxy)

Docker images are built for quick deployment in various computing cloud providers.

For more information on docker and containerization technologies, refer to [official document][2].

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][3].

## Pull the image

```bash
$ docker pull teddysun/mtproxy
```

This pulls the latest release of MTProxy.

It can be found at [Docker Hub][4].

## Start a container

You **must create a directory**  `/etc/mtproxy` in host at first:

```
$ mkdir -p /etc/mtproxy
```

To start the proxy all you need to do is below:

`docker run -d -p443:443 --name=mtproxy --restart=always -v /etc/mtproxy:/data teddysun/mtproxy`

The container's log output (`docker logs mtproxy`) will contain the links to paste into the Telegram app:

```
[+] Using the explicitly passed secret: '00baadf00d15abad1deaa515baadcafe'.
[+] Saving it to /data/secret.
[*] Final configuration:
[*]   Secret 1: 00baadf00d15abad1deaa515baadcafe
[*]   tg:// link for secret 1 auto configuration: : tg://proxy?server=3.14.15.92&port=443&secret=00baadf00d15abad1deaa515baadcafe
[*]   t.me link for secret 1: tg://proxy?server=3.14.15.92&port=443&secret=00baadf00d15abad1deaa515baadcafe
[*]   Tag: no tag
[*]   External IP: 3.14.15.92
[*]   Make sure to fix the links in case you run the proxy on a different port.
```

**Warning**: The port number `443` must be opened in firewall.

The secret will persist across container upgrades in a volume.

It is a mandatory configuration parameter: if not provided, it will be generated automatically at container start. 

You may forward any other port to the container's 443: be sure to fix the automatic configuration links if you do so.

Please note that the proxy gets the Telegram core IP addresses at the start of the container. We try to keep the changes to a minimum, but you should restart the container about once a day, just in case.

## Registering your proxy

Once your MTProxy server is up and running go to [@MTProxybot](https://t.me/mtproxybot) and register your proxy with Telegram to gain access to usage statistics and monetization.

## Custom configuration

If you need to specify a custom secret (say, if you are deploying multiple proxies with DNS load-balancing), you may pass the SECRET environment variable as 16 bytes in lower-case hexidecimals:

`docker run -d -p443:443 -v /etc/mtproxy:/data -e SECRET=00baadf00d15abad1deaa51sbaadcafe teddysun/mtproxy`

## Monitoring

The MTProto proxy server exports internal statistics as tab-separated values over the http://localhost:2398/stats endpoint.

Please note that this endpoint is available only from localhost: depending on your configuration, you may need to collect the statistics with `docker exec mtproxy curl http://localhost:2398/stats`.

* `ready_targets`: number of Telegram core servers the proxy will try to connect to.
* `active_targets`: number of Telegram core servers the proxy is actually connected to. Should be equal to ready_targets.
* `total_special_connections`: number of inbound client connections
* `total_max_special_connections`: the upper limit on inbound connections. Is equal to 60000 multiplied by worker count.

[1]: https://github.com/TelegramMessenger/MTProxy
[2]: https://docs.docker.com/
[3]: https://docs.docker.com/install/
[4]: https://hub.docker.com/r/teddysun/mtproxy/