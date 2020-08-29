;; Lisp image build script
;;   run with `sbcl --no-sysinit --no-userinit --load`

(defpackage #:rb-sbcl
  (:use #:common-lisp))
(in-package #:rb-sbcl)

(defvar *quicklisp-directory*
  (merge-pathnames "quicklisp/" (user-homedir-pathname)))
(defvar *quicklisp-setup*
  (merge-pathnames "setup.lisp" *quicklisp-directory*))
(defvar *image-name*
  (string-downcase (package-name *package*)))
(defvar *image-timestamp*
  (get-universal-time))

(defmacro message (format &rest args)
  `(format *error-output*
     ,(concatenate 'string "[" *image-name* "] " format "~%") ,@args))

(defun format-timestamp (stream time)
  (multiple-value-bind (se mi hr dd mm yyyy)
    (decode-universal-time time)
    (format stream "~D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
      yyyy mm dd hr mi se)))

(unless (probe-file *quicklisp-setup*)
  (message "Could not find Quicklisp setup file at path ~A." *quicklisp-setup*)
  (sb-ext:exit :code 1))

(load *quicklisp-setup*)
(require :quicklisp)
(message "+quicklisp ~A" ql-info:*version*)

(defvar *quicklisp-dist-version*
  (ql:dist-version "quicklisp"))

(defvar *toplevel-init-hooks*
  '())

(defun toplevel-init ()
  (dolist (hook *toplevel-init-hooks*) (funcall hook))
  (sb-impl::toplevel-init))

(defun ensure-find-package (designator)
  (let ((p (find-package designator)))
    (unless p (error "Cannot find a package named ~A." designator))
    (the package p)))

(let ((cl-package (ensure-find-package '#:common-lisp))
       (user-package (ensure-find-package '#:common-lisp-user)))
  (dolist (package (delete cl-package (package-use-list user-package)))
    (unuse-package package user-package)))

(macrolet ((load-system (sys)
             (check-type sys (or string symbol))
             `(ql:quickload ',sys)))
  (load-system #:asdf)
  (load-system #:uiop)
  (load-system #:alexandria)
  (load-system #:closer-mop)
  (load-system #:babel)
  (load-system #:cl-ppcre)
  (load-system #:trivial-features)
  (load-system #:iterate)
  (load-system #:trivial-gray-streams)
  (load-system #:bordeaux-threads)
  (load-system #:anaphora)
  (load-system #:let-plus)
  (load-system #:cffi)
  (load-system #:nibbles)
  (load-system #:quri)
  (load-system #:usocket)
  (load-system #:cl-fad)
  (load-system #:cl+ssl)
  (load-system #:cl-base64)
  (load-system #:esrap)
  (load-system #:chipz)
  (load-system #:named-readtables)
  (load-system #:drakma)
  (load-system #:ironclad)
  (load-system #:fiveam)
  (load-system #:cl-json)
  (load-system #:log4cl)
  (load-system #:trivia)
  (load-system #:cl-interpol)
  (load-system #:lparallel)
  (load-system #:trivial-types)
  (load-system #:cl-syntax)
  (load-system #:cl-syntax-interpol)
  (load-system #:cl-store)
  (load-system #:cl-autowrap)
  (load-system #:hunchentoot)
  (load-system #:woo)
  (load-system #:cl-dbi)
  (load-system #:cl-opengl)
  (load-system #:sdl2)
  (load-system #:sdl2-image)
  (load-system #:sdl2-mixer)
  (load-system #:sdl2-ttf)
  (load-system #:slynk))

(macrolet ((initialize (&body body)
             `(push (lambda () ,@body) *toplevel-init-hooks*)))
  (initialize (message ".image ~A ~A"
                *image-name* (format-timestamp nil *image-timestamp*)))
  (initialize (message ".implementation ~A ~A"
                (lisp-implementation-type) (lisp-implementation-version)))
  (initialize (message "+asdf ~A" (asdf:asdf-version)))
  (initialize (message "+quicklisp ~A dist ~A"
                ql-info:*version* *quicklisp-dist-version*)))

(setf *toplevel-init-hooks* (nreverse *toplevel-init-hooks*))

(let ((toplevel-fn #'toplevel-init)
       (output-pn (make-pathname :defaults *load-pathname* :type nil :version nil))
       (build-package *package*))
  (let ((*package* (ensure-find-package '#:common-lisp-user)))
    (message "deleting package ~A" (package-name build-package))
    (delete-package build-package)
    (message "building image ~A" output-pn)
    (sb-ext:save-lisp-and-die output-pn :toplevel toplevel-fn :executable t)))
