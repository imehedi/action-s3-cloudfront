#!/bin/sh -l

set -e

if [ -z "$AWS_REGION" ]; then
  AWS_REGION="eu-west-1"
fi

if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo 'missing AWS credentials'
  exit 1
fi

if [[ -z "$AWS_S3_BUCKET" ]]; then
  echo 'target s3 bucket missing'
  exit 1
fi

sh -c "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
       AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}  \
       aws s3 sync ${SOURCE_DIR:-.} s3://${AWS_S3_BUCKET}/${DEST_DIR} \
        $*"
