#!/bin/bash

set -ex

cd "${0%/*}"

SUITE=${1:-bullseye}
CONT=$(buildah from localhost/debian-systemd-${SUITE})

buildah copy $CONT etc/ /etc
buildah copy $CONT root/ /root
buildah copy $CONT setup/ /setup
buildah run $CONT /bin/bash /setup/setup.sh
buildah run $CONT rm -rf /setup

buildah config --author "Alexander Veit" $CONT
#buildah config --cmd '/sbin/init' $CONT
buildah config --port 22/tcp $CONT
buildah config --port 25/tcp $CONT
buildah config --port 465/tcp $CONT
buildah config --port 587/tcp $CONT
buildah config --port 143/tcp $CONT
buildah config --port 993/tcp $CONT

buildah commit --rm $CONT localhost/debian-mail-${SUITE}:latest

