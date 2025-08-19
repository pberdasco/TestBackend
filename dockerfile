# =========================
# Base común
# =========================
FROM node:22-alpine AS base
# instalar curl en el alpine
RUN apk add --no-cache curl 
WORKDIR /app
RUN corepack enable

# =========================
# Dependencias PRODUCCIÓN
# =========================
FROM base AS deps-prod
COPY package*.json ./
# Solo deps de producción
RUN npm ci --omit=dev

# =========================
# Dependencias TEST/DEV
# =========================
FROM base AS deps-test
COPY package*.json ./
# Incluye devDependencies (p.ej. vitest, nodemon, etc.)
RUN npm ci

# =========================
# Runtime PRODUCCIÓN
# =========================
FROM base AS runtime-prod
ENV NODE_ENV=production
# Copiamos node_modules de prod
COPY --chown=node:node --from=deps-prod /app/node_modules ./node_modules
# Copiamos el código
COPY --chown=node:node . .
# Opcional: excluir carpetas de runtime en prod
# (pediste "quizás sin request, scaffolder y sql")
RUN rm -rf request scaffolder sql

# (opcional: si no servís /public desde el backend)
# RUN rm -rf public


# El backend debe escuchar en $PORT (ver .env)
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s \
  CMD curl -fsS http://127.0.0.1:${PORT:-5111}/health || exit 1

# Ejecutar modo prod (node src/server.js)
CMD ["npm", "run", "start"]

# =========================
# Runtime TEST/DEV
# =========================
FROM base AS runtime-test
ENV NODE_ENV=development
COPY --chown=node:node --from=deps-test /app/node_modules ./node_modules
COPY --chown=node:node . .

HEALTHCHECK --interval=30s --timeout=3s --start-period=20s \
  CMD curl -fsS http://127.0.0.1:${PORT:-5111}/health || exit 1

# Ejecutar modo dev
CMD ["npm", "run", "dev"]
