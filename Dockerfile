FROM docker.io/drycc/base:bullseye

ENV PYTHON_VERSION=3.10.2
COPY . /app
WORKDIR /app

RUN export DEBIAN_FRONTEND=noninteractive \
  && install-stack python $PYTHON_VERSION && . init-stack \
  && set -eux; pip3 install -r requirements.txt 2>/dev/null

EXPOSE 8000
CMD ["mkdocs", "serve", "-a", "0.0.0.0:8000"]
