;;; -*- Gerbil -*-
;;; (C) vyzo
;;; AWS environment and parameters
(export #t)

(def aws-access-key
  (make-parameter (getenv "AWS_ACCESS_KEY_ID" #f)))
(def aws-secret-key
  (make-parameter (getenv "AWS_SECRET_ACCESS_KEY" #f)))
(def aws-region
  (make-parameter (getenv "AWS_DEFAULT_REGION" "us-east-1")))
