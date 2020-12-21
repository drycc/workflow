FROM python:3.8-alpine

COPY . /app
WORKDIR /app

RUN pip install -r requirements.txt

EXPOSE 8000
CMD ["mkdocs", "serve", "-a", "0.0.0.0:8000"]
