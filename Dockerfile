FROM python:3.8-alpine

COPY . /app
WORKDIR /app

RUN python -m venv /usr/local/env \
  && source /usr/local/env/bin/activate \
  && pip install -r requirements.txt

ENV PATH /usr/local/env/bin:$PATH

EXPOSE 8000
CMD ["mkdocs", "serve", "-a", "0.0.0.0:8000"]
