#!/bin/sh
#
# /!\ THIS FILE IS OVERWRITTEN BY THE docker-entrypoint.sh
#
set -e

#
# SCRIPT THAT RUNS BEFORE THE NEXT.JS APP
#
# It is used to apply database migrations
#

if [ "$DATABASE_URL" ]; then
    echo "Applying migrations..."
    npx prisma migrate deploy
    echo "Migrations applied."
fi

# We are now done with the entrypoint, let's run the app
exec "$@"
