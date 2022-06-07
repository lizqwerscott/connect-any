;;;; package.lisp

(defpackage :any.head
  (:import-from :jonathan :to-json)
  (:import-from :cl-ppcre :all-matches-as-strings)
  (:import-from :uiop :run-program)
  (:use :common-lisp :clack :yason :babel :str)
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

   :put-text-clipboard

   :stream-recive-string

   :bilibili-phone-sharep
   :handle-bilibili-phone-share

   :save-data-file
   :load-data-file

   :set-password
   :get-password

   :list-or))

(defpackage :any.web
  (:import-from :cl-ppcre :all-matches-as-strings)
  (:use :common-lisp :ip-interfaces :str :any.head :babel :yason :patron :quri)
  (:export
   :get-local-ip

   :find-hosts

   :make-url

   :web-get
   :web-post-upload
   :web-post
   :web-post-json

   :handle-qs

   :send-connect
   :send-live
   :send-text
   :send-url))

(defpackage :any.client
  (:use :common-lisp :bordeaux-threads :any.web :any.head)
  (:export
   :device-live-ip
   :start-search
   :stop-search
   :show-device
   :get-device-list
   :find-device

   :send-text
   :send-url

   :add-device))

(defpackage :any.server
  (:use :common-lisp :clack :optima :any.web :any.head :babel)
  (:export
   :defroute
   :server-start
   :server-stop))

(defpackage #:connect-any
  (:use :common-lisp :any.head :any.web :any.client :any.server :str :yason :flexi-streams)
  (:export
   :ptfs
   :start-s
   :restart-s
   :stop-s

   :send-clipboard
   :send-clipboard-url))
