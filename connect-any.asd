;;;; connect-any.asd

(asdf:defsystem #:connect-any
  :description "Describe connect-any here"
  :author "lizqwer"
  :license  "Specify license here"
  :version "0.0.1"
  :serial t
  :depends-on (:uiop
               :clack
               :ip-interfaces
               :str
               :dexador
               :babel
               :flexi-streams
               :quri
               :alexandria
               :optima
               :yason
               :bordeaux-threads
               :patron
               :trivial-clipboard
               :jonathan)
  :components ((:file "package")
               (:file "head")
               (:file "web")
               (:file "client")
               (:file "server")
               (:file "main")))
