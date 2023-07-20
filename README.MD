# Mercure Installer

## Contents

- [Files](#files)                 : An overview of all files in this repository
- [Instructions](#instructions)   : Instructions on how to use the scripts in this repo

## Files

- `install.sh`                - Main installation script; used to install the Mercure server
- `mercure.sh`                - Wrapper for execution of the Mercure server; used to run the Mercure server
- `config/Caddyfile`          - Main configuration file for the Mercure/Caddy server for a production environment
- `config/Caddyfile.dev`      - Main configuration file for the Mercure/Caddy server for a development environment
- `config/mercure.conf`       - Supervisor worker to manage the Mercure process
- `test/test-publish.sh`      - Used to manually send a publish request to the server (work in progress)
- `test/test-subscribe.sh`    - Used to manually send a subscribe request to the server (to be implemented)

## Instructions

This repository contains scripts to install and run the Mercure server based on the Caddy webserver onto your system. Its main goal is to install and configure the Mercure server automatically, and setting it up in such a way that it will automatically be managed by supervisor (on Linux).

However, you can also use the available `mercure.sh` script to run the server after having installed it manually due to the fact that all options are configurable.

### Installation

Basic usage:

-`./install.sh [options]`

Available options can be found using:

- `./install.sh -h`

    or

- `./install.sh --help`

### Execution

Basic usage:

- `./mercure.sh [options]`

Available options can be found using:

- `./mercure.sh -h`

    or

- `./mercure.sh --help`
