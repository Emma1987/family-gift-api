#!/bin/sh
set -e

# Install Composer dependencies if not already installed
if [ -z "$(ls -A 'vendor/' 2>/dev/null)" ]; then
    echo "Installing Composer dependencies..."
    composer install --prefer-dist --no-progress --no-interaction
fi

# Wait for the database to be ready (only if DATABASE_URL is set)
if grep -q ^DATABASE_URL= .env; then
    echo "Waiting for database to be ready..."
    ATTEMPTS_LEFT_TO_REACH_DATABASE=60
    until [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -eq 0 ] || DATABASE_ERROR=$(php bin/console dbal:run-sql -q "SELECT 1" 2>&1); do
        if [ $? -eq 255 ]; then
            # If the Doctrine command exits with 255, an unrecoverable error occurred
            ATTEMPTS_LEFT_TO_REACH_DATABASE=0
            break
        fi
        sleep 1
        ATTEMPTS_LEFT_TO_REACH_DATABASE=$((ATTEMPTS_LEFT_TO_REACH_DATABASE - 1))
        echo "Still waiting for database to be ready... $ATTEMPTS_LEFT_TO_REACH_DATABASE attempts left."
    done

    if [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -eq 0 ]; then
        echo "The database is not up or not reachable:"
        echo "$DATABASE_ERROR"
        exit 1
    else
        echo "The database is now ready and reachable"
    fi

    # Run migrations if they exist
    if [ "$( find ./migrations -iname '*.php' -print -quit )" ]; then
        echo "Running migrations..."
        php bin/console doctrine:migrations:migrate --no-interaction --all-or-nothing
    fi
fi

# Set file permissions for Symfony (important for var and public directories)
chmod -R 777 var

# Proceed with the default command (apache2-foreground)
exec "$@"
