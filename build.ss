#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import :std/build-script)

(defbuild-script
  '("aws/env"
    "aws/sigv4"
    "aws/s3"))
