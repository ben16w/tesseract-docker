# tesseract-docker

This repository contains Docker Compose files for Tesseract.

## Installation

Before you begin, make sure you have Docker installed on your system. You can download and install Docker for your operating system using the following links:

- [Docker for Windows](https://docs.docker.com/docker-for-windows/install/)
- [Docker for Mac](https://docs.docker.com/docker-for-mac/install/)
- [Docker for Linux](https://docs.docker.com/engine/install/)

Once you have Docker installed, follow these steps:

1. Clone this repository to your local machine.
2. Edit the `.env` file to set the environment variables for your use case.

## Usage

Firstly navigate to the cloned repository directory in your terminal. Then run the appropriate Docker Compose file for your use case.

For example, to start Nextcloud, run the following command:

        docker-compose -f docker-compose.nextcloud.yml up -d

Example environment variables which can be installed in a `.env` file:

        DOCKER_DATA_PATH="./data"
        DOCKER_APPDATA_PATH="./appdata"
        DOCKER_USERNAME='vagrant'
        DOCKER_EMAIL_USERNAME='ben@ben.com'
        DOCKER_EMAIL_HOST='ben.mail.com'
        DOCKER_EMAIL_PORT='465'
        DOCKER_EMAIL_PASSORD='password'
        DOCKER_HOSTNAME='test.test'
        DOCKER_DOMAIN=''
        DOCKER_SQL_PASSWORD='password'
        DOCKER_TZ='Europe/London'
        DOCKER_UID='1000'
        DOCKER_GID='1000'
        DOCKER_DOCKER_USERNAME='ben'
        DOCKER_DOCKER_PASSWORD='password'
        DOCKER_VAULTWARDEN_ADMIN_TOKEN='token'
        DOCKER_IMMICH_JWT_SECRET='secret'
        DOCKER_PAPERLESS_SECRET_KEY='secret'

## License

This project is licensed under the Unlicense - see the LICENSE file for details
