(in-package :any.server)

(defparameter *routes*
  (make-hash-table :test #'equal))

(defparameter *clack-server* nil)

(defun defroute (path fn)
  (setf (gethash path *routes*)
        fn))

(defun handler (env)
  (format t "get env:~A~%" env)
  (destructuring-bind (&key remote-addr remote-port request-method path-info request-uri query-string headers content-type content-length raw-body &allow-other-keys)
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
                         (list :method request-method
                               :uri request-uri
                               :addr remote-addr
                               :port remote-port
                               :query-string query-string
                               :content-type content-type
                               :content-length content-length
                               :raw-body raw-body))))
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

