;;;; main.lisp

(in-package #:connect-any)

(defroute "/"
    (lambda (x)
      (declare (ignore x))
      "Hello World hahah"))

(defroute "/hello"
    (lambda (x)
      (declare (ignore x))
      "Hello"))

(defroute "/connect"
    (lambda (x)
      ;(format t "~A~%" x)
      (declare (ignore x))
      (to-json-a `(("name" . ,(get-user))
                   ("device" . ,(get-id))))))

(defroute "/live"
    (lambda (x)
      (declare (ignore x))
      (to-json-a `(("name" . ,(get-user))
                   ("device" . ,(get-id))))))

(defroute "/sendmsg"
    (lambda (x)
      (format t "~A~%" x)
      (mapcar #'(lambda (i)
                  (format t "~A~%" i))
              (handle-qs (second x)))
      "hello"))

(defroute "/getdevicelist"
    (lambda (x)
      (declare (ignore x))
      (let ((lst (get-device-list)))
        (to-json-a
         (if lst
             `(("msg" . 200)
               ("result" . ,(mapcar #'(lambda (device)
                                        `(("device" . ,(car device))
                                          ("livep" . ,(second device))))
                                    lst)))
             `(("msg" . 404)))))))

(defroute "/recive"
    (lambda (x)
      (let ((text (parse (car (last x)))))
        (when text
          (when (find-device (assoc-value text "device"))
            (send-notify (format nil "~A send text" (assoc-value text "device")))
            (put-text-clipboard (assoc-value text "text")))))))

(defun ptfs ()
  (start (prompt-read "DeviceId")
         (prompt-read "Name")
         (prompt-read "Address")
         (prompt-read-number "Port")))

(defun start (id user server port)
  (set-id id)
  (set-user user)
  (when (and server port)
    (set-device-ip server)
    (server-start :address server :port port)
    (start-search)))

(defun restart (port)
  (when (and (not-nil)
             (get-device-ip)
             port)
    (server-start :address (get-device-ip) :port port)
    (start-search)))

(defun stop ()
  (server-stop)
  (stop-search))

(defun send-clipboard (device)
  (send-text device (trivial-clipboard:text)))

(in-package :cl-user)
