(in-package :any.client)

(defclass device-s ()
    ((id
      :initarg :id
      :accessor g-device-id)
     (ips
      :initarg :ips
      :initform nil
      :accessor g-device-ips)
     (livep
      :initform t
      :accessor g-device-livep)))

(defmethod device-is-live ((device device-s))
  (setf (g-device-ips device)
        (mapcar #'(lambda (ipl)
                    (list (car ipl)
                          (handler-case
                              (let ((result (send-live (car ipl))))
                                (and result
                                     (string= (assoc-value result "device")
                                              (g-device-id device))))
                            (error (c)
                              (format t
                                      "device: ~A(~A) refuss connect (~A)~%"
                                      (g-device-id device)
                                      (car ipl)
                                      c)
                              nil))))
                (g-device-ips device)))
  (setf (g-device-livep device)
        (list-or
         (mapcar #'second
                 (g-device-ips device))))
  (if (g-device-livep device)
      (format t "device:~A is live~%" (g-device-id device))
      (format t "device:~A is dead~%" (g-device-id device)))
  (g-device-livep device))

(defmethod device-add-ip ((device device-s) ip livep)
  (let ((ips (g-device-ips device)))
    (if (not (find ip ips :test #'string= :key #'car))
        (setf (g-device-ips device)
              (append ips
                      (list
                       (cons ip livep)))))))

(defmethod device-live-ip ((device device-s))
  (labels ((find-live (ips)
             (when ips
               (if (second (car ips))
                   (car ips)
                   (find-live (cdr ips))))))
    (car (find-live (g-device-ips device)))))

(defparameter *searchp* nil)
(defparameter *devices* (make-hash-table :test #'equal))

(defun s-device-live (k p)
  (let ((result (gethash k *devices*)))
    (when result
      (setf (gethash k *devices*)
            (setf (getf result :livep)
                  p)))))

(defun add-device (ip device-id)
  (if (gethash device-id *devices*)
      (let ((device (gethash device-id *devices*)))
        (if (device-add-ip device ip t)
            device
            (format t "already in devices~%")))
      (setf (gethash device-id *devices*)
            (make-instance 'device-s :id device-id :ips `((,ip . t))))))

(defun find-device-ip (ip)
  (let ((result))
    (maphash #'(lambda (device-id device)
                 (let ((r (find ip (g-device-ips device) :test #'string=)))
                   (when r
                     (push device result))))
             *devices*)
    result))

(defun add-device-is (ip)
  (handler-case
      (let ((result (send-connect ip)))
        (when (and result
                   (assoc-value result "name")
                   (assoc-value result "device"))
          (format t
                  "handle name: ~A, device: ~A, ip: ~A~%"
                  (assoc-value result "name")
                  (assoc-value result "device")
                  ip)
          (if (string= (assoc-value result "name")
                       (get-user))
              (let ((device-id (assoc-value result "device")))
                (format t "handle device: ~A ip: ~A~%" device-id ip)
                (add-device ip device-id)
                (format t "add device: ~A ip: ~A~%" device-id ip))
              (format t "other people(~A) device~%" (assoc-value result "name")))))
    (error (c)
      ;(format t "~A~%" c)
      nil)))

(defun search-devices ()
  (format t "start search device~%")
  (when (not-nil)
    (dolist (i (find-hosts))
      (mapcar #'(lambda (ip)
                  (add-device-is ip))
              (remove (get-device-ip) i :test #'string=))))
  (save-device)
  (format t "end search device~%"))

(defun device-client-run ()
  (do ((i 0 (+ i 1)))
      ((not *searchp*) nil)
    (when (= (mod i 10) 0)
      ())
    ;(devices-live)
    (maphash #'(lambda (id device)
                 (declare (ignore id))
                 (device-is-live device))
             *devices*)
    (sleep 5))
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
                 (push (list :id (g-device-id v)
                             :ips (g-device-ips v))
                       result))
             *devices*)
    (save-data-file "./devices.txt" result)))

(defun load-device ()
  (mapcar #'(lambda (x)
              (setf (gethash (getf x :id) *devices*)
                    (make-instance 'device-s
                                   :id (getf x :id)
                                   :ips (getf x :ips))))
          (load-data-file "./devices.txt")))

(defun show-device ()
  (maphash #'(lambda (k v)
               (format t "~A:---------~%" k)
               (format t "ips:~A~%" (g-device-ips v))
               (format t "live:~A~%" (g-device-livep v)))
           *devices*))

(defun get-device-list ()
  (let ((result nil))
    (maphash #'(lambda (k v)
                 (declare (ignore k))
                 (push (list k
                             (g-device-livep v))
                       result))
             *devices*)
    result))

(defun find-device (name &key (livep t))
  (let ((result (gethash name *devices*)))
    (when result
      (if livep
          (when (g-device-livep result)
            result)
          result))))

