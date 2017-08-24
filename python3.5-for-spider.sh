#!/bin/bash
set -e
docker run -it --rm --name my-running-script -v `pwd`:/usr/src/myapp -w /usr/src/myapp ddv12138/python:3.5 python $1
