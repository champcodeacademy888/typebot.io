# ================== BUILDER ======================
FROM oven/bun:1 as builder
WORKDIR /app
COPY . .
RUN bun install --frozen-lockfile
RUN bunx turbo build --filter=public-api

# ================== FINAL IMAGE ======================
FROM oven/bun:1-slim as release
WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages/prisma/postgresql ./packages/prisma/postgresql
COPY --from=builder /app/apps/public-api/dist ./apps/public-api/dist

RUN ./node_modules/.bin/prisma generate --schema=packages/prisma/postgresql/schema.prisma;

EXPOSE 3000
ENV PORT=3000

CMD ["bun", "./apps/public-api/dist/server.js"]
