#!/bin/bash
# This script is used to start the Mercure server.
#
# Usage:
#   ./mercure.sh [options]
#
# Options can be found by using mercure.sh --help
# 
# Default will:
# - Use [ /etc/mercure ] as config directory 
# - Use [ /etc/mercure ] as the home directory
# - Use [ /var/www/antiftw ] for the web root
# - Use [ /etc/mercure/Caddyfile ] for the Caddyfile file location
# - Use [ localhost:3333 ] as the server address 
# - Use [ * ] for the CORS domains, allowing all domains
# - Use [ * ] for the Publish domains, allowing all domains
# - Use [ RS256 ] for the publish algorithm
# - Use [ RS256 ] for the subscribe algorithm
# - Use a [ Symfony public key generated with LexikJWTAuthenticationBundle ] for the Publisher
# - Use a [ Symfony public key generated with LexikJWTAuthenticationBundle ] for the Subscriber
#
# Note: This script must be run as root

exit_error() {
    RED='\033[0;31m' # Red
    NC='\033[0m' # No Color
    printf "\n$RED ERROR $NC: $1\n\n" >&2
    exit 1
}

get_key(){
    local KEYFILE=$1
    if [[ -z "$KEYFILE" ]]; then
        # If no key is passed, default to Symfony key
        KEYFILE="$WEB_ROOT/config/jwt/public.pem"
        if  [[ -f "$KEYFILE" ]]; then 
            # If key is a file and exists, read it
            KEY="$(cat $WEB_ROOT/config/jwt/public.pem)"
        else 
            # If key is file but does not exist, exit error
            exit_error "Keyfile [ $KEYFILE ] does not exist or is not readable."
        fi 
    elif [[ -f "$KEYFILE" ]] && [[ "$KEYFILE" =~ "\/" ]]; then
        # If key is a file and exists, read it
        KEY="$(cat $KEYFILE)"
    elif [[ "$KEYFILE" =~ "\/" ]]; then
        # If key is file but does not exist, exit error
        exit_error "Keyfile [ $KEYFILE ] does not exist or is not readable."
    else
        # If key is not a file, use it as is
        KEY="$KEYFILE"
    fi
    echo "$KEY"
}

# Get arguments
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            echo ""
            echo "This script is used to start the Mercure server."
            echo ""
            echo "Usage:"
            echo "  $0 [options]"
            echo ""
            echo "Options:"
            echo ""
            echo "  -c, --config-directory=<DIRECTORY>      Set direcotry for the Caddyfile and other config files"
            echo "                                          (default: /etc/mercure)"
            echo ""
            echo "  -cf, --caddy-file=<FILE>                Set Caddyfile, e.g. -cf=/etc/mercure/Caddyfile" 
            echo "                                          (default: <CONFIG_DIR>/Caddyfile)"
            echo "  -hd, --home-directory=<DIRECTORY>       Set home directory for the Mercure server"
            echo "                                          (default: /etc/mercure)"
            echo ""
            echo "  -cd, --cors-domains=<DOMAINS>          Set CORS domains, e.g. -cd=https://example.com"
            echo "                                          (default: * (allow all domains))"
            echo "                                          (Note: Multiple domains can be set by separating them with a comma)" 
            echo ""
            echo "  -m, --mercure-path=<PATH>               Set path to the Mercure binary, e.g. -m=/usr/sbin/mercure"
            echo "                                          (default: /usr/sbin/mercure)"
            echo ""
            echo "  -pd, --publish-domains=<DOMAINS>        Set publish domains, e.g. -pd=https://example.com"
            echo "                                          (default: * (allow all domains))"
            echo "                                          (Note: Multiple domains can be set by separating them with a comma)"
            echo ""
            echo "  -pk, --publish-key=<KEY>                Set publish key, allowed values:"
            echo "                                             - <PATH_TO_KEY> (e.g. -pk=/var/www/antiftw/config/jwt/public.pem)"
            echo "                                             - <RAW_KEY> (e.g. -pk=\"-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----\""
            echo "                                          (Note: When using RSHA: This is the public key of the JWT)"
            echo ""
            echo "  -sk, --subscribe-key=<KEY>              Set subscribe key, allowed values:"
            echo "                                             - <PATH_TO_KEY> (e.g. -pk=/var/www/antiftw/config/jwt/public.pem)"
            echo "                                             - <RAW_KEY> (e.g. -pk=\"-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----\""
            echo "                                          (Note: When using RSHA: This is the public key of the JWT)"
            echo ""
            echo "  -pa, --publish-alg=<ALG>                Set publish algorithm, e.g. -pa=RS256"
            echo "                                          (default: RS256)"
            ehco "                                          Allowed values: RS256, RS384, RS512, HS256, HS384, HS512"
            echo ""
            echo "  -sa, --subscribe-alg=<ALG>              Set subscribe algorithm, e.g. -sa=RS256"
            echo "                                          (default: RS256)"
            ehco "                                          Allowed values: RS256, RS384, RS512, HS256, HS384, HS512"
            echo ""
            echo "  -wr, --web-root=<DIRECTORY>             Set web root directory, e.g. -wr=/var/www/antiftw"
            echo "                                          (default: /var/www/antiftw)"
            echo ""
            echo "  -h, --help                              Show this help message and exit"
            echo ""
            exit 0
            ;;
        -a=*|--address=*)
            SERVER_ADDRESS="${arg#*=}"
            ;;
        -c=*|--config-direcory=*)
            CONFIG_DIR="${arg#*=}"
            ;;
       
        m=*|--mercure-path=*)
            MERCURE_PATH="${arg#*=}"
            ;;
        -cf=*|--caddy-file=*)
            CADDYFILE="${arg#*=}"
            ;;
        -hd|--directory=*)
            HOME_DIR="${arg#*=}"
            ;;
        -cd=*|--cors-domains=*)
            CORS_DOMAINS="${arg#*=}"
            ;;
        -pd=*|--publish-domains=*)
            PUBLISH_DOMAINS="${arg#*=}"
            ;;
        -pa=*|--publish-alg=*)
            PUBLISH_ALG="${arg#*=}"
            ;;
        -pk=*|--publish-key=*)
            PUBLISH_KEYFILE="${arg#*=}"
            ;;        
        -sa=*|--subscribe-alg=*)
            SUBSCRIBE_ALG="${arg#*=}"
            ;;
        -sk=*|--subscribe-key=*)
            SUBSCRIBE_KEYFILE="${arg#*=}"
            ;;
        -wr=*|--web-root=*)
            WEB_ROOT="${arg#*=}"
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

SERVER_ADDRESS=${SERVER_ADDRESS:-"localhost:3333"}

# Default to /etc/mercure for the config and data directories
HOME_DIR=${HOME_DIR:-"/etc/mercure"}
CONFIG_DIR=${CONFIG_DIR:-"/etc/mercure"}

# Default to /etc/mercure/Caddyfile for the Caddyfile (config file)
CADDYFILE=${CADDYFILE:-"$CONFIG_DIR/Caddyfile"}

# Default to Symfony root, only used when PUB/SUB keys are not set
WEB_ROOT=${WEB_ROOT:-"/var/www/antiftw"}

# Path where Mercure is installed
MERCURE_PATH=${MERCURE_PATH:-"/usr/sbin/mercure"}

# Get keys
PUBLISH_KEY="$(get_key $PUBLISH_KEYFILE)"
SUBSCRIBE_KEY="$(get_key $SUBSCRIBE_KEYFILE)"

# Use RS256 by default (RSA SHA-256)
PUBLISH_ALG=${PUBLISH_ALG:-"RS256"}
SUBSCRIBE_ALG=${SUBSCRIBE_ALG:-"RS256"}

# Allow all domains by default
CORS_DOMAINS=${CORS_DOMAINS:-"*"}
PUBLISH_DOMAINS=${PUBLISH_DOMAINS:-"*"}

# Start Mercure using the determined values
MERCURE_PUBLISHER_JWT_KEY="$PUBLISH_KEY" \
MERCURE_PUBLISHER_JWT_ALG="$PUBLISH_ALG" \
MERCURE_SUBSCRIBER_JWT_KEY="$SUBSCRIBE_KEY" \
MERCURE_SUBSCRIBER_JWT_ALG="$SUBSCRIBE_ALG" \
SERVER_NAME=$SERVER_ADDRESS \
MERCURE_CORS_ORIGINS="$CORS_DOMAINS" \
MERCURE_PUBLISHER_ORIGINS="$PUBLISH_DOMAINS" \
XDG_CONFIG_HOME="$CONFIG_DIR" \
HOME="$HOME_DIR" \
"$MERCURE_PATH" run --config "$CADDYFILE"

