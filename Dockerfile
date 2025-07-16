FROM python:3.12-slim

# Dependencies
RUN apt-get update && apt-get install -y \
	nginx \
	gcc \
	supervisor && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Config
COPY flask_config/nginx.conf /etc/nginx/sites-enabled/
RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
	rm /etc/nginx/sites-enabled/default

COPY flask_config/app.ini /config/
COPY flask_config/supervisor.conf /etc/supervisor/conf.d/

# Local app
COPY app /app
COPY flask_config/requirements.txt /config/
RUN pip install --upgrade pip && \
	pip install -r /config/requirements.txt

EXPOSE 80

# Start Supervisor, in turn start Nginx and uWSGI
CMD ["supervisord", "-n"]
