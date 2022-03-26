(in-package :any.server)

(defparameter *routes*
  (make-hash-table :test #'equal))

(defparameter *clack-server* nil)

(defun defroute (path fn)
  (setf (gethash path *routes*)
        fn))

(defun handler (env)
  (destructuring-bind (&key request-method path-info request-uri query-string headers content-type content-length raw-body &allow-other-keys)
      env
      (let ((route-fn (gethash path-info *routes*)))
        (format nil "request-method: ~A, path-info:~A, request-uri:~A, query-string: ~A~%"
                request-method path-info request-uri query-string)
        (format nil "content-length: ~A, content-type: ~A, raw-body: ~A~%"
                content-length
                content-type
                raw-body)
        (if route-fn
            `(200
              nil
              (,(funcall route-fn
                         (list request-method
                               query-string
                               content-type
                               content-length
                               raw-body))))
            `(404
              nil
              (,(format nil "The Path not find~%")))))))

(defun server-start (&rest args &key server address port &allow-other-keys)
  (declare (ignore server address port))
  (when *clack-server*
    (restart-case (error "Server is already running.")
      (restart-server ()
        :report "Restart the server"
        (server-stop))))
  (setf *clack-server*
        (apply #'clackup #'handler args)))

(defun server-stop ()
  (if *clack-server*
      (progn
        (stop *clack-server*)
        (setf *clack-server* nil))
      (format t "not started!~%")))

