(in-package :any.client)

(defparameter *searchp* nil)
(defparameter *devices* (make-hash-table :test #'equal))

(defstruct device
  id
  ip
  livep)

(defun s-device-live (k p)
  (let ((result (gethash k *devices*)))
    (when result
      (setf (gethash k *devices*)
            (setf (getf result :livep)
                  p)))))

(defun send-connect (ip)
  (web-get (format nil "~A:7677" ip)
           "connect"
           :args `(("name" . ,(get-user))
                   ("id" . ,(get-id)))
           :jsonp t))

(defun send-live (ip)
  (web-get (format nil "~A:7677" ip)
           "live"
           :args `(("name" . ,(get-user))
                   ("id" . ,(get-id)))
           :jsonp t))

(defun send-text (device text)
  (web-post-json (format nil "~A:7677" (device-ip device))
                     "recive"
                     :args `(("device" . ,(get-id))
                             ("type" . "text")
                             ("data" . ,text))
                     :jsonp t
                     :isbyte t))

(defun send-url (device url)
  (web-post-json (format nil "~A:7677" (device-ip device))
                     "recive"
                     :args `(("device" . ,(get-id))
                             ("type" . "url")
                             ("data" . ,url))
                     :jsonp t
                     :isbyte t))

(defun add-device (ip device)
  (if (gethash ip *devices*)
      (format t "already in devices~%")
      (setf (gethash ip *devices*)
            (make-device :id device :ip ip :livep t))))


(defun add-device-is (ip)
  (handler-case
      (let ((result (send-connect ip)))
        (when (and result
                   (assoc-value result "name")
                   (assoc-value result "device"))
          (format t "handle name: ~A, device: ~A, ip: ~A~%" (assoc-value result "name")
                  (assoc-value result "device") ip)
          (if (string= (assoc-value result "name")
                       (get-user))
              (let ((device (assoc-value result "device")))
                (format t "handle device: ~A ip: ~A~%" device ip)
                (add-device ip device)
                (format t "add device: ~A ip: ~A~%" device ip))
              (format t "other people(~A) device~%" (assoc-value result "name")))))
    (error (c)
      ;(format t "~A~%" c)
      nil)))

(defun search-devices ()
  (format t "start search device~%")
  (when (not-nil)
    (dolist (i (find-hosts))
      (mapcar #'(lambda (ip)
                  (if (gethash ip *devices*)
                      (format t "already in devices~%")
                      (add-device-is ip)))
              (remove (get-device-ip) i :test #'string=))))
  (save-device)
  (format t "end search device~%"))

(defun devices-live ()
  (maphash #'(lambda (k v)
               (handler-case
                   (let ((result (send-live k)))
                     (if (and result
                              (string= (assoc-value result "device")
                                       (device-id v)))
                         (progn
                           (if (not (device-livep v))
                               (progn
                                 (format t "device: ~A(~A) is relive~%" (device-id v) k)
                                 (setf (device-livep v)
                                       t)
                                 ;(s-device-live k t)
                                 )
                               (format t "device: ~A(~A) is live~%" (device-id v) k)))
                         (progn
                           (format t "device: ~A(~A) device name change or another error~%" (device-id v) k)
                           (setf (device-livep v)
                                 nil)
                           ;(s-device-live k nil)
                           )))
                 (error (c)
                   (format t "device: ~A(~A) refuss connect~%" (device-id v) k)
                   (setf (device-livep v)
                         nil)
                   ;(s-device-live k nil)
                   )))
           *devices*))

(defun device-client-run ()
  (do ((i 0 (+ i 1)))
      ((not *searchp*) nil)
    (when (= (mod i 10) 0)
      ())
    (devices-live)
    (sleep 1))
  (format t "run finish~%"))

(defun start-search ()
  (setf *searchp* t)
  (when (not (uiop:probe-file* "./devices.txt"))
    (with-open-file (in "./devices.txt" :direction :output
                                        :if-exists :overwrite
                                        :if-does-not-exist :create)
      (print () in)))
  (load-device)
  (make-thread #'search-devices :name "device search")
  (make-thread #'device-client-run :name "device-client"))

(defun stop-search ()
  (setf *searchp* nil))

(defun save-device ()
  (let ((result nil))
    (maphash #'(lambda (k v)
                 (push (list :id (device-id v)
                             :ip (device-ip v)
                             :livep (device-livep v))
                       result))
             *devices*)
    (save-data-file "./devices.txt" result)))

(defun load-device ()
  (mapcar #'(lambda (x)
              (setf (gethash (getf x :ip) *devices*)
                    (make-device :id (getf x :id)
                           :ip (getf x :ip)
                           :livep nil)))
          (load-data-file "./devices.txt")))

(defun show-device ()
  (maphash #'(lambda (k v)
               (format t "~A:---------~%~A~%" k v))
           *devices*))

(defun get-device-list ()
  (let ((result nil))
    (maphash #'(lambda (k v)
                 (declare (ignore k))
                 (setf result
                       (append result
                               (list
                                (list (device-id v)
                                      (device-livep v))))))
             *devices*)
    result))

(defun find-device (name &key (livep t))
  (let ((result nil))
    (maphash #'(lambda (k v)
                 (declare (ignore k))
                 (when (string= name
                                (device-id v))
                   (push v result)))
             *devices*)
    (if livep
        (remove-if #'(lambda (device)
                       (not (device-livep device)))
                   result)
        result)))

