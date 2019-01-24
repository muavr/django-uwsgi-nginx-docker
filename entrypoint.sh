#!/bin/bash

# -e exit immediately if a command exits with a non-zero status
# -x print commands and their arguments as they are executed
if [ "$DEBUG" = "TRUE" ]; then
    set -ex
fi

source ./venv/bin/activate

# checks whether $WORKING_DIRECTORY directory is empty
if !(find "$WORKING_DIRECTORY" -mindepth 1 -not -path "$WORKING_DIRECTORY/venv/*" -type f -print -quit | grep -q .); then
    echo 'Directory '$WORKING_DIRECTORY' is empty.'
    
# checks whether source directory directory is empty
    if !(find "$TMP_DIR/env/src/" -mindepth 1 -print -quit | grep -q .); then
        echo 'Creating new Django project...'
        pip install django
        django-admin startproject $PROJECT_NAME ./
    else
        echo 'Copying project files...'
        cp -r $TMP_DIR/env/src/* $WORKING_DIRECTORY/
        if [ -f "./requirements.txt" ]; then
            pip install -r requirements.txt
        else
            pip install django
        fi
    fi
fi


mkdir -p /var/log/uwsgi/
mkdir -p /etc/uwsgi/vassals/
mkdir -p /run/${PROJECT_NAME}

chown -R www-data:www-data /var/log/uwsgi/
chown -R www-data:www-data /run/${PROJECT_NAME}

cp $TMP_DIR/env/conf/uwsgi/emperor.ini /etc/uwsgi/emperor.ini
cp $TMP_DIR/env/conf/uwsgi/uwsgi.ini /etc/uwsgi/vassals/${PROJECT_NAME}_uwsgi.ini

cp $TMP_DIR/env/conf/nginx/nginx.conf /etc/nginx/nginx.conf
cp $TMP_DIR/env/conf/nginx/template.conf  /etc/nginx/sites-enabled/${PROJECT_NAME}_nginx.conf

cp $TMP_DIR/env/conf/supervisor/project_supervisord.conf /etc/supervisor/conf.d/project_supervisord.conf
cp $TMP_DIR/env/conf/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

envsubst < /etc/nginx/sites-enabled/${PROJECT_NAME}_nginx.conf > /etc/nginx/sites-enabled/${PROJECT_NAME}_nginx.conf_tmp
mv /etc/nginx/sites-enabled/${PROJECT_NAME}_nginx.conf_tmp /etc/nginx/sites-enabled/${PROJECT_NAME}_nginx.conf

rm -fr $TMP_DIR

exec supervisord -nc /etc/supervisor/supervisord.conf "$@"
