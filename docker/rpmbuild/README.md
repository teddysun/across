## CentOS RPM package building environment by Teddysun

This docker image can be used to build RPM packages.

For more information on docker and containerization technologies, refer to [official document][1].

## Supported tags and respective `Dockerfile` links

- `latest`, `8` [*(Dockerfile)*][2]
- `7` [*(Dockerfile)*][3]
- `6` [*(Dockerfile)*][7]

### Reference

- Supported architectures ([*more info*][4]): `amd64`, `arm64v8`

## Integration

RPMs will be built in `/home/builder/rpmbuild` folder, which should contain source archives, patches and built RPM/SRPM files.

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][5].

## User Account and Root Access

The `builder` user (UID 1000) is a member of users and wheel, and has password-less sudo as any user, any group.

## Pull the image

For CentOS 6

```bash
$ docker pull teddysun/rpmbuild:6
```

For CentOS 7

```bash
$ docker pull teddysun/rpmbuild:7
```

For CentOS 8

```bash
$ docker pull teddysun/rpmbuild:8
```

It can be found at [Docker Hub][6].

## Start a container

There is an example to start a container for CentOS 6 like below:

```bash
$ mkdir -m 777 -p /opt/builder6
$ docker run -it --rm -h buildbot --name rpmbuild6 -v /opt/builder6:/home/builder/rpmbuild teddysun/rpmbuild:6
```

There is an example to start a container for CentOS 7 like below:

```bash
$ mkdir -m 777 -p /opt/builder7
$ docker run -it --rm -h buildbot --name rpmbuild7 -v /opt/builder7:/home/builder/rpmbuild teddysun/rpmbuild:7
```

There is an example to start a container for CentOS 8 like below:

```bash
$ mkdir -m 777 -p /opt/builder8
$ docker run -it --rm -h buildbot --name rpmbuild8 -v /opt/builder8:/home/builder/rpmbuild teddysun/rpmbuild:8
```

[1]: https://docs.docker.com/
[2]: https://github.com/teddysun/across/blob/master/docker/rpmbuild/Dockerfile.centos8
[3]: https://github.com/teddysun/across/blob/master/docker/rpmbuild/Dockerfile.centos7
[4]: https://github.com/docker-library/official-images#architectures-other-than-amd64
[5]: https://docs.docker.com/install/
[6]: https://hub.docker.com/r/teddysun/rpmbuild/
[7]: https://github.com/teddysun/across/blob/master/docker/rpmbuild/Dockerfile.centos6