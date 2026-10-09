FROM node:20-alpine AS build 
WORKDIR /app 
COPY package*.json ./ 
COPY . . 
ENV NODE_OPTIONS="--max-old-space-size=4096" 
RUN npx vite build 
FROM nginx:alpine 
COPY --from=build /app/dist /usr/share/nginx/html 
EXPOSE 80 
CMD ["nginx", "-g", "daemon off;"] 
