#!/usr/bin/bash
set -e

echo "Add github token so we can pull from private repos"
sudo -u app git config --global url."https://api:$OAUTHTOKEN@github.com/".insteadOf "https://github.com/"
sudo -u app git config --global url."https://ssh:$OAUTHTOKEN@github.com/".insteadOf "ssh://git@github.com/"
sudo -u app git config --global url."https://git:$OAUTHTOKEN@github.com/".insteadOf "git@github.com:"

echo "Change to $APP_DIR and run bundle install as app user"
cd $APP_DIR
sudo -u app bundle install

echo "Create template files"
cp "$APP_DIR/config/secrets.yml.example" "$APP_DIR/config/secrets.yml"
cp "$APP_DIR/config/database.yml.example" "$APP_DIR/config/database.yml"
cp "$APP_DIR/config/sunspot.yml.example" "$APP_DIR/config/sunspot.yml"

echo "Modify config file for database"
sed -i 's/{{ database_host }}/'"$DB_HOST"'/g' "$APP_DIR/config/database.yml"
sed -i 's/{{ database_username }}/'"$DB_USER"'/g' "$APP_DIR/config/database.yml"
sed -i 's/{{ database_password }}/'"$DB_PASSWORD"'/g' "$APP_DIR/config/database.yml"
sed -i 's/{{ database_name }}/'"$DB_NAME"'/g' "$APP_DIR/config/database.yml"

echo "Modify config file for secrets"
sed -i 's/{{ auth_server_id }}/'"$AUTH_SERVER_ID"'/g' "$APP_DIR/config/secrets.yml"
sed -i 's/{{ client_id }}/'"$CLIENT_ID"'/g' "$APP_DIR/config/secrets.yml"
sed -i 's/{{ client_secret }}/'"$CLIENT_SECRET"'/g' "$APP_DIR/config/secrets.yml"
sed -i 's/{{ secret_key_base }}/'"$SECRET_KEY_BASE"'/g' "$APP_DIR/config/secrets.yml"
sed -i 's/{{ host_name }}/'"$HOST_NAME"'/g' "$APP_DIR/config/secrets.yml"
sed -i 's/{{ api_token }}/'"$API_TOKEN"'/g' "$APP_DIR/config/secrets.yml"
if [[ "$PASSENGER_APP_ENV" == "development" ]]; then
   sed -i 's/{{ api_host }}/'"$API_HOST"'/g' "$APP_DIR/config/secrets.yml"
fi
sed -i 's/{{ coral_password }}/'"$CORAL_PASSWORD"'/g' "$APP_DIR/config/secrets.yml"
sed -i 's/{{ service_password }}/'"$SERVICE_PASSWORD"'/g' "$APP_DIR/config/secrets.yml"
sed -i 's/{{ refworks_password }}/'"$REFWORKS_PASSWORD"'/g' "$APP_DIR/config/secrets.yml"
sed -i 's/{{ sentrydsn }}/'"$SENTRYDN"'/g' "$APP_DIR/config/secrets.yml"
sed -i 's/{{ illiad_password }}/'"$ILLIAD_PASSWORD"'/g' "$APP_DIR/config/secrets.yml"
sed -i 's/{{ rabbitmq_host }}/'"$RABBITMQ_HOST"'/g' "$APP_DIR/config/secrets.yml"

echo "Modify webapp config file for PASSENGER_APP_ENV setting"
sed -i 's/{{ passenger_app_env }}/'"$PASSENGER_APP_ENV"'/g' "/etc/nginx/sites-enabled/webapp.conf"

echo "Run the assests precompile rake job"
RAILS_ENV=$PASSENGER_APP_ENV bundle exec rake assets:precompile

echo "Fix permissions on $APP_DIR folder"
chown -R app:app $APP_DIR

if [[ "$PASSENGER_APP_ENV" == "development" ]]; then
    if  [[ $RUN_TASK == 1 ]]; then
        echo "Run development database migrations"
        RAILS_ENV=$PASSENGER_APP_ENV bundle exec rake db:migrate
    fi
fi

if [[ "$PASSENGER_APP_ENV" == "development" ]]; then
    if  [[ $RUN_TASK == 1 ]]; then
        echo "Adding sample bins"
        RAILS_ENV=$PASSENGER_APP_ENV bundle exec rake sample:bins
        echo "Adding sample shelves"
        RAILS_ENV=$PASSENGER_APP_ENV bundle exec rake sample:shelves
        echo "Adding sample trays"
        RAILS_ENV=$PASSENGER_APP_ENV bundle exec rake sample:trays
        echo "Adding sample items"
        RAILS_ENV=$PASSENGER_APP_ENV bundle exec rake sample:items
        echo "Adding sample users"
        RAILS_ENV=$PASSENGER_APP_ENV bundle exec rake sample:users
    fi
fi

echo "Need to wait for RabbitMQ HOST before running rake jobs"
if ! "$APP_DIR/wait-for-it.sh" $RABBITMQ_HOST:15672 -t 180; then exit 1; fi

echo "Wait an additional 15 seconds"
sleep 15

if  [[ $RUN_TASK == 1 ]]; then
    if [[ "$PASSENGER_APP_ENV" != "development" ]]; then
        echo "Run database migrations"
        RAILS_ENV=$PASSENGER_APP_ENV bundle exec rake db:migrate
    fi
    echo "Start Passenger Service as $PASSENGER_APP_ENV"
    exec /sbin/my_init
fi

if  [[ $RUN_TASK == 2 ]]
then
    echo "Start sneakers"
    RAILS_ENV=$PASSENGER_APP_ENV exec bundle exec rake sneakers:run
fi

if  [[ $RUN_TASK == 3 ]]
then
    echo "Run the Scheduled Reports job once at midnight"
    if [[ $(date -u -d "now + 30 minutes" +'%H') -eq "05" ]]
    then
        echo "Run the rails runner Scheduled Reports job"
        RAILS_ENV=$PASSENGER_APP_ENV bundle exec rake annex:run_scheduled_reports
        echo "Rake Notify job completed"
    else
        echo "Run the rake annex:get_active_requests job"
        RAILS_ENV=$PASSENGER_APP_ENV bundle exec rake annex:get_active_requests
        echo "Rake jobs completed"
    fi
fi
