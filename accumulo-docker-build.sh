#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage : $0 <accumulo src dir>"
    exit 1
fi

ACCUMULO_SRC=$1

# Build a general Docker image for building Accumulo
docker build -t accumulo-build .

USER_NAME=${SUDO_USER:=$USER}
USER_ID=$(id -u "${USER_NAME}")

if [ "$(uname -s)" = "Darwin" ]; then
  GROUP_ID=100
fi

if [ "$(uname -s)" = "Linux" ]; then
  GROUP_ID=$(id -g "${USER_NAME}")
fi

# By default everything in a Docker container runs as root.  The following
# builds a specific image that will run with the same username and userid in
# the container as your user outside the container.  This is done so that when
# you map your Accumulo source dir into the container and it writes out class
# and tar.gz files those will have the correct user id.
docker build -t "accumulo-build-${USER_ID}" - <<UserSpecificDocker
FROM accumulo-build
RUN rm -f /var/log/faillog /var/log/lastlog
RUN groupadd --non-unique -g ${GROUP_ID} ${USER_NAME}
RUN useradd -g ${GROUP_ID} -u ${USER_ID} -k /root -m ${USER_NAME}
RUN mkdir -p /etc/sudoers.d
RUN echo "${USER_NAME} ALL=NOPASSWD: ALL" > "/etc/sudoers.d/accumulo-build-${USER_ID}"
ENV HOME /home/${USER_NAME}
ENV USER ${USER_NAME}
UserSpecificDocker

#If this env varible is empty, docker will be started	#If this env varible is true, docker will be started
# in non interactive mode	# in interactive mode
DOCKER_INTERACTIVE_RUN=${DOCKER_INTERACTIVE_RUN-"-i -t"}

# Run a docker container that has your Accumulo source and Maven repo mapped
# into the container.  These dirs are mapped into the container using cached,
# which may cause writes to be slightly delayed but it improves performance.
docker run --rm=true $DOCKER_INTERACTIVE_RUN \
  -v "${ACCUMULO_SRC}:/home/${USER_NAME}/accumulo-src:cached" \
  -w "/home/${USER_NAME}/accumulo-src" \
  -v "${HOME}/.m2:/home/${USER_NAME}/.m2:cached" \
  -u "${USER_ID}" \
  "accumulo-build-${USER_ID}" bash
