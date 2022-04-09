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
      (let ((another-uri (getf x :uri))
            (another-ip (getf x :addr))
            (query (handle-qs (getf x :query-string))))
        (format t "url: ~A~%" another-ip)
        (format t "str: ~A~%" query)
        (if (string= (get-user) (assoc-value query "name"))
            (add-device another-ip
                        (assoc-value query "id"))
            (format t "another user~%")))
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
              (handle-qs (getf x :query-string)))
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

(defun handle-text (device text)
  (send-notify (format nil "~A send text" device))
  (format t "recive (~A) message:~A~%" device text)
  (put-text-clipboard text)
  (to-json-a
   `(("msg" . 200)
     ("result" . "recive text"))))

(defun handle-url (device url)
  (format t "recive (~A) url: ~A~%" device url)
  (if (bilibili-phone-sharep url)
      (run-shell (format nil "google-chrome-stable '~A' &" (handle-bilibili-phone-share url)))
      (run-shell (format nil "google-chrome-stable '~A' &" url)))
  (to-json-a
   `(("msg" . 200)
     ("result" . "recive url"))))

(defun handle-recive (text)
  (when (find-device (assoc-value text "device"))
    (let ((type (assoc-value text "type"))
          (device (assoc-value text "device"))
          (data (assoc-value text "data")))
      (cond ((string= type "text")
             (handle-text device data))
            ((string= type "url")
             (handle-url device data))
            (t (progn
                 (format t "[ERROR]: ~A is not can find type~%" type)
                 (to-json-a
                  `(("msg" . 220)
                    ("result" . "the type is not find")))))))))

(defroute "/recive"
    (lambda (x)
      (let ((body (stream-recive-string (getf x :raw-body)
                                        (getf x :content-length))))
        (if body
            (let ((text (parse body)))
              (if text
                  (handle-recive text)
                  (to-json-a
                   `(("msg" . 404)
                     ("result" . "the text is null")))))
            (to-json-a
             `(("msg" . 404)
               ("result" . "not have body")))))))

(defun ptfs ()
  (start-s (prompt-read "DeviceId")
           (prompt-read "Name")
           (prompt-read "Address")
           (prompt-read-number "Port")))

(defun start-s (id user &optional (server (get-local-ip)) (port 7677))
  (set-id id)
  (set-user user)
  (when (and server port)
    (set-device-ip server)
    (server-start :address server :port port)
    (start-search)))

(defun restart-s (&optional (port 7677))
  (when (and (not-nil)
             (get-device-ip)
             port)
    (server-start :address (get-device-ip) :port port)
    (start-search)))

(defun stop-s ()
  (server-stop)
  (stop-search))

(defun send-clipboard (device)
  (send-text device (trivial-clipboard:text)))

(defun send-clipboard-url (device)
  (send-url device (trivial-clipboard:text)))

(in-package :cl-user)
