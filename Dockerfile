# Use OpenJDK 17 as the base image
FROM openjdk:8-alpine

# Install curl and bash for file handling
RUN apk add --no-cache curl bash screen git

# users
ARG DOCKER_USER=user
RUN adduser -D $DOCKER_USER
#RUN echo "myuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN mkdir -p /minecraft
RUN chown -R $DOCKER_USER:$DOCKER_USER /minecraft

WORKDIR /minecraft

COPY startup.sh startup.sh

RUN chmod +x ./startup.sh


USER $DOCKER_USER

WORKDIR /minecraft/data

RUN chmod -R 777 .

CMD ../startup.sh