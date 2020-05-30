# action-s3-cloudfront
A simple GitHub action to sync with S3 and trigger Cloudfront invalidation

## Inputs

##### `AWS_ACCESS_KEY_ID`

**Required** AWS credentials to use for CLI. You should use the GitHub secrets for this. 

##### `AWS_SECRET_ACCESS_KEY`

**Required** AWS credentials to use for CLI. You should use the GitHub secrets for this. 

##### `AWS_S3_BUCKET`

**Required** AWS credentials to use for CLI. You may use the GitHub secrets for this. 

##### `CLOUDFRONT_INVALIDATE`

**Optional** true/false choice to decide whether to trigger invalidation. 

##### `DISTRIBUTION`

**Optional/Required** Only required when CLOUDFRONT_INVALIDATE is set to true.


## Example usage

    - name: Sync s3 and invalidate cloudfront cache
    uses: imehedi/action-s3-cloudfront@v1
    with:
      args: --acl public-read --follow-symlinks --delete
    env:
      AWS_REGION: 'us-east-1'
      SOURCE_DIR: 'public'
      AWS_S3_BUCKET: ${{ secrets.AWS_S3_BUCKET }}
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      DISTRIBUTION: ${{ secrets.DISTRIBUTION }}
      CLOUDFRONT_INVALIDATE: true
      CF_PATHS: '/*'