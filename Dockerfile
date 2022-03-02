FROM docker.io/drycc/base:bullseye

ENV PYTHON_VERSION=3.10.2
COPY . /app
WORKDIR /app

RUN export DEBIAN_FRONTEND=noninteractive \
  && install-stack python $PYTHON_VERSION && . init-stack \
  && python -m venv /usr/local/env \
  && source /usr/local/env/bin/activate \
  && pip install -r requirements.txt

EXPOSE 8000
CMD ["PATH=/usr/local/env/bin:\$PATH", "mkdocs", "serve", "-a", "0.0.0.0:8000"]
