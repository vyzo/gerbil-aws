#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import :std/make
        (only-in :gerbil/tools/gxtags make-tags))

(def build-spec
  '("aws/env"
    "aws/sigv4"
    "aws/s3"))

(def srcdir
  (path-normalize (path-directory (this-source-file))))

(def (main . args)
  (match args
    (["meta"]
     (write '("spec" "deps" "compile" "tags"))
     (newline))
    (["spec"]
     (pretty-print build-spec))
    (["deps"]
     (let (build-deps (make-depgraph/spec build-spec))
       (call-with-output-file "build-deps" (cut write build-deps <>))))
    (["compile"]
     (let (depgraph (call-with-input-file "build-deps" read))
       (make srcdir: srcdir
             depgraph: depgraph
             optimize: #t
             static: #t
             debug: 'env
             prefix: "vyzo"
             build-spec)))
    (["tags"]
     (make-tags ["aws"] "TAGS"))
    ([]
     (displayln "... make deps")
     (main "deps")
     (displayln "... compile")
     (main "compile")
     (displayln "... make tags")
     (main "tags"))))
