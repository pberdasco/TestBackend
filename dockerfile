# =========================
# Base común
# =========================
FROM node:22-alpine AS base
WORKDIR /app
ENV NODE_ENV=production
# opcional pero útil si usás yarn/pnpm
RUN corepack enable

# =========================
# Instalar dependencias de PRODUCCIÓN
# =========================
FROM base AS deps-prod
COPY package*.json ./
RUN npm ci --omit=dev

# =========================
# Instalar dependencias de TEST (incluye devDeps)
# =========================
FROM base AS deps-test
ENV NODE_ENV=development
COPY package*.json ./
RUN npm ci

# =========================
# Runtime PRODUCCIÓN
# =========================
FROM node:22-alpine AS runtime-prod
WORKDIR /app
ENV NODE_ENV=production
# usuario no root por seguridad
USER node

# 1) node_modules de prod
COPY --chown=node:node --from=deps-prod /app/node_modules ./node_modules
# 2) código fuente
COPY --chown=node:node . .

# healthcheck simple (requiere curl)
USER root
RUN apk add --no-cache curl
USER node
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -fsS http://127.0.0.1:${PORT:-3000}/health || exit 1

# Ajustá el entrypoint a tu archivo real (server.js, app.js, etc.)
CMD ["npm", "start"]

# =========================
# Runtime TEST / STAGING
# =========================
FROM node:22-alpine AS runtime-test
WORKDIR /app
ENV NODE_ENV=development
USER node

# 1) node_modules con devDeps
COPY --chown=node:node --from=deps-test /app/node_modules ./node_modules
# 2) código fuente
COPY --chown=node:node . .

USER root
RUN apk add --no-cache curl
USER node
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -fsS http://127.0.0.1:${PORT:-3000}/health || exit 1

# En test node --watch
CMD ["npm", "run", "dev"]
