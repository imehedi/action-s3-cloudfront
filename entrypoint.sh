#!/usr/bin/env bash
# Sync a folder to S3 and, optionally, invalidate a CloudFront distribution.
#
# Every setting can come from the step's `with:` (GitHub passes it as INPUT_<NAME>)
# or, as in earlier versions of this action, from the step's `env:`. `with:` wins.
# Anything given as `with: args:` is passed to `aws s3 sync` unchanged.

set -euo pipefail

setting() {
  local input="INPUT_$1"
  printf '%s' "${!input:-${!1:-${2:-}}}"
}

fail() {
  echo "::error::$1"
  exit 1
}

# Credentials given as inputs are exported for the CLI; otherwise the CLI's own
# chain applies (for example, those exported by aws-actions/configure-aws-credentials).
access_key_id="$(setting AWS_ACCESS_KEY_ID)"
secret_access_key="$(setting AWS_SECRET_ACCESS_KEY)"
if [ -n "$access_key_id" ] || [ -n "$secret_access_key" ]; then
  [ -n "$access_key_id" ] && [ -n "$secret_access_key" ] \
    || fail "AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be given together"
  echo "::add-mask::$secret_access_key"
  export AWS_ACCESS_KEY_ID="$access_key_id"
  export AWS_SECRET_ACCESS_KEY="$secret_access_key"
fi

region="$(setting AWS_REGION "${AWS_DEFAULT_REGION:-eu-west-1}")"
export AWS_REGION="$region" AWS_DEFAULT_REGION="$region"

bucket="$(setting AWS_S3_BUCKET)"
source_dir="$(setting SOURCE_DIR .)"
dest_dir="$(setting DEST_DIR)"
dest_dir="${dest_dir#/}"
invalidate="$(setting CLOUDFRONT_INVALIDATE false)"
distribution="$(setting DISTRIBUTION)"
# CF_PATH is the name earlier versions read; CF_PATHS is the documented one.
cf_paths="$(setting CF_PATHS "$(setting CF_PATH '/*')")"

[ -n "$bucket" ] || fail "AWS_S3_BUCKET is not set"
[ -d "$source_dir" ] || fail "SOURCE_DIR '$source_dir' is not a directory"

case "$invalidate" in
  true | false) ;;
  *) fail "CLOUDFRONT_INVALIDATE must be true or false, got '$invalidate'" ;;
esac

# Check the invalidation settings before anything is uploaded.
if [ "$invalidate" = "true" ] && { [ -z "$distribution" ] || [ "$distribution" = "false" ]; }; then
  fail "DISTRIBUTION is required when CLOUDFRONT_INVALIDATE is true"
fi

echo "Syncing '$source_dir' to s3://$bucket/$dest_dir"
aws s3 sync "$source_dir" "s3://$bucket/$dest_dir" "$@"

if [ "$invalidate" = "true" ]; then
  # Split on whitespace without expanding globs, so '/*' reaches CloudFront as written.
  read -r -a paths <<< "$cf_paths"
  echo "Invalidating ${paths[*]} on CloudFront distribution $distribution"
  invalidation_id="$(aws cloudfront create-invalidation \
    --distribution-id "$distribution" \
    --paths "${paths[@]}" \
    --query 'Invalidation.Id' \
    --output text)"
  echo "Invalidation $invalidation_id created"
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "invalidation_id=$invalidation_id" >> "$GITHUB_OUTPUT"
  fi
fi