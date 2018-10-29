# Heroku Buildpack for EJSON [![Build Status](https://travis-ci.org/envato/heroku-buildpack-ejson.svg?branch=master)](https://travis-ci.org/envato/heroku-buildpack-ejson)

This is a [Heroku Buildback](http://devcenter.heroku.com/articles/buildpacks) that automates the decryption of
[EJSON](https://github.com/Shopify/ejson) secrets on deploy.

It's a fork of [Shopify's EJSON buildpack](https://github.com/Shopify/ejson) that exports secrets as environment
variables on application start rather than writing to a JSON file when the slug is compiled. This avoids storing
an unencrypted secrets file on disk and allows apps to continue fetching secrets from environment variables.

## Keys

EJSON files are encrypted via a public-key cryptography scheme, the intention being that the non-secret public key
can safely be stored on developer machines and in source control, whereas the sensitive private key can be scoped
only to production infrastructure.

## Getting started with EJSON

Install EJSON with `gem install ejson`.

Generate an EJSON keypair with `ejson keygen`.

```bash
❯ ejson keygen
Public Key:
d437b2159cbf18a9e36fc1aa7a3007ea2b2ea5c0c2878d7101ad740c81418b55
Private Key:
24a4a88328317f80bd74ee80d6fe298ae6e9d02361d818c068dfd445b686098e
```

Create an EJSON file `secrets.ejson` using the public key and add your first secret:

```json
{
  "_public_key": "d437b2159cbf18a9e36fc1aa7a3007ea2b2ea5c0c2878d7101ad740c81418b55",
  "SOME_API_KEY": "password"
}
```

Do no commit this file to source control at this stage. The value is still unencrypted. Use EJSON to encrypt it:

```bash
❯ ejson encrypt secrets.ejson
Wrote %d bytes to %s.
225secrets.ejson
```

Now the file can be safely committed and deployed.

## Deployment to Heroku

Add the following environment variables to your heroku app's config:

```
heroku config:set \
  EJSON_FILE=secrets.ejson \
  EJSON_PRIVATE_KEY=24a4a88328317f80bd74ee80d6fe298ae6e9d02361d818c068dfd445b686098e
```

Add this Heroku buildpack:

```
❯ heroku buildpacks:set https://github.com/envato/heroku-buildpack-ejson.git
```

On application start, it will use those 2 environment variables to decrypt the ejson file and export the secrets
as environment variables.

## Decrypting secrets

Use the Heroku CLI to pipe the private key into ejson for decryption:

```
❯ heroku config:get EJSON_PRIVATE_KEY | ejson decrypt --key-from-stdin secrets.ejson
{
  "_public_key": "d437b2159cbf18a9e36fc1aa7a3007ea2b2ea5c0c2878d7101ad740c81418b55",
  "SOME_API_KEY": "password"
}
```
