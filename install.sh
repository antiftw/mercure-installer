#!/bin/bash
#
# This script is used to install the Mercure server.
#
# Usage:
#   ./install.sh [options]
#
# Options can be found by using install.sh --help
#
# Default will:
# - Install the latest [ x86_64 Linux ] version of Mercure into /usr/sbin/mercure
# - Use [ /etc/mercure ] as config directory
# - Use [ PROD ] as environment, meaning it will copy the Caddyfile from config/Caddyfile
#
# Note: This script must be run as root

exit_error() {
    RED='\033[0;31m' # Red
    NC='\033[0m' # No Color
    printf "\n$RED ERROR $NC: $1\n\n" >&2
    exit 1
}

generateLink() {
    local VERSION=$1
    local ARCHITECTURE=$2
    local OS=$3
    
    # Uppercase first letter of OS
    OS="$(tr '[:lower:]' '[:upper:]' <<< ${OS:0:1})${OS:1}"
    
    FILENAME="mercure_${VERSION}_${OS}_${ARCHITECTURE}"
    LINK="https://github.com/dunglas/mercure/releases/download/v$VERSION/$FILENAME.tar.gz"
    echo "$LINK"
}

# Get arguments
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            echo ""
            echo "This script is used to download and setup the Mercure server."
            echo ""
            echo "Usage:"
            echo "  $0 [options]"
            echo ""
            echo "Options:"
            echo "  -h, --help                  Show this help message and exit"
            echo "  -v, --version=<x.y.z>       Choose specific version to install, e.g. -v=0.14.10"
            echo ""
            echo "  -a, --architecture=<amd64>  Choose specific architecture to install, e.g. -a=x86_64"
            echo "                              Allowed values:"
            echo "                                - x86_64 (default)"
            echo "                                - i386"
            echo "                                - arm64, arm5, arm6, arm7"
            echo "                              (Note: Only x86_64 and arm64 are available for darwin)"
            echo ""
            echo "  -o, --os=<linux>            Choose specific OS to install, e.g. -o=linux"
            echo "                              Allowed values:"
            echo "                                - linux (default)"
            echo "                                - windows"
            echo "                                - darwin (for MacOS users)"
            echo ""
            exit 0
            ;;
        -a=*|--architecture=*)
            ARCHITECTURE="${arg#*=}"
            ;;
        -c=*|--config-direcory=*)
            CONFIG_DIRECTORY="${arg#*=}"
            ;;
        -e=*|--environment=*)
            ENVIRONMENT="${arg#*=}"
            ;;
        -v=*|--version=*)
            VERSION="${arg#*=}"
            ;;
        -o=*|--os=*)
            OS="${arg#*=}"
            ;;
        *)
            exit_error "Unknown argument: $arg, use --help for more information"
            ;;
    esac
done

# Check if script is run as root
if [ "$(id -u)" != "0" ]; then
    exit_error "Must run as root"
fi

OS=${OS:-"linux"}
ARCHITECTURE=${ARCHITECTURE:-"x86_64"}
CONFIG_DIRECTORY=${CONFIG_DIRECTORY:-"/etc/mercure"}
ENVIRONMENT=${ENVIRONMENT:-"PROD"}
SCRIPT_DIR="$PWD"

# Find latest version if not specified
if [ -z "$VERSION" ]; then
    VERSION=$(curl -s https://api.github.com/repos/dunglas/mercure/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    # Remove the "v" prefix
    VERSION="${VERSION:1}"
fi

DOWNLOAD_LINK=$(generateLink "$VERSION" "$ARCHITECTURE" "$OS")
echo "$DOWNLOAD_LINK"

# Download and extract mercure
wget -O mercure.tar.gz "$DOWNLOAD_LINK"
MERCURE_UNTAR_DIR="$PWD/mercure"
mkdir -p "$MERCURE_UNTAR_DIR"
tar -xzf mercure.tar.gz -C "$MERCURE_UNTAR_DIR"

cd "$MERCURE_UNTAR_DIR" || exit_error "Could not cd into $MERCURE_UNTAR_DIR"

# Move mercure binary to /usr/sbin
mv mercure /usr/sbin/mercure

# Create config directory
mkdir -p "$CONFIG_DIRECTORY"

if [ "$ENVIRONMENT" == "PROD" ]; then
    cp "$PWD/config/Caddyfile" "$CONFIG_DIRECTORY/Caddyfile"
elif [ "$ENVIRONMENT" == "DEV" ]; then
    cp "$PWD/config/Caddyfile.dev" "$CONFIG_DIRECTORY/Caddyfile"
elif [ "$ENVIRONMENT" == "TEST" ]; then
    cp "$PWD/config/Caddyfile.test" "$CONFIG_DIRECTORY/Caddyfile"
else
    exit_error "Unknown environment: $ENVIRONMENT, use --help for more information"
fi

if [ "$OS" == "Linux" ]; then
    # Install supervisor to manage Mercure process
    apt-get install -y supervisor

    # Copy supervisor worker file
    cp "$PWD/config/mercure.conf" /etc/supervisor/conf.d/mercure.conf

    # Copy mercure.sh to /usr/sbin
    cp "$SCRIPT_DIR/mercure.sh" /usr/sbin/mercure.sh

    # Create log directory
    mkdir -p /var/log/mercure

    # Load new supervisor config
    supervisor reread && supervisor update

    # Start mercure process
    supervisorctl start mercure:mercure_0
else
    printf "\n\n"
    echo "WARNING: Since you are not installing this on a Linux Machine,"
    echo "         this script has not installed supervisor on your system."
    echo "         You should setup something to manage the Mercure process,"
    echo "         or manually start it (not recommended)."
    echo "         The following script can be used to start the Mercure server:"
    echo ""
    echo "         mercure.sh"
    echo ""
    echo "         Which is included in this repository."
    printf "\n\n"
fi