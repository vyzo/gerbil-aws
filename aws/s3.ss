;;; -*- Gerbil -*-
;;; (C) vyzo
;;; AWS S3 client
(import "env"
        "sigv4"
        :std/net/request
        :std/net/uri
        :std/crypto/digest
        :std/text/hex
        :std/xml
        :std/sugar
        :std/srfi/19)
(export s3-list-buckets s3-create-bucket! s3-delete-bucket!
        s3-list-objects s3-get s3-put! s3-delete!)

;;; API
(def (s3-list-buckets)
  (let* ((req (s3-request/error verb: 'GET))
         (xml (s3-parse-xml req))
         (buckets (sxml-select xml (sxml-e? 's3:Bucket)))
         (names (map (cut sxml-find <> (sxml-e? 's3:Name) cadr) buckets)))
    (request-close req)
    names))

;; NOTE: all bucket operations need the correct region for the bucket or they will 400
;; You can set the correct region by parameterizing aws-region (defined in env.ss)
(def (s3-create-bucket! bucket)
  (let (req (s3-request/error verb: 'PUT bucket: bucket))
    (request-close req)
    (void)))

(def (s3-delete-bucket! bucket)
  (let (req (s3-request/error verb: 'DELETE bucket: bucket))
    (request-close req)
    (void)))

(def (s3-list-objects bucket)
  (let* ((req (s3-request/error verb: 'GET bucket: bucket))
         (xml (s3-parse-xml req))
         (keys (sxml-select xml (sxml-e? 's3:Key) cadr)))
    (request-close req)
    keys))

(def (s3-get bucket key)
  (let* ((req (s3-request/error verb: 'GET bucket: bucket
                                path: (string-append "/" key)))
         (data (request-content req)))
    (request-close req)
    data))

(def (s3-put! bucket key data
              content-type: (content-type "binary/octet-stream"))
  (let (req (s3-request/error verb: 'PUT bucket: bucket
                              path: (string-append "/" key)
                              body: data
                              content-type: content-type))
    (request-close req)
    (void)))

(def (s3-delete! bucket key)
  (let (req (s3-request/error verb: 'DELETE bucket: bucket
                              path: (string-append "/" key)))
    (request-close req)
    (void)))

;;; internal
(def (s3-request verb:   (verb 'GET)
                 bucket: (bucket #f)
                 path:   (path "/")
                 query:  (query #f)
                 body:   (body #f)
                 content-type: (content-type #f)) ; must be specified if body is specified
  (let* ((now (current-date))
         (ts (date->string now "~Y~m~dT~H~M~SZ"))
         (scopets (date->string now "~Y~m~d"))
         (scope (string-append scopets "/" (aws-region) "/s3"))
         (hash (sha256 (or body '#u8())))
         (host (if bucket
                 (string-append bucket "." "s3.amazonaws.com")
                 "s3.amazonaws.com"))
         (headers [["Host" :: (string-append host ":443")]
                   ["x-amz-date" :: ts]
                   ["x-amz-content-sha256" :: (hex-encode hash)]
                   (if body [["Content-Type" :: content-type]] []) ...])
         (creq (aws4-canonical-request
                verb: verb
                uri: path
                query: query
                headers: headers
                hash: hash))
         (headers [["Authorization" :: (aws4-auth scope creq ts headers)] :: headers])
         (url (string-append "https://" host path)))
    (case verb
       ((GET)
        (http-get url headers: headers params: query))
       ((PUT)
        (http-put url headers: headers params: query data: body))
       ((DELETE)
        (http-delete url headers: headers params: query))
       ((HEAD)
        (http-head url headers: headers params: query))
       (else
        (error "Bad request verb" verb)))))

(def (s3-request/error . args)
  (with-request-error
   (apply s3-request args)))

(def (s3-parse-xml req)
  (parse-xml (request-content req)
             namespaces: '(("http://s3.amazonaws.com/doc/2006-03-01/" . "s3"))))

(def (with-request-error req)
  (if (and (fx>= (request-status req) 200)
           (fx< (request-status req) 300))
    req
    ;; TODO: proper exception
    (begin
      (request-close req)
      (error "AWS request error"
        (request-status req)
        (request-status-text req)))))
