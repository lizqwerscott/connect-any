;;;; package.lisp

(defpackage :any.head
  (:import-from :jonathan :to-json)
  (:use :common-lisp :clack :yason)
  (:export
   :and-list
   :and-vector
   :equal-vector
   :remove-duplicates-v
   :run-shell
   :vector-list
   :string-merge

   :prompt-read
   :prompt-read-number
   :prompt-switch
   :want-to-self-input

   :to-json-a

   :get-user
   :set-user
   :get-id
   :set-id
   :get-device-ip
   :set-device-ip
   :not-nil

   :assoc-value

   :send-notify

   :put-text-chipboard))

(defpackage :any.web
  (:import-from :cl-ppcre :all-matches-as-strings)
  (:use :common-lisp :ip-interfaces :str :any.head :drakma :babel :yason)
  (:export
   :find-hosts
   :web-get
   :web-post-upload
   :web-post
   :web-post-json

   :handle-qs))

(defpackage :any.client
  (:use :common-lisp :bordeaux-threads :any.web :any.head)
  (:export
   :device-id
   :device-ip
   :device-p
   :device-livep
   :start-search
   :stop-search
   :show-device
   :get-device-list
   :find-device
   :send-text))

(defpackage :any.server
  (:use :common-lisp :clack :optima :any.web :any.head :babel)
  (:export
   :defroute
   :server-start
   :server-stop))

(defpackage #:connect-any
  (:use :common-lisp :any.head :any.web :any.client :any.server :str :babel :yason)
  (:export
   :ptfs
   :start
   :restart
   :stop))
