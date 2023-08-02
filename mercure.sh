#!/bin/bash
# This script is used to start the Mercure server.
#
# Usage:
#
#   ./mercure.sh [options]
#
# Options can be found by using mercure.sh --help
#
# Default will:
# - Use [ /etc/mercure ] as config directory
# - Use [ /etc/mercure ] as the home directory
# - Use [ /var/www/antiftw ] for the web root
# - Use [ /etc/mercure/Caddyfile ] for the Caddyfile file location
# - Use [ /usr/local/bin/mercure ] for the Mercure binary location
# - Use [ :3333 ] as the server address
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
    [[ "$VERBOSE" -ge 1 ]] && echo "Getting key from $KEYFILE"

    if [[ "$KEYFILE" =~ "/" ]] && [[ -f "$KEYFILE" ]]; then
        # If key is a file and exists, read it
        [[ "$VERBOSE" -ge 1 ]] && echo "Keyfile [ $KEYFILE ] exists, using it"
        KEY="$(cat $KEYFILE)"

    elif [[ "$KEYFILE" =~ "/" ]]; then
        # If key is file but does not exist, exit error
        exit_error "Keyfile [ $KEYFILE ] does not exist or is not readable."

    else
        # If key is not a file, use it as is
        [[ "$VERBOSE" -ge 1 ]] && echo "Keyfile [ $KEYFILE ] is not a file, key-data provided as is"
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
            echo "  -c, --config-directory=<PATH>      Set direcotry for the Caddyfile and other config files"
            echo "                                     (default: /etc/mercure)"
            echo ""
            echo "  -cf, --caddy-file=<FILE>           Set Caddyfile, e.g. -cf=/etc/mercure/Caddyfile" 
            echo "                                     default: <CONFIG_DIR>/Caddyfile)"
            echo "  -hd, --home-directory=<PATH>       Set home directory for the Mercure server"
            echo "                                     (default: /etc/mercure)"
            echo ""
            echo "  -cd, --cors-domains=<DOMAINS>      Set CORS domains, e.g. -cd=https://example.com"
            echo "                                     (default: * (allow all domains))"
            echo "                                     (Note: Multiple domains can be set by separating them with a comma)" 
            echo ""
            echo "  -m, --mercure-path=<PATH>          Set path to the Mercure binary, e.g. -m=/usr/local/bin/mercure"
            echo "                                     (default: /usr/local/bin/mercure)"
            echo ""
            echo "  -pd, --publish-domains=<DOMAINS>   Set publish domains, e.g. -pd=https://example.com"
            echo "                                     (default: * (allow all domains))"
            echo "                                     (Note: Multiple domains can be set by separating them with a comma)"
            echo ""
            echo "  -pk, --publish-key=<KEY>           Set publish key, allowed values:"
            echo "                                      - <PATH_TO_KEY> (e.g. -pk=/var/www/antiftw/config/jwt/public.pem)"
            echo "                                      - <RAW_KEY> (e.g. -pk=\"-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----\""
            echo "                                     (Note: When using RSHA: This is the public key of the JWT)"
            echo ""
            echo "  -sk, --subscribe-key=<KEY>         Set subscribe key, allowed values:"
            echo "                                      - <PATH_TO_KEY> (e.g. -pk=/var/www/antiftw/config/jwt/public.pem)"
            echo "                                      - <RAW_KEY> (e.g. -pk=\"-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----\""
            echo "                                     (Note: When using RSHA: This is the public key of the JWT)"
            echo ""
            echo "  -pa, --publish-alg=<ALG>           Set publish algorithm, e.g. -pa=RS256"
            echo "                                     (default: RS256)"
            echo "                                     Allowed values: RS256, RS384, RS512, HS256, HS384, HS512"
            echo ""
            echo "  -sa, --subscribe-alg=<ALG>         Set subscribe algorithm, e.g. -sa=RS256"
            echo "                                     (default: RS256)"
            echo "                                     Allowed values: RS256, RS384, RS512, HS256, HS384, HS512"
            echo ""
            echo " -t, --transport-url=<URL>           Set transport URL, e.g. -t=bolt:///etc/mercure/mercure.db"
            echo "                                     (default: bolt://<CONFIG_DIR>/mercure.db)"
            echo ""
            echo " -wr, --web-root=<PATH>              Set web root directory, e.g. -wr=/var/www/antiftw"
            echo "                                     (default: /var/www/antiftw)"
            echo ""
            echo " -h, --help                          Show this help message and exit"
            echo ""
            echo " -v, --verbose                       Enable verbose output"
            echo " -vv, --very-verbose                 Enable very verbose output"

            echo "Note: This script must be run as www-data"
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
        -t=*|--transport-url=*)
            TRANSPORT_URL="${arg#*=}"
            ;;
        -wr=*|--web-root=*)
            WEB_ROOT="${arg#*=}"
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

[[ "$VERBOSE" -ge 1 ]] && echo "\n\n==========================================\n\n"
[[ "$VERBOSE" -ge 1 ]] && echo "Initializing environment variables..."

SERVER_ADDRESS=${SERVER_ADDRESS:-":3333"}

# Default to /etc/mercure for the config and data directories
HOME_DIR=${HOME_DIR:-"/etc/mercure"}
CONFIG_DIR=${CONFIG_DIR:-"/etc/mercure"}

# Default to /etc/mercure/Caddyfile for the Caddyfile (config file)
CADDYFILE=${CADDYFILE:-"$CONFIG_DIR/Caddyfile"}

# Default to Symfony root, only used when PUB/SUB keys are not set
WEB_ROOT=${WEB_ROOT:-"/var/www/antiftw"}

# Path where Mercure is installed
MERCURE_PATH=${MERCURE_PATH:-"/usr/local/bin/mercure"}

# Default to Symfony public key, only used when PUB/SUB keys are not set
PUBLISH_KEYFILE=${PUBLISH_KEYFILE:-"$WEB_ROOT/config/jwt/public.pem"}
SUBSCRIBE_KEYFILE=${SUBSCRIBE_KEYFILE:-"$WEB_ROOT/config/jwt/public.pem"}

# Get keys
PUBLISH_KEY="$(get_key $PUBLISH_KEYFILE $WEB_ROOT)"
SUBSCRIBE_KEY="$(get_key $SUBSCRIBE_KEYFILE $WEB_ROOT)"

# Use RS256 by default (RSA SHA-256)
PUBLISH_ALG=${PUBLISH_ALG:-"RS256"}
SUBSCRIBE_ALG=${SUBSCRIBE_ALG:-"RS256"}

# Allow all domains by default
CORS_DOMAINS=${CORS_DOMAINS:-"*"}
PUBLISH_DOMAINS=${PUBLISH_DOMAINS:-"*"}

TRANSPORT_URL=${TRANSPORT_URL:-"bolt://$CONFIG_DIR/mercure.db"}

[[ "$VERBOSE" -ge 1 ]] && echo "Done initializing environment variables:"
[[ "$VERBOSE" -ge 1 ]] && echo ""

if [ "$VERBOSE" -ge 2 ]; then
    # Print all variables
    echo "SERVER_ADDRESS: $SERVER_ADDRESS"
    echo "HOME_DIR: $HOME_DIR"
    echo "CONFIG_DIR: $CONFIG_DIR"
    echo "CADDYFILE: $CADDYFILE"
    echo "WEB_ROOT: $WEB_ROOT"
    echo "MERCURE_PATH: $MERCURE_PATH"
    echo "PUBLISH_KEYFILE: $PUBLISH_KEYFILE"
    echo "PUBLISH_KEY: $PUBLISH_KEY"
    echo "SUBSCRIBE_KEYFILE: $SUBSCRIBE_KEYFILE"
    echo "SUBSCRIBE_KEY: $SUBSCRIBE_KEY"
    echo "PUBLISH_ALG: $PUBLISH_ALG"
    echo "SUBSCRIBE_ALG: $SUBSCRIBE_ALG"
    echo "CORS_DOMAINS: $CORS_DOMAINS"
    echo "PUBLISH_DOMAINS: $PUBLISH_DOMAINS"
    echo "TRANSPORT_URL: $TRANSPORT_URL"
fi

[[ "$VERBOSE" -ge 1 ]] && echo "Starting Mercure server..."

# Start Mercure using the determined values
MERCURE_PUBLISHER_JWT_KEY="$PUBLISH_KEY" \
MERCURE_PUBLISHER_JWT_ALG="$PUBLISH_ALG" \
MERCURE_SUBSCRIBER_JWT_KEY="$SUBSCRIBE_KEY" \
MERCURE_SUBSCRIBER_JWT_ALG="$SUBSCRIBE_ALG" \
MERCURE_SERVER_NAME=$SERVER_ADDRESS \
MERCURE_CORS_ORIGINS="$CORS_DOMAINS" \
MERCURE_PUBLISHER_ORIGINS="$PUBLISH_DOMAINS" \
XDG_CONFIG_HOME="$CONFIG_DIR" \
HOME="$HOME_DIR" \
MERCURE_TRANSPORT_URL="$TRANSPORT_URL" \
"$MERCURE_PATH" run --config "$CADDYFILE"
