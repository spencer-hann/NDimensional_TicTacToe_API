FROM python:3.7-alpine3.7

WORKDIR /usr/app/

# Install app dependencies
COPY requirements.txt ./
RUN apk add --no-cache --virtual .build-deps \
    make automake gcc g++ subversion python3-dev musl-dev
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt --upgrade

COPY *.py* /usr/app/
COPY agents /usr/app/agents
COPY setup.py /usr/app
RUN python setup.py
RUN apk del .build-deps

ENTRYPOINT ["python", "/usr/app/tictactoe.py"]
