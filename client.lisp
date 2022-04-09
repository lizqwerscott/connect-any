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
  (let ((d (find-device device)))
    (when (and d
               (device-livep d))
      (web-post-json (format nil "~A:7677" (device-ip d))
                     "recive"
                     :args `(("device" . ,(get-id))
                             ("text" . ,text))
                     :jsonp t
                     :isbyte t))))

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
  (when (not-nil)
    (dolist (i (find-hosts))
      (mapcar #'(lambda (ip)
                  (if (gethash ip *devices*)
                      (format t "already in devices~%")
                      (add-device-is ip)))
              (remove (get-device-ip) i :test #'string=)))))

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
  (format t "start search device~%")
  (search-devices)
  (format t "end search device~%")
  (make-thread #'device-client-run :name "device-client"))

(defun stop-search ()
  (setf *searchp* nil))

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

(defun find-device (name)
  (let ((result nil))
    (maphash #'(lambda (k v)
                 (declare (ignore k))
                 (when (string= name
                                (device-id v))
                   (setf result v)))
             *devices*)
    result))

