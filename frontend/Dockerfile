FROM node:18

WORKDIR /app

COPY . .

RUN npm install
RUN npm install react-scripts
RUN npm run build

CMD ["npx", "serve", "-s", "build"]