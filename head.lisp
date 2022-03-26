(in-package :any.head)

(defparameter *user-name* nil)

(defparameter *device-id* nil)

(defparameter *device-ip* nil)

(defun get-user ()
  *user-name*)

(defun set-user (name)
  (setf *user-name* name))

(defun get-id ()
  *device-id*)

(defun set-id (id)
  (setf *device-id* id))

(defun get-device-ip ()
  *device-ip*)

(defun set-device-ip (ip)
  (setf *device-ip* ip))

(defun not-nil ()
  (and *user-name*
       *device-id*))

(setf yason:*parse-object-as* :alist)

(defun and-list (lst &optional (result t))
  (if lst
      (and-list (cdr lst)
                (and (car lst) result))
      result))

(defun and-vector (vector &optional (i 0) (result t))
  (if (< i (length vector))
      (and-vector vector
                  (+ i 1)
                  (and (elt vector i) result))
      result))

(defun equal-vector (x1 x2)
  (and-vector (map 'vector #'equal x1 x2)))

(defun remove-duplicates-v (lst)
  (remove-duplicates lst
                     :test #'equal-vector))

(defun run-shell (program &key (output nil))
  #+clozure (ccl:run-program "/bin/sh"
                             (list "-c" (format nil "~A" program))
                             :output output))

(defun vector-list (v &optional (i 0) (result nil))
  (if (< i (length v))
      (vector-list v
                   (+ i 1)
                   (append result
                           (list (elt v i))))
      result))

(defun string-merge (str1 str2 delimiter)
  (if (or (equal str1 "") (equal str2 ""))
      (format nil "~A~A" str1 str2)
      (format nil "~A~A~A" str1 delimiter str2)))

(defun prompt-read (prompt)
  (format t "Input-~A:" prompt)
  (force-output *query-io*)
  (read-line *query-io*))

(defun prompt-read-number (prompt)
  (or (parse-integer (prompt-read prompt) :junk-allowed t) 0))

(defun prompt-switch (prompt switchs) 
  (format t "Input-~A:~%" prompt)
  (format t "Switch:")
  (do ((i 1 (+ i 1))
       (iterm switchs (cdr iterm)))
      ((= i (+ (length switchs) 1)) 'done)
      (format t " [~A]~A " i (car iterm)))
  (format t "~%")
  (elt switchs 
       (do ((input (prompt-read-number "Number") (prompt-read-number "Number")))
           ((and (>= input 0) (<= input (length switchs))) (- input 1)))))

(defun want-to-self-input (prompt &optional (switchs nil))
  (if (y-or-n-p (format nil "Do you want to chose ~A" prompt))
      (prompt-switch prompt switchs)
      (prompt-read prompt)))

(defun to-json-a (alist)
  (to-json alist :from :alist))

(defun assoc-value (plist key)
  (cdr (assoc key plist :test #'string=)))
