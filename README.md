# action-s3-cloudfront

A simple GitHub action to sync a folder to S3 and, optionally, invalidate a
CloudFront distribution. It runs on the official AWS CLI v2 image (`amazon/aws-cli:2.37.9`).

## Inputs

Every input can be given under `with:` or, as in earlier versions, as an
environment variable of the same name under `env:`. `with:` wins when both are set.

| Input                                         | Required          | Default     | Description                                    |
|-----------------------------------------------|-------------------|-------------|------------------------------------------------|
| `AWS_S3_BUCKET`                               | **yes**           |             | Bucket to sync to                              |
| `SOURCE_DIR`                                  | no                | `.`         | Local directory to upload                      |
| `DEST_DIR`                                    | no                | bucket root | Prefix inside the bucket                       |
| `AWS_REGION`                                  | no                | `eu-west-1` | AWS region                                     |
| `CLOUDFRONT_INVALIDATE`                       | no                | `false`     | `true` to invalidate CloudFront after the sync |
| `DISTRIBUTION`                                | when invalidating |             | CloudFront distribution ID                     |
| `CF_PATHS`                                    | no                | `/*`        | Space-separated paths to invalidate            |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | no                |             | Static keys; prefer OIDC (below)               |

Extra flags for `aws s3 sync` (for example `--delete` or `--cache-control`) go in
`with: args:`.

## Outputs

| Output            | Description                                             |
|-------------------|---------------------------------------------------------|
| `invalidation_id` | ID of the CloudFront invalidation, when one was created |

## Example usage

### Recommended: OpenID Connect (no stored keys)

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: actions/checkout@v7

  - name: Configure AWS credentials (OIDC)
    uses: aws-actions/configure-aws-credentials@v6
    with:
      role-to-assume: arn:aws:iam::123456789012:role/github-actions-deploy
      aws-region: us-east-1

  - name: Sync S3 and invalidate CloudFront cache
    uses: imehedi/action-s3-cloudfront@v6
    with:
      AWS_S3_BUCKET: my-site-bucket
      SOURCE_DIR: public
      CLOUDFRONT_INVALIDATE: true
      DISTRIBUTION: ${{ secrets.DISTRIBUTION }}
      CF_PATHS: '/*'
      args: --follow-symlinks --delete
```

### Alternative: access keys from repository secrets

```yaml
- name: Sync S3 and invalidate CloudFront cache
  uses: imehedi/action-s3-cloudfront@v6
  with:
    args: --follow-symlinks --delete
  env:
    AWS_REGION: 'us-east-1'
    SOURCE_DIR: 'public'
    AWS_S3_BUCKET: ${{ secrets.AWS_S3_BUCKET }}
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    DISTRIBUTION: ${{ secrets.DISTRIBUTION }}
    CLOUDFRONT_INVALIDATE: true
    CF_PATHS: '/*'
```

> **About `--acl public-read`:** new S3 buckets have ACLs disabled (Object
> Ownership: *Bucket owner enforced*), so that flag makes the sync fail. Serve
> the bucket through CloudFront with Origin Access Control instead of making
> objects public.

## Releasing

Push a version tag (`git tag v6 && git push origin v6`). The `release` workflow
publishes a GitHub Release with generated notes and moves the `latest` tag.