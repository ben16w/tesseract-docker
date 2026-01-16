# docker-compose

This repository contains Docker Compose files for Tesseract.

## Installation

Firstly ensure Docker is installed. Details on how to install Docker can be found below:

- [Docker for Windows](https://docs.docker.com/docker-for-windows/install/)
- [Docker for Mac](https://docs.docker.com/docker-for-mac/install/)
- [Docker for Linux](https://docs.docker.com/engine/install/)

Install the required system packages:

```sh
sudo apt install make python3 python3-pip python3-venv
```

Set up the virtual environment and install the required Python packages:

```sh
make install-venv
```

Lint the Docker Compose files:

```sh
make lint
```

## Usage

Firstly navigate to the cloned repository directory in your terminal. Then run the appropriate Docker Compose file for your use case.

For example, to start Nextcloud, run the following command:

```sh
docker-compose -f docker-compose.nextcloud.yml up -d
```

Example environment variables which can be installed in a `.env` file:

```sh
TESSERACT_DATA_PATH="./data"
TESSERACT_APPDATA_PATH="./appdata"
TESSERACT_USERNAME='ubuntu'
TESSERACT_EMAIL_USERNAME='user@domain.com'
TESSERACT_EMAIL_HOST='user.domain.com'
TESSERACT_EMAIL_PORT='465'
TESSERACT_EMAIL_PASSWORD='password'
TESSERACT_HOSTNAME='test.test'
TESSERACT_DOMAIN=''
TESSERACT_SQL_PASSWORD='password'
TESSERACT_TZ='Europe/London'
TESSERACT_UID='1000'
TESSERACT_GID='1000'
TESSERACT_DOCKER_USERNAME='user'
TESSERACT_DOCKER_PASSWORD='password'
TESSERACT_VAULTWARDEN_ADMIN_TOKEN='token'
TESSERACT_IMMICH_JWT_SECRET='secret'
TESSERACT_PAPERLESS_SECRET_KEY='secret'
```

## License

This project is licensed under the Unlicense. See the [LICENSE](LICENSE) file for details.

## Authors

- Ben Wadsworth
