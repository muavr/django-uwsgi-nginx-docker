FROM ubuntu:16.04

RUN set -ex && \
    apt-get update && \
    apt-get install -y \
    "mc" \
    "figlet" \
    "nginx" \
    "python3-pip" \
    "python3-dev" \
    "build-essential" \
    "libssl-dev" \
    "libffi-dev" \
    "supervisor" \
    "gettext-base" && \
    pip3 install virtualenv


ARG DEBUG
ARG PROJECT_NAME

ENV DEBUG ${DEBUG:-TRUE}
ENV WEBUSER webuser
ENV PROJECT_NAME ${PROJECT_NAME:-myproject}
ENV TMP_DIR /tmp/$PROJECT_NAME
ENV WORKING_DIRECTORY /home/$WEBUSER/var/www/$PROJECT_NAME

WORKDIR $WORKING_DIRECTORY

RUN set -ex && \
    useradd -ms /bin/bash $WEBUSER && \
    mkdir -p /tmp/$PROJECT_NAME && \
    mkdir -p $WORKING_DIRECTORY && \
    virtualenv venv --python `which python3` && \
    . $WORKING_DIRECTORY/venv/bin/activate && \
    pip3 install --upgrade pip && \
    pip3 install uwsgi


COPY /env $TMP_DIR/env
COPY /entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
