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

      //console.log('profile from spotify: ' + JSON.stringify(profile));
      cb(null, profile);
    },
  );
}
