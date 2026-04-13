FROM node:20-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --production

COPY export.js ./

CMD ["node", "export.js"]
