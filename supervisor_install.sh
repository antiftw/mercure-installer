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
# - Install the latest [ x86_64 Linux ] version of Mercure into /usr/local/bin/mercure
# - Use [ /etc/mercure ] as config directory
# - Use [ PROD ] as environment, meaning it will copy the Caddyfile from config/Caddyfile
#
# Note: This script must be run as root

RED='\033[31m' # Red
GREEN='\033[32m' # Green
NC='\033[0m' # No Color

exit_error() {
    printf "\n$RED ERROR $NC: $1\n\n" >&2
    exit 1
}

handle_return() {
    local RETURN_CODE=$1
    local MESSAGE=$2

    MESSAGE=${MESSAGE:-"Unknown error occurred"}
    if [ "$RETURN_CODE" -eq 0 ]; then
        printf "$GREEN✔️$NC\n"
    else
        printf "❌\n"
        exit_error "$MESSAGE"
    fi
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
            echo "  -ver, --version=<x.y.z>     Choose specific version to install, e.g. -v=0.14.10"
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
            echo " -v, --verbose                Enable verbose output"
            echo " -vv, --very-verbose          Enable very verbose output"
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
        -o=*|--os=*)
            OS="${arg#*=}"
            ;;
        -u=*|--user=*)
            USER="${arg#*=}"
            ;;
        -ver=*|--version=*)
            VERSION="${arg#*=}"
            ;;
        -v|--verbose)
            VERBOSE=1
            ;;
        -vv|--very-verbose)
            VERBOSE=2
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

VERBOSE=${VERBOSE:-0}
OS=${OS:-"linux"}
ARCHITECTURE=${ARCHITECTURE:-"x86_64"}
CONFIG_DIRECTORY=${CONFIG_DIRECTORY:-"/etc/mercure"}
ENVIRONMENT=${ENVIRONMENT:-"PROD"}
SCRIPT_DIR="$PWD"
USER=${USER:-"antiftw"}

if [ "$VERBOSE" -ge 2 ]; then
    # Print Arguments
    echo "Arguments passed:"
    echo "  - Architecture: $ARCHITECTURE"
    echo "  - OS: $OS"
    echo "  - Version: $VERSION"
    echo "  - Config directory: $CONFIG_DIRECTORY"
    echo "  - Environment: $ENVIRONMENT"
    echo ""
fi

[ "$VERBOSE" -ge 1 ] && echo "Mercure Installer Initializing..."
# Find latest version if not specified
if [ -z "$VERSION" ]; then
    [ "$VERBOSE" -ge 1 ] && printf "No version given, determining latest version..."
    VERSION=$(curl -s https://api.github.com/repos/dunglas/mercure/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")'); RETURN_CODE=$?
    [ "$VERBOSE" -ge 1 ] && handle_return "$RETURN_CODE" "Could not determine latest version"
    # Remove the "v" prefix
    VERSION="${VERSION:1}"
    [ "$VERBOSE" -ge 1 ] && printf "Latest version is $VERSION\n"
fi

# Download and extract mercure
DOWNLOAD_LINK=$(generateLink "$VERSION" "$ARCHITECTURE" "$OS")
[ "$VERBOSE" -ge 1 ] && echo "Downloading Mercure from $DOWNLOAD_LINK..."
wget -q --show-progress -O mercure.tar.gz "$DOWNLOAD_LINK"

# Extract mercure
[ "$VERBOSE" -ge 1 ] && printf "Extracting Mercure..."
MERCURE_TAR_FILE="$PWD/mercure.tar.gz"
MERCURE_UNTAR_DIR="$PWD/mercure"

mkdir -p "$MERCURE_UNTAR_DIR"
tar -xzf "$MERCURE_TAR_FILE" -C "$MERCURE_UNTAR_DIR"; RETURN_CODE=$?
[ "$VERBOSE" -ge 1 ] && handle_return "$RETURN_CODE" "Could not extract Mercure"

cd "$MERCURE_UNTAR_DIR" || exit_error "Could not cd into $MERCURE_UNTAR_DIR"

# Move mercure binary to /usr/local/bin
BINARY_DIRECTORY="/usr/local/bin"
[ "$VERBOSE" -ge 1 ] && printf "Moving Mercure binary to $BINARY_DIRECTORY" 
mv mercure $BINARY_DIRECTORY; RETURN_CODE=$?
[ "$VERBOSE" -ge 1 ] && handle_return "$RETURN_CODE" "Could not move mercure binary to $BINARY_DIRECTORY"

# Create config directory
[ "$VERBOSE" -ge 1 ] && printf "Creating config directory $CONFIG_DIRECTORY"
mkdir -p "$CONFIG_DIRECTORY"; RETURN_CODE_1=$?
chown $USER:www-data "$CONFIG_DIRECTORY"; RETURN_CODE_2=$?
chmod 775 "$CONFIG_DIRECTORY"; RETURN_CODE_3=$?
RETURN_CODE=$((RETURN_CODE_1 + RETURN_CODE_2 + RETURN_CODE_3))
[ "$VERBOSE" -ge 1 ] && handle_return "$RETURN_CODE" "Could not create config directory $CONFIG_DIRECTORY"

# Copy Caddyfile
[ "$VERBOSE" -ge 1 ] && printf "Copying Caddyfile..."
if [ "$ENVIRONMENT" == "PROD" ]; then
    cp "$SCRIPT_DIR/config/Caddyfile" "$CONFIG_DIRECTORY/Caddyfile"; RETURN_CODE=$?
elif [ "$ENVIRONMENT" == "DEV" ]; then
    cp "$SCRIPT_DIR/config/Caddyfile.dev" "$CONFIG_DIRECTORY/Caddyfile"; RETURN_CODE=$?
elif [ "$ENVIRONMENT" == "TEST" ]; then
    cp "$SCRIPT_DIR/config/Caddyfile.test" "$CONFIG_DIRECTORY/Caddyfile"; RETURN_CODE=$?
else
    exit_error "Unknown environment: $ENVIRONMENT, use --help for more information"
fi
[ "$VERBOSE" -ge 1 ] && handle_return "$RETURN_CODE" "Could not copy Caddyfile"

# Create database file
[ "$VERBOSE" -ge 1 ] && printf "Creating database file..."
DATABASE_FILE="$CONFIG_DIRECTORY/mercure.db"
touch "$DATABASE_FILE"; RETURN_CODE_1=$?
chown $USER:www-data "$DATABASE_FILE"; RETURN_CODE_2=$?
RETURN_CODE=$((RETURN_CODE_1 + RETURN_CODE_2))
[ "$VERBOSE" -ge 1 ] && handle_return "$RETURN_CODE" "Could not create database file"

# Cleanup downloaded files
[ "$VERBOSE" -ge 1 ] && printf "Cleaning up..."
rm -f "$MERCURE_TAR_FILE"; RETURN_CODE_1=$?
rm -rf "$MERCURE_UNTAR_DIR"; RETURN_CODE_2=$?
RETURN_CODE=$((RETURN_CODE_1 + RETURN_CODE_2))
[ "$VERBOSE" -ge 1 ] && handle_return "$RETURN_CODE" "Error occurred while cleaning up"

if [ "$OS" == "linux" ]; then
    # Install supervisor to manage Mercure process
    [ "$VERBOSE" -ge 1 ] && printf "Installing supervisor..."
    apt-get install -qq supervisor; RETURN_CODE=$?
    [ "$VERBOSE" -ge 1 ] && handle_return "$RETURN_CODE" "Could not install supervisor"

    # Copy supervisor worker file
    [ "$VERBOSE" -ge 1 ] && printf "Copying supervisor config..."
    cp "$SCRIPT_DIR/config/mercure.conf" /etc/supervisor/conf.d/mercure.conf; RETURN_CODE=$?
    [ "$VERBOSE" -ge 1 ] && handle_return "$RETURN_CODE" "Could not copy supervisor config"

    # Copy mercure.sh to /usr/local/bin
    [ "$VERBOSE" -ge 1 ] && printf "Copying mercure.sh..."
    cp "$SCRIPT_DIR/mercure.sh" /usr/local/bin/mercure.sh; RETURN_CODE=$?
    [ "$VERBOSE" -ge 1 ] && handle_return "$RETURN_CODE" "Could not copy mercure.sh"

    # Create log directory
    [ "$VERBOSE" -ge 1 ] && printf "Creating log directory $LOG_DIRECTORY..."
    LOG_DIRECTORY="/var/log/mercure"
    mkdir -p "$LOG_DIRECTORY"; RETURN_CODE_1=$?
    chown $USER:www-data "$LOG_DIRECTORY"; RETURN_CODE_2=$?
    chmod 775 "$LOG_DIRECTORY"; RETURN_CODE_3=$?
    RETURN_CODE=$((RETURN_CODE_1 + RETURN_CODE_2 + RETURN_CODE_3))
    [ "$VERBOSE" -ge 1 ] && handle_return "$RETURN_CODE" "Could not create log directory $LOG_DIRECTORY"

    # Load new supervisor config
    [ "$VERBOSE" -ge 1 ] && printf "Loading supervisor config..."
    supervisorctl reread && supervisorctl update; RETURN_CODE=$?
    [ "$VERBOSE" -ge 1 ] && handle_return "$RETURN_CODE" "Could not load supervisor config"

    # Start mercure process
    [ "$VERBOSE" -ge 1 ] && printf "Starting mercure process..."
    supervisorctl start mercure:mercure_0; RETURN_CODE=$?
    [ "$VERBOSE" -ge 1 ] && handle_return "$RETURN_CODE" "Could not start mercure process"

    echo ""
    echo "Mercure has been installed and started using the default values."
    echo "You can now access the Mercure dashboard at:"
    echo ""
    echo "  http://localhost:3000/.well-known/mercure/ui/"
    echo ""
    echo "You can also start and stop the Mercure server by running:"
    echo ""
    echo "  supervisorctl start mercure:mercure_0"
    echo "  supervisorctl stop mercure:mercure_0"
    echo ""
    echo "To change the configuration, edit the following files:"
    echo ""
    echo "  /etc/mercure/Caddyfile"
    echo "  /etc/supervisor/conf.d/mercure.conf"
    echo ""
    echo "And restart the Mercure process by running:"
    echo ""
    echo "  supervisorctl reread && supervisorctl update"
    echo ""
    echo "However, it might be that Supervisor fails to stop the Mercure process."
    echo "In that case, you can kill the process manually by running:"
    echo ""
    echo "  kill \$(ps aux | grep '[m]ercure' | awk '{print \$2}')"
    echo ""
else
    echo ""
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

# Return success
exit 0;