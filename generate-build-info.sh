#!/bin/bash

# This script generates a build information file.

GIT_COMMIT=$(git rev-parse --short HEAD)
BUILD_DATE=$(date)
GIT_USER=$(git config user.name)

BUILD_INFO="Commit: $GIT_COMMIT
Date: $BUILD_DATE
User: $GIT_USER"

echo "$BUILD_INFO" > airootfs/etc/acreetion-build
