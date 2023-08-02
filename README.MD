# Mercure Installer

This repository contains scripts to install and run the Mercure server based on the Caddy webserver onto your system. Its main goal is to install and configure the Mercure server automatically, and setting it up in such a way that it will automatically be managed by supervisor (on Linux).

However, `mercure.sh` can also be used (manually) as a handy wrapper around the Mercure process, handling the setting of the required environment variables before executing the process.

## Contents

- [Files](#files)                 : An overview of all files in this repository
- [Instructions](#instructions)   : Instructions on how to use the scripts in this repo

## Files

- `install.sh`                - Main installation script; used to install the Mercure server
- `mercure.sh`                - Wrapper for execution of the Mercure server; used to run the Mercure server
- `config/mercure.service`    - A service configuration file
- `config/$ENV/Caddyfile`     - Main configuration file for the Mercure Hub / Caddy server
- `config/$ENV/.env`          - Environment variables for the `mercure.service`
- `test/test-publish.sh`      - Used to manually send a publish request to the server (work in progress)
- `test/test-subscribe.sh`    - Used to manually send a subscribe request to the server (to be implemented)

## Instructions

This section will give some short instructions on how to use the files in this repository.

### Installation

Basic usage:

- `./install.sh [options]`

Available options can be found using:

- `./install.sh -h`

    or

- `./install.sh --help`

Details:

A Mercure (Caddyserver) can be configured using the files mentioned below. Note that there is also an option to use a `yaml` file, but the preferred/recommended way is using the following:

- Environment variables
- A so called `Caddyfile`; comparable to an Apache VHOST file

In the `config/dist` folder you can find example files: 

- A file with available environment variables: `.mercure.env`
- A `Caddyfile` with available options and links to resources for more info.

You can choose to edit one of the existing ones, and edit the values there:

- `config/prod/mercure.env`
- `config/prod/Caddyfile`
- run with `./install.sh` (since default env = '`prod`')

Or add a new one; for example `test`:

- create a new folder `config/test`
- create two files: `.mercure.env` and `Caddyfile`
- configure values as desired
- run with `./install.sh -e=test`



### Execution

Basic usage:

You could manually run the Mercure hub using:

- `mercure run --config=/path/to/Caddyfile`

However the preferred method (especially in production) is letting a processmanager, like Systemd or Supervisord manage the process for you.

Because of this, the installer will automatically setup a new service (`mercure.service`), which can be started with:

- `systemctl start mercure.service`

and stopped with

- `systemctl stop mercure.service`

By default this service will be enabled so that it starts on launch. If you would like to disable this, you can use:

- `systemctl disable mercure.service`

### Testing (development)

To run a docker container with a bind volume, run this in project root:

- `docker run -it --mount type=bind,src="$(pwd)",target=/src ubuntu bash`

Then run the following command to install prerequisites:

- `apt-get update && apt-get upgrade && apt-get install -y wget curl`

Then you can run the install script by going into src/ and running the script

- `cd src`
- `./install -vv`
