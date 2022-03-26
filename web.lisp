(in-package :any.web)

(defparameter *temp-str* nil)

(defun get-gateway-ip ()
  (remove-duplicates-v
   (mapcar #'(lambda (ip)
               (setf (elt ip 3) 1)
               ip)
           (mapcar #'ip-interface-address
                   (cdr (get-ip-interfaces))))))

(defun get-ip (str)
  (all-matches-as-strings "[0-9]{3}.[0-9]{3}.[0-9]+.[0-9]+" str))

(defun get-hosts (gateway-ip)
  (let ((ip (join "."
                  (vector-list gateway-ip)))
        (stream (make-string-output-stream :element-type 'character)))
    (run-shell (format nil "nmap -sP ~A/24" ip)
                 :output stream)
    (cdr (get-ip (get-output-stream-string stream)))))

(defun find-hosts ()
  (mapcar #'get-hosts
          (get-gateway-ip)))

(defun test ()
  (setf *temp-str* (get-hosts (first (get-gateway-ip)))))

(defun generate-url (host command &optional args)
  (let ((url (format nil "http://~A/~A?" host command))
        (str-args ""))
    (dolist (i args)
      (setf str-args (string-merge str-args (string-merge (car i) (cdr i) "=") "&")))
    (format nil "~A~A" url str-args)))

(defun web-post-json (host command &key args (jsonp t) (isbyte t))

  (multiple-value-bind (bytes code headers)
      (http-request (generate-url host command)
                    :method :post
                    :content (if isbyte
                                 (string-to-octets (to-json-a args))
                                 (to-json-a args))
                    :content-type "application/json; charset=utf-8")
    (declare (ignorable code))
    (let ((content-type (cdr (assoc :content-type headers))))
      (if (and jsonp
               (starts-with-p "application/json" content-type))
          (parse bytes)
          bytes))))

(defun web-post (host command &key args (jsonp t) (isbyte t))
  (multiple-value-bind (bytes code headers)
      (http-request (generate-url host command)
                    :method :post
                    :parameters args)
    (declare (ignorable code))
    (let ((content-type (cdr (assoc :content-type headers))))
      (if (and jsonp
               (starts-with-p "application/json" content-type))
          (parse bytes)
          bytes))))

(defun web-post-upload (host command file &key (jsonp nil))
  (let ((text (http-request (generate-url host command)
                            :method :post
                            :content-type "multipart/form-data"
                            :parameters `(("image" . ,(pathname file)))
                            :form-data t)))
    (if jsonp
        (parse text)
        text)))

(defun web-get (host command &key args (jsonp nil))
  (let ((text (http-request (generate-url host command args)
                            :method :get)))
    (if jsonp
        (parse text)
        text)))

(defun handle-qs (str)
  (mapcar #'(lambda (item)
              (split "=" item))
          (split "&" str)))

