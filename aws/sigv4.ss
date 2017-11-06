;;; -*- Gerbil -*-
;;; (C) vyzo
;;; AWS sigv4 request signatures
package: vyzo/aws

(import "env"
        :gerbil/gambit/bytes
        :std/srfi/13
        :std/crypto/digest
        :std/crypto/hmac
        :std/text/hex
        :std/net/uri
        :std/sort)
(export aws4-canonical-request aws4-sign)

;; Reference: http://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html

;; create a canonical request string for signing
(def (aws4-canonical-request
      verb: verb       ; symbol -- http verb (GET PUT DELETE ...)
      uri: uri         ; string -- canonical request uri
      query: query     ; [[string . value] ...] -- query parameters
      headers: headers ; [[string . value] ...] -- signed request headers
      hash: hash       ; bytes -- SHA256 content hash
      )
  (string-append
   (symbol->string verb) "\n"
   uri "\n"
   (canonical-query-string query) "\n"
   (canonical-headers headers) "\n"
   (signed-headers headers) "\n"
   (hex-encode hash)))

;; calculate a signature for a canonical request
;; scope is the request scope: string in the form yyyymmdd/region/service
;; ts is the request timestamp string
;; request is a the canonical request string
(def (aws4-sign scope request-str ts)
  (let ((key (signing-key scope))
        (str (string-to-sign scope request-str ts)))
    (hmac-sha256 key (string->bytes str))))

;;; internal
(def (canonical-repr val)
  (uri-encode
   (with-output-to-string []
     (cut display val))))

(def (canonical-query-string query)
  (let* ((query (map (lambda (q) (cons (car q) (canonical-repr (cdr q))))
                     query))
         (query (sort query (lambda (a b) (string<? (car a) (car b))))))
    (string-join
     (map (lambda (q) (string-append (car q) "=" (cdr q))) query)
     "&")))

(def (canonical-headers headers)
  (let* ((headers (map (lambda (h)
                         (cons (string-downcase (car h))
                               (canonical-repr (cdr h))))
                       headers))
         (headers (sort headers (lambda (a b) (string<? (car a) (car b))))))
    (string-join
     (map (lambda (h) (string-append (car h) ":" (cdr h))) headers)
     "\n")))

(def (signed-headers headers)
  (string-join
   (sort (map (lambda (h) (string-downcase (car h))) headers)
         string<?)
   ";"))

(def (signing-key scope)
  ;; TODO cache signing keys
  (match (string-split scope #\/)
    ([date region service]
     (let* ((date-key
             (hmac-sha256 (string->bytes
                           (string-append "AWS4" (aws-secret-key)))
                          (string->bytes date)))
            (date-region-key
             (hmac-sha256 date-key
                          (string->bytes region)))
            (date-region-svc-key
             (hmac-sha256 date-region-key
                          (string->bytes service))))
       (hmac-sha256 date-region-svc-key
                    (@bytes "aws4_request"))))
    (else
     (error "Bad request scope; expected date/region/service string"))))

(def (string-to-sign scope req ts)
  (string-append "AWS4-HMAC-SHA256\n"
                 ts "\n"
                 scope "\n"
                 (hex-encode (sha256 req))))
