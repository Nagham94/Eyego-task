# Use Node.js image based on Alpine Linux as a base image
FROM node:lts-alpine3.22

# the working directory inside the container
WORKDIR /usr/app

# Copy package.json and package-lock.json to the working directory 
COPY package*.json /usr/app/

# Install dependencies from package.json
RUN npm install

# Copy the rest of the application files into the container
COPY . .

# Expose port 3000 for incoming traffic
EXPOSE 3000

# command to run the application
CMD [ "node", "index.js" ]
