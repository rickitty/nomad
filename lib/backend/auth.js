function getBearerToken(req) {
  const auth = req.headers.authorization;
  if (auth && auth.startsWith('Bearer ')) {
    return auth.substring('Bearer '.length);
  }
  if (req.body && req.body.token) {
    return req.body.token;
  }
  return null;
}

module.exports = { getBearerToken };
