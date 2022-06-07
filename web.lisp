(in-package :any.web)

(defparameter *temp-str* nil)

(defun get-local-ip ()
  (join "."
        (mapcar #'(lambda (x)
                    (format nil "~A" x))
                (vector-list
                 (ip-interface-address
                  (car (cdr (get-ip-interfaces))))))))

(defun get-gateway-ip ()
  (remove-duplicates-v
   (mapcar #'(lambda (ip)
               (setf (elt ip 3) 1)
               ip)
           (mapcar #'ip-interface-address
                   (cdr (get-ip-interfaces))))))

(defun get-ip (str)
  (all-matches-as-strings "[0-9]+.[0-9]+.[0-9]+.[0-9]+" str))

(defun get-arp-ip (str)
  (all-matches-as-strings "[0-9]+.[0-9]+.[0-9]+.[0-9]+" str))

(defun vector-ip-to-str (ip)
  (join "."
        (mapcar #'(lambda (x)
                    (format nil "~A" x))
                (vector-list ip))))

(defun get-hosts (gateway-ip)
  (let ((ip (vector-ip-to-str gateway-ip))
        (stream (make-string-output-stream :element-type 'character)))
    (run-shell (format nil "nmap -sP ~A/24" ip)
                 :output stream)
    (cdr (get-ip (get-output-stream-string stream)))))

(defun get-hosts-arp (gateway-ip)
  (let ((ip (vector-ip-to-str gateway-ip))
        (stream (make-string-output-stream :element-type 'character)))
    (run-shell (format nil
                       "echo ~A | sudo -S -k arp-scan ~A/24"
                       (get-password)
                       ip)
               :output stream)
    (cdr (cdr (get-arp-ip (get-output-stream-string stream))))))

(defun find-hosts ()
  (mapcar #'get-hosts-arp
          (get-gateway-ip)))

(defun test ()
  (setf *temp-str* (get-hosts (first (get-gateway-ip)))))

(defun generate-url (host command &key (args nil) (ssl nil))
  (let ((url (format nil "~A/~A" host command))
        (str-args ""))
    (if (> (length args) 0)
        (setf url
              (format nil "~A?" url)))
    (if ssl
        (setf url
              (format nil "https://~A" url))
        (setf url
              (format nil "http://~A" url)))
    (dolist (i args)
      (setf str-args (string-merge str-args (string-merge (car i) (cdr i) "=") "&")))
    (format nil "~A~A" url str-args)))

(defun web-post-json (host command &key args (jsonp t) (isbyte t))
  (multiple-value-bind (body status respone-headers uri stream)
      (dex:post (generate-url host command)
                :content (if isbyte
                             (string-to-octets (to-json-a args))
                             (to-json-a args))
                :headers '(("content-type" . "application/json; charset=utf-8")))
    (declare (ignorable status uri stream))
    (if (and jsonp
             (str:starts-with-p "application/json"
                                (gethash "content-type"
                                         respone-headers)))
        (parse body)
        body)))

(defun web-post (url &key args (jsonp t))
  (multiple-value-bind (body status respone-headers uri stream)
      (dex:post url
                :content args)
    (declare (ignorable status uri stream))
    (if (and jsonp
             (str:starts-with-p "application/json"
                                (gethash "content-type"
                                         respone-headers)))
        (parse body)
        body)))

(defun web-post-upload (url file &key (jsonp nil))
  (let ((text (dex:post url
                        :content `(("image" . ,(pathname file))))))
    (if jsonp
        (parse text)
        text)))

(defun make-url (host command args)
  (make-uri :defaults (generate-url host command)
            :query args))

(defun web-get (host command &key args (jsonp nil))
  (let ((text (dex:get (make-url host command args))))
    (if jsonp
        (parse text)
        text)))

(defun lst2-cons (lst)
  (if (= 2 (length lst))
      (cons (first lst) (second lst))
      lst))

(defun handle-qs (str)
  (mapcar #'(lambda (item)
              (lst2-cons (split "=" item)))
          (split "&" str)))

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

(defun send-text (ip text)
  (web-post-json (format nil "~A:7677" ip)
                     "recive"
                     :args `(("device" . ,(get-id))
                             ("type" . "text")
                             ("data" . ,text))
                     :jsonp t
                     :isbyte t))

(defun send-url (ip url)
  (web-post-json (format nil "~A:7677" ip)
                     "recive"
                     :args `(("device" . ,(get-id))
                             ("type" . "url")
                             ("data" . ,url))
                     :jsonp t
                     :isbyte t))
