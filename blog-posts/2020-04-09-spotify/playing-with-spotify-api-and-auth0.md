---
published: false
title: 'Playing with Spotify API and Auth0'
cover_image: 'https://raw.githubusercontent.com/abbaspour/dev.to/master/blog-posts/2020-04-09-spotify/assets/auth0-spotify.png'
description: 'Connectivity between Spotify and Auth0'
tags: spotify, auth0, api, oauth2.0
series:
canonical_url:
---

## Registration

Head to https://developer.spotify.com/dashboard and create an app. Set callback URL to https://jwt.io

Reference https://developer.spotify.com/documentation/general/guides/authorization-guide/

## OAuth 2.0 Flow

### Implicit flow

```bash
git clone https://github.com/abbaspour/auth0-bash.git
cd auth0-bash/login
./authorize.sh -d https://accounts.spotify.com \
 -c 6e57bb4631fe47f6be27af4ff2bf7489 \
 -R token \
 -s user-read-email \
 -b firefox \
 -o
```

### Userinfo Endpoint

```bash
expert access_token='XXX'
curl -H "Authorization: Bearer ${access_token}" \
 https://api.spotify.com/v1/me
{
  "display_name" : "xxxx",
  "email" : "xxx@xxx.com",
  "external_urls" : {
    "spotify" : "https://open.spotify.com/user/xxx"
  },
  "followers" : {
    "href" : null,
    "total" : 0
  },
  "href" : "https://api.spotify.com/v1/users/xxx",
  "id" : "xxx",
  "images" : [ ],
  "type" : "user",
  "uri" : "spotify:user:xxxx"
}
```

### Authorization Code Flow

```bash
./authorize.sh -d https://accounts.spotify.com \
  -c 6e57bb4631fe47f6be27af4ff2bf7489 \
  -R code \
  -s user-read-email \
  -b firefox -o
```

### Exchange Code

```bash
export code='XXX'
export basic=$(printf "6e57bb4631fe47f6be27af4ff2bf7489:XXXX" | openssl base64 -e -A)
curl -H "Authorization: Basic ${basic}" \
 -d grant_type=authorization_code \
 -d code=${code} \
 -d redirect_uri=https%3A%2F%2Fjwt.io \
 https://accounts.spotify.com/api/token | jq .
```

### Refresh

```bash
export refresh_token='xxx'
curl -sS -H "Authorization: Basic ${basic}" \
 -d grant_type=refresh_token \
 -d refresh_token=${refresh_token} \
 https://accounts.spotify.com/api/token | jq .
```

## Auth0 Integration

![Auth0 + Spotify](https://dev-to-uploads.s3.amazonaws.com/i/r13aiazzbvujw7htifxo.png)

Let's add Spotofy as a custom social connection. Auth0 does the Authorization Code flow part. We need to supply endpoints and a `fetchUserProfile.js` script that does fetch user profile with an access token.

```js
// code/fetchUserProfile.js

(() => {
  function fetchUserProfile(accessToken, ctx, cb) {
    request.get(
      'https://api.spotify.com/v1/me',
      {
        headers: {
          Authorization: 'Bearer ' + accessToken,
          'User-Agent': 'Auth0',
        },
        timeout: 10000,
      },
      (e, r, b) => {
        if (e) return cb(e);
        if (r.statusCode !== 200) return cb(new Error('invalid status:' + r.statusCode));

        let info;
        try {
          info = JSON.parse(b);
        } catch (e) {
          return cb(new Error('invalid profile:'));
        }

        let profile = {
          user_id: info.id,
          name: info.display_name,
          nickname: info.id,
          app_metadata: {
            spotify_link: info.href,
          },
        };
        if (info.email) {
          profile.email = info.email;
          profile.email_verified = false;
        }
        if (!_.isEmpty(info.images)) profile.picture = _.head(profile.images);

        cb(null, profile);
      },
    );
  }
  return fetchUserProfile;
})()

```

We can now take that script and import it to Auth0 as a custom OAuth 2.0 connection using `create-spotify-connection.sh`:

---

**NOTE**

Make sure https://tenant.auth0.com/login/callback is registered as valid callback URL in your Spotify client.

---

```bash

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
        -a token    # access_token. default from environment variable
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
```

### Returning Spotify Access Token to Auth0 Client

Here we want to add Spotify `access_token` as a custom claim to Auth0 `id_token`. Note that Spotify access tokens expire in 1-hour. Hence we need silent authentication in Auth0 client to renew id_token and get a new Spotify access token every hour or so. That happens inside Auth0 rules:

```js
// code/spotify-access_token-rule.js

(() => {
  function renewSpotifyAccessToken(user, context, callback) {
    let spotify_identity = _.find(user.identities, { connection: 'spotify' });

    if (_.isUndefined(spotify_identity)) {
      console.log('no spotify_identity');
      return callback(null, user, context);
    }

    const namespace = 'https://my.ns/';

    let refresh_token = spotify_identity.refresh_token;
    let client_id = configuration.spotify_client_id;
    let client_secret = configuration.spotify_client_secret;

    const basic_auth = new Buffer(client_id + ':' + client_secret).toString('base64');
    request.post(
      'https://accounts.spotify.com/api/token',
      {
        headers: { authorization: 'basic ' + basic_auth },
        form: {
          grant_type: 'refresh_token',
          refresh_token: refresh_token,
        }
      },
      (err, r, b) => {
        if (err) {
          return console.log(err);
        }
        if (r.statusCode !== 200) return new Error('StatusCode: ' + r.statusCode);
        const info = JSON.parse(b);
        console.log(JSON.stringify(info, null, '  '));

        console.log('adding claim for spotify user: ' + spotify_identity.user_id);

        context.idToken[namespace + 'spotify/access_token'] = info.access_token;
        return callback(null, user, context);
      },
    );
  }
  return renewSpotifyAccessToken;
})()

```
