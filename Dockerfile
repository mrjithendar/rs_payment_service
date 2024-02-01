FROM      python:3.9
RUN       mkdir /app
WORKDIR   /app
COPY      payment-docker.py payment.py
COPY      payment.ini .
COPY      rabbitmq.py .
COPY      requirements.txt .
RUN       pip3 install -r requirements.txt
CMD       ["uwsgi", "--ini", "payment.ini"]