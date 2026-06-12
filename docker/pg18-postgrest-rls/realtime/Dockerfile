FROM node:22-alpine@sha256:8456a1e0e6b9ab7bfd3ce1e82a19cc0b59ca46c0966497f929d01956cc32809b
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev
COPY server.js test-client.js ./
EXPOSE 4000
CMD ["node", "server.js"]
