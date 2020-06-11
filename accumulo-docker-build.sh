#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage : $0 <accumulo src dir>"
    exit 1
fi

ACCUMULO_SRC=$1

docker build -t accumulo-build .

USER_NAME=${SUDO_USER:=$USER}
USER_ID=$(id -u "${USER_NAME}")

if [ "$(uname -s)" = "Darwin" ]; then
  GROUP_ID=100
fi

if [ "$(uname -s)" = "Linux" ]; then
  GROUP_ID=$(id -g "${USER_NAME}")
fi

docker build -t "accumulo-build-${USER_ID}" - <<UserSpecificDocker
FROM accumulo-build
RUN rm -f /var/log/faillog /var/log/lastlog
RUN groupadd --non-unique -g ${GROUP_ID} ${USER_NAME}
RUN useradd -g ${GROUP_ID} -u ${USER_ID} -k /root -m ${USER_NAME}
RUN mkdir -p /etc/sudoers.d
RUN echo "${USER_NAME} ALL=NOPASSWD: ALL" > "/etc/sudoers.d/accumulo-build-${USER_ID}"
ENV HOME /home/${USER_NAME}
UserSpecificDocker

docker run -it \
  -v "${ACCUMULO_SRC}:/home/${USER_NAME}/accumulo-src:cached" \
  -w "/home/${USER_NAME}/accumulo-src" \
  -v "${HOME}/.m2:/home/${USER_NAME}/.m2:cached" \
  -u "${USER_ID}" \
  "accumulo-build-${USER_ID}" bash
