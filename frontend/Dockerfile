# Use official Node image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json ./

# Install dependencies
RUN npm install

# Copy rest of the files
COPY . .

# Build app
RUN npm run build

# Serve with nginx
FROM nginx:alpine
COPY --from=0 /app/build /usr/share/nginx/html

EXPOSE 809
CMD ["nginx", "-g", "daemon off;"]