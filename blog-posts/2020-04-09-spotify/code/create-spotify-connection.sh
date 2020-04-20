#!/bin/bash

set -eo pipefail
declare -r DIR=$(dirname "${BASH_SOURCE[0]}")

command -v curl || { echo >&2 "error: curl not found"; exit 3; }
command -v base64 || { echo >&2 "error: base64 not found"; exit 3; }
command -v sed || { echo >&2 "error: sed not found"; exit 3; }
command -v jq || { echo >&2 "error: jq not found"; exit 3; }

function usage() {
    cat <<END >&2
USAGE: $0 [-a access_token] [-c spotify_client_id] [-x spotify_client_secret] [-e auth0-client] [-s fetch] [-v|-h]
        -a token    # management API access_token. default from environment variable access_token
        -c id       # spotify client_id
        -x secret   # spotify client_secret
        -s file     # fetchUserProfile.js JS file. default is 'fetchUserProfile.js'
        -D          # dry-run, interpolate only
        -h|?        # usage
        -v          # verbose
eg,
     $0 -c 6e57bb4631fe47f6be27af4ff2bf7489 -x XXXXX -e 1C39ZFp1MrRkRtTY7vlxFjvJLCheoMZm
END
    exit $1
}

declare client_id=''
declare client_secret=''
declare enabled_client=''

declare fetch_file="${DIR}/fetchUserProfile.js"
declare dry_run=0

while getopts "a:d:c:x:e:s:Dhv?" opt
do
    case ${opt} in
        a) access_token=${OPTARG};;
        c) client_id=${OPTARG};;
        x) client_secret=${OPTARG};;
        e) enabled_client=${OPTARG};;
        s) fetch_file=${OPTARG};;
        v) opt_verbose=1;; #set -x;;
        D) dry_run=1;;
        h|?) usage 0;;
        *) usage 1;;
    esac
done

[[ -z "${fetch_file}" ]] && { echo >&2 "ERROR: fetch_file undefined."; usage 1; }
[[ -z "${client_id}" ]] && { echo >&2 "ERROR: client_id undefined."; usage 1; }
[[ -z "${client_secret}" ]] && { echo >&2 "ERROR: client_secret undefined."; usage 1; }
[[ -z "${enabled_client}" ]] && { echo >&2 "ERROR: enabled_client undefined."; usage 1; }
[[ -f "${fetch_file}" ]] || { echo >&2 "ERROR: fetch_file missing: ${fetch_file}"; usage 1; }

declare -r script_single_line=$(sed 's|\\|\\\\|g;s/$/\\n/g' "${fetch_file}" | tr -d '\n' )

declare BODY=$(cat << EOL
{
  "name": "spotify",
  "strategy": "oauth2",
  "is_domain_connection": true,
  "options": {
    "client_id": "${client_id}",
    "client_secret": "${client_secret}",
    "scripts": {
        "fetchUserProfile": "${script_single_line}"
    },
    "authorizationURL": "https://accounts.spotify.com/authorize",
    "tokenURL": "https://accounts.spotify.com/api/token",
    "scope": "user-read-email",
    "customHeaders": {
    }
  },
  "enabled_clients": [
     "${enabled_client}"
  ]
}
EOL
)

[[ ${dry_run} -eq 1  ]] && { echo "${BODY}"; exit 0; }

[[ -z "${access_token}" ]] && { echo >&2 "ERROR: access_token undefined. export access_token='PASTE' "; usage 1; }
declare -r AUTH0_DOMAIN_URL=$(echo "${access_token}" | awk -F. '{print $2}' | base64 -di 2>/dev/null | jq -r '.iss')

curl --request POST \
    -H "Authorization: Bearer ${access_token}" \
    --url "${AUTH0_DOMAIN_URL}api/v2/connections" \
    --header 'content-type: application/json' \
    -d "${BODY}"
