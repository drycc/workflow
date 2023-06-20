ARG CODENAME
FROM registry.drycc.cc/drycc/base:${CODENAME}

ENV DRYCC_UID=1001 \
  DRYCC_GID=1001 \
  DRYCC_HOME_DIR=/workspace \
  PYTHON_VERSION=3.11

RUN groupadd drycc --gid ${DRYCC_GID} \
  && useradd drycc -u ${DRYCC_UID} -g ${DRYCC_GID} -s /bin/bash -m -d ${DRYCC_HOME_DIR}

WORKDIR ${DRYCC_HOME_DIR}

COPY --chown=${DRYCC_UID}:${DRYCC_GID} . ${DRYCC_HOME_DIR}

RUN export DEBIAN_FRONTEND=noninteractive \
  && install-stack python $PYTHON_VERSION && . init-stack \
  && set -eux; pip3 install -r requirements.txt 2>/dev/null \
  && rm -rf \
        /usr/share/doc \
        /usr/share/man \
        /usr/share/info \
        /usr/share/locale \
        /var/lib/apt/lists/* \
        /var/log/* \
        /var/cache/debconf/* \
        /etc/systemd \
        /lib/lsb \
        /lib/udev \
        /usr/lib/`echo $(uname -m)`-linux-gnu/gconv/IBM* \
        /usr/lib/`echo $(uname -m)`-linux-gnu/gconv/EBC* \
  && mkdir -p /usr/share/man/man{1..8}

USER ${DRYCC_UID}
EXPOSE 8000
CMD ["mkdocs", "serve", "-a", "0.0.0.0:8000"]
