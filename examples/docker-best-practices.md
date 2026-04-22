# docker-best-practices — Real-World Examples

The skill enforces secure and efficient container patterns. Each example shows a concrete Dockerfile or Compose configuration, the problem it causes, and the correct fix.

## Before / After

### Example 1: Full single-stage build shipped to production

**Before** (triggers the skill):
```dockerfile
# ❌ Everything ends up in the production image:
#    - TypeScript compiler and ts-node (~200 MB)
#    - All devDependencies
#    - Full source tree including test files
#    - .env files if they exist in the build context
FROM node:20
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
EXPOSE 3000
CMD ["node", "dist/server.js"]
# docker images: myapp   latest   1.31GB
```

**After** (skill-compliant):
```dockerfile
# ✅ Multi-stage: builder has compiler; runner has only the compiled output
FROM node:20-slim AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

FROM node:20-slim AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs \
 && adduser --system --uid 1001 --ingroup nodejs appuser
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts
COPY --from=builder --chown=appuser:nodejs /app/dist ./dist
USER appuser
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
EXPOSE 3000
CMD ["node", "dist/server.js"]
# docker images: myapp   latest   178MB  (86% smaller)
```

**Why:** The build image needs the TypeScript compiler, type definitions, and test utilities — none of which belong in a running container. Multi-stage builds copy only the compiled `dist/` directory and production `node_modules` into the final image. Combined with a non-root user and health check, this is production-grade.

---

### Example 2: Secrets baked into a Docker image

**Before** (triggers the skill):
```dockerfile
# ❌ API key is now in the image layer — visible with `docker history` or `docker inspect`
FROM node:20-slim
ARG STRIPE_SECRET_KEY
ENV STRIPE_SECRET_KEY=$STRIPE_SECRET_KEY
COPY . .
RUN npm ci
CMD ["node", "server.js"]
```

```bash
# The key is now permanently embedded:
docker build --build-arg STRIPE_SECRET_KEY=sk_live_... -t myapp .
docker history myapp   # ← key appears in plain text
```

**After** (skill-compliant):
```dockerfile
# ✅ BuildKit secret mount — available during build, never written to any layer
# syntax=docker/dockerfile:1
FROM node:20-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN --mount=type=secret,id=npm_token \
    npm config set //registry.npmjs.org/:_authToken=$(cat /run/secrets/npm_token) \
 && npm ci --ignore-scripts
COPY . .
RUN npm run build
```

```bash
# Secret passed at build time, never stored:
DOCKER_BUILDKIT=1 docker build \
  --secret id=npm_token,env=NPM_TOKEN \
  -t myapp .
```

```yaml
# Runtime secrets via env_file — loaded at `docker run`, not baked in
# docker-compose.yml
services:
  api:
    image: myapp:latest
    env_file:
      - .env    # contains STRIPE_SECRET_KEY, never written into the image
```

**Why:** `ENV` and `ARG` values survive in image metadata and layer history even after the Dockerfile instruction that set them. Any developer who can `docker pull` the image can read the secret. Runtime injection via `--env-file` keeps secrets out of the image entirely.

---

### Example 3: Missing .dockerignore sends secrets into the build context

**Before** (triggers the skill):
```bash
# No .dockerignore in project root
# docker build sends EVERYTHING to the daemon, including:
#   .env              ← live API keys
#   .env.local        ← local overrides with passwords
#   node_modules/     ← 500 MB that gets overwritten by npm ci anyway
#   .git/             ← full commit history including previously deleted secrets
#   coverage/         ← test output
#   *.log             ← debug logs that may contain tokens

docker build -t myapp .
# Sending build context to Docker daemon  847MB   ← slow and leaky
```

**After** (skill-compliant):
```
# .dockerignore
.git
.gitignore
node_modules
npm-debug.log*
.env
.env.*
*.local
.DS_Store
dist
coverage
.nyc_output
.next
.turbo
*.log
Dockerfile*
docker-compose*.yml
README.md
tests/
__tests__/
*.test.ts
*.spec.ts
```

```bash
docker build -t myapp .
# Sending build context to Docker daemon  1.2MB   ← only source files
```

**Why:** Without `.dockerignore`, the entire working directory — including `.env` files with live credentials — is sent to the Docker daemon as the build context. Even if your `COPY` instructions never reference them, they exist in the context and can be accessed by malicious or misconfigured `RUN` steps (e.g., a compromised npm postinstall hook that reads `/run/context/`).
