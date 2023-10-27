#!/bin/sh

VERSIONS="$@"

if [ ! -z "$GH_TOKEN" ]; then
	tokenarg="--build-arg GH_TOKEN=$GH_TOKEN"
fi
docker build --platform=$PLATFORM $tokenarg --build-arg "VERSIONS=$VERSIONS" .
