;;;; connect-any.lisp

(in-package #:connect-any)

(defroute "/"
    (lambda (x)
      "Hello World hahah"))

(defroute "/hello"
    (lambda (x)
      "Hello"))

(defroute "/connect"
    (lambda (x)
      ;(format t "~A~%" x)
      (to-json-a `(("name" . ,(get-user))
                   ("device" . ,(get-id))))))

(defun start ()
  (set-id (prompt-read "DeviceId"))
  (set-user (prompt-read "Name"))
  (let ((server (prompt-read "Address"))
        (port (prompt-read-number "Port")))
    (when (and server
               port)
      (set-device-ip server)
      (server-start :address server :port port)
      (start-search))))

(defun stop ()
  (server-stop))


(in-package :cl-user)
