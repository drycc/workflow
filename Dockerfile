FROM docker.io/drycc/base:bullseye

RUN adduser --system \
	--shell /bin/bash \
	--disabled-password \
	--home /workspace \
	--group \
	drycc

ENV PYTHON_VERSION=3.10.2
COPY . /workspace
WORKDIR /workspace

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
  && mkdir -p /usr/share/man/man{1..8} \
  && chown -R drycc:drycc /workspace

USER drycc
EXPOSE 8000
CMD ["mkdocs", "serve", "-a", "0.0.0.0:8000"]
