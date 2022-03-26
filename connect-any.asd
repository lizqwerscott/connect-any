;;;; connect-any.asd

(asdf:defsystem #:connect-any
  :description "Describe connect-any here"
  :author "lizqwer"
  :license  "Specify license here"
  :version "0.0.1"
  :serial t
  :depends-on (:clack
               :ip-interfaces
               :str
               :drakma
               :babel
               :purl
               :alexandria
               :optima
               :yason
               :bordeaux-threads
               :trivial-clipboard
               :jonathan)
  :components ((:file "package")
               (:file "head")
               (:file "web")
               (:file "client")
               (:file "server")
               (:file "main")))
