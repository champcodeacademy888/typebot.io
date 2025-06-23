#!/bin/sh
set -e

if [ "$DATABASE_URL" ]; then
    echo "Applying migrations..."
    npx prisma migrate deploy
    echo "Migrations applied."
fi

exec "$@"
