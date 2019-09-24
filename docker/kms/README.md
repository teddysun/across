## KMS Server Docker Image by Teddysun

This is A fully Microsoft compatible KMS server with Docker Image.

vlmcsd is a fully Microsoft compatible KMS server that provides product activation services to clients. It is meant as a drop-in replacement for a Microsoft KMS server (Windows computer with KMS key entered). It currently supports KMS protocol versions 4, 5 and 6.

vlmcsd is designed to run on POSIX compatible operating systens. It only requires a basic C library with a BSD-style sockets API and either `fork` or `pthreads`. That allows it to run on most embedded systems like routers, NASes, mobile phones, tablets, TVs, settop boxes, etc. Some efforts have been made that it also runs on Windows.

## Prepare the host

Docker images are built for quick deployment in various computing cloud providers.
For more information on docker and containerization technologies, refer to [official document][1].

If you need to install docker by yourself, follow the [official installation guide][2].

## Pull the image

```bash
$ docker pull teddysun/kms
```

This pulls the latest release of KMS Server.
It can be found at [Docker Hub][3].

## Start a container

```bash
$ docker run -d -p 1688:1688 --name kms --restart=always teddysun/kms
```

**Note**: The TCP port number `1688` must be opened in firewall.

[1]: https://docs.docker.com/
[2]: https://docs.docker.com/install/
[3]: https://hub.docker.com/r/teddysun/kms/