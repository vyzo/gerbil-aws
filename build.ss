#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import :std/make)

(def build-spec
  '("aws/env"
    "aws/sigv4"
    "aws/s3"))

(let (srcdir (path-normalize (path-directory (this-source-file))))
  (make srcdir: srcdir
        optimize: #t
        static: #t
        debug: 'env
        prefix: "vyzo"
        build-spec))