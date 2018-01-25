# Gerbil AWS

AWS client libraries for Gerbil Scheme.

## License

Gambit Licence: dual Apache/2 and LGPL/2.1.

## Installation

```
gxpkg install github.com/vyzo/gerbil-aws
```

## Usage

### Environment

Parameters that control AWS interaction:
```
(import :vyzo/aws/env)

aws-access-key ; AWS_ACCESS_KEY_ID environment variable
aws-secret-key ; AWS_SECRET_ACCESS_KEY environment variable
aws-region     ; AWS_DEFAULT_REGION, defaults to us-east-1

```

You must parameterize `aws-access-key` and `aws-secret-key` or set the appropriate
environment variables.


### S3

```
(import :vyzo/aws/s3)

s3-list-buckets
s3-create-bucket!
s3-delete-bucket!

s3-list-objects
s3-get
s3-put!
s3-delete!

```

Example:
```
> (aws-access-key ...)
> (aws-secret-key ...)

> (s3-create-bucket! "vyzo-test")
> (s3-list-buckets)
("vyzo-test")
> (s3-put! "vyzo-test" "test" "hello world")
> (s3-list-objects "vyzo-test")
("test")
> (bytes->string (s3-get "vyzo-test" "test"))
"hello world"
> (s3-delete! "vyzo-test" "test")
> (s3-list-objects "vyzo-test")
()
> (s3-delete-bucket! "vyzo-test")
> (s3-list-buckets)
()

```
