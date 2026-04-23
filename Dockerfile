FROM node:18-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./

RUN node -e "\
const fs = require('fs'); \
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8')); \
pkg.dependencies['@nestjs/common'] = '^10.4.22'; \
pkg.dependencies['@nestjs/core'] = '^10.4.22'; \
pkg.dependencies['@nestjs/platform-express'] = '^10.4.22'; \
if (pkg.devDependencies) { \
  pkg.devDependencies['@nestjs/cli'] = '^10.4.5'; \
  pkg.devDependencies['@nestjs/schematics'] = '^10.2.2'; \
  pkg.devDependencies['@nestjs/testing'] = '^10.4.22'; \
} \
pkg.overrides = { \
  'body-parser': '^1.20.3', \
  'multer': '^2.1.1', \
  'express': { \
    '.': '^4.21.0', \
    'path-to-regexp': '^0.1.13' \
  }, \
  'qs': '^6.14.2' \
}; \
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2)); \
"

RUN npm install

COPY . .

RUN npm run build

FROM node:18-alpine

WORKDIR /usr/src/app

# Security best practice: run as non-root user
USER node

# Copy built artifacts and dependencies
COPY --from=builder --chown=node:node /usr/src/app/node_modules ./node_modules
COPY --from=builder --chown=node:node /usr/src/app/package*.json ./
COPY --from=builder --chown=node:node /usr/src/app/dist ./dist

EXPOSE 3000

CMD ["npm", "run", "start:prod"]
