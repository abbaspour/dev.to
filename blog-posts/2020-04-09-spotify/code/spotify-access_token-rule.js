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
