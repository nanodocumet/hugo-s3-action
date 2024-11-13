#!/bin/bash -l

set -eo pipefail

# Check configuration

err=0

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "error: AWS_ACCESS_KEY_ID is not set"
  err=1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "error: AWS_SECRET_ACCESS_KEY is not set"
  err=1
fi

if [ -z "$AWS_REGION" ]; then
  echo "error: AWS_REGION is not set"
  err=1
fi

if [ $err -eq 1 ]; then
  exit 1
fi

# Create a dedicated profile for this action to avoid
# conflicts with other actions
aws configure --profile hugo-s3 <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

# Install Hugo
if [ -z "$HUGO_VERSION" ]; then
  # https://github.com/gohugoio/hugo/releases/tag/v0.137.0
  # Note that we have no longer build the deploy feature in the standard and extended archives. If you need that,
  # download archives with withdeploy in the filename.
  HUGO_VERSION=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | jq -r '.tag_name')
fi

# Compare versions against specific version that requires a different binary
HUGO_MINIMUM_VERSION_WITHDEPLOY="0.137.0"
HIGHER_HUGO_VERSION=$(lastversion "${HUGO_MINIMUM_VERSION_WITHDEPLOY}" -gt "${HUGO_VERSION}")

if [ $? -eq 0 ]; then
  # HUGO_VERSION is lower than the HUGO_MINIMUM_VERSION_WITHDEPLOY
  HUGO_EDITION='hugo_extended'
  # Trick to get just the digits-only version. lastversion returns the higher digits-only version. Exit code will be 0.
  HUGO_VERSION=$(lastversion "${HUGO_VERSION}" -gt "0.0.0")
else
  # HUGO_VERSION is the same or higher than the HUGO_MINIMUM_VERSION_WITHDEPLOY
  HUGO_EDITION='hugo_extended_withdeploy'
  # HIGHER_HUGO_VERSION contains the digits-only version of the higher version
  HUGO_VERSION="${HIGHER_HUGO_VERSION}"
fi

mkdir tmp/ && cd tmp/
curl -sSL https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_EDITION}_${HUGO_VERSION}_Linux-64bit.tar.gz | tar -xvzf-
mv hugo /usr/local/bin/
cd .. && rm -rf tmp/
cd ${GITHUB_WORKSPACE}
hugo version || exit 1

# Build
if [ "$MINIFY" = "true" ]; then
  hugo --minify
else
  hugo
fi

# Deploy as configured in your repo
hugo deploy

# Clear out credentials after we're done
# We need to re-run `aws configure` with bogus input instead of
# deleting ~/.aws in case there are other credentials living there
aws configure --profile hugo-s3 <<-EOF > /dev/null 2>&1
null
null
null
text
EOF
