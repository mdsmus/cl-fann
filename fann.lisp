(defpackage :fann
  (:use :cl :cffi)
  (:export :make-net :make-shortcut-net :cascade-train-on-file
           :train-on-file :load-from-file :save-to-file :run-net :load-fann :close-fann :with-fann))

(in-package :fann)

(define-foreign-library libfann (:unix "libfann.so.2"))

(defun load-fann ()
  (use-foreign-library libfann))

(defun close-fann ()
  (close-foreign-library 'libfann))

(defmacro with-fann (&body body)
  `(handler-case (progn (load-fann)
                        (let ((ret (progn ,@body)))
                          (close-fann)
                          (close-fann)
                          ret))
     (load-foreign-library-error (expr)
       (declare (ignore expr))
       :fann-load-error)))


(with-fann
  (defcfun "fann_create_standard_array" :pointer (num_layers :int) (layers :pointer))

  (defcfun "fann_create_shortcut_array" :pointer (num_layers :int) (layers :pointer))


  (defstruct fann-net fann-net inputs outputs)

  (defun make-net (&rest camadas)
    (with-foreign-object (layers :int (length camadas))
      (loop for i in camadas
         for j from 0
         do (setf (mem-aref layers :int j) i))
      (make-fann-net :fann-net (fann-create-standard-array (length camadas) layers)
                     :inputs (first camadas)
                     :outputs (first (last camadas)))))

  (defun make-shortcut-net (&rest camadas)
    (with-foreign-object (layers :int (length camadas))
      (loop for i in camadas
         for j from 0
         do (setf (mem-aref layers :int j) i))
      (make-fann-net :fann-net (fann-create-shortcut-array (length camadas) layers)
                     :inputs (first camadas)
                     :outputs (first (last camadas)))))

  (defcfun "fann_create_from_file" :pointer (filename :string))
  (defcfun "fann_get_num_input" :int (net :pointer))
  (defcfun "fann_get_num_output" :int (net :pointer))

  (defun load-from-file (filename)
    "Carrega uma rede preconfigurada e pretreinada de um arquivo."
    (let ((net (fann-create-from-file (namestring filename))))
      (make-fann-net :fann-net net
                     :inputs (fann-get-num-input net)
                     :outputs (fann-get-num-output net))))

  (defcfun "fann_save" :int (net :pointer) (filename :string))

  (defun save-to-file (net file)
    "Salva uma rede num arquivo"
    (fann-save (fann-net-fann-net net) (namestring file)))

  (defcfun "fann_train_on_file" :void
    (net :pointer)
    (file :string)
    (max-epochs :int)
    (epochs-between-reports :int)
    (desired-error :float))

  (defun train-on-file (net file max-e ebr de)
    (fann-train-on-file (fann-net-fann-net net) (namestring file) max-e ebr de))

  (defcfun "fann_cascadetrain_on_file" :void
    (net :pointer)
    (file :string)
    (max-neurons :int)
    (neurons-between-reports :int)
    (desired-error :float))

  (defun cascade-train-on-file (net file max-e ebr de)
    (fann-cascadetrain-on-file (fann-net-fann-net net) (namestring file) max-e ebr de))


  (defcfun "fann_run" :pointer (net :pointer) (inputs :pointer))

  (defun run-net (net inputs)
    (with-foreign-object (input :float (fann-net-inputs net))
      (loop for i from 0
         for j in inputs
         do (setf (mem-aref input :float i) (coerce j 'float)))
      (let ((res (fann-run (fann-net-fann-net net) input)))
        (loop for i from 0 to (1- (fann-net-outputs net))
           collect (mem-aref res :float i)))))
           
                         
)

#|

#+sbcl (in-package :sb-impl)

#+sbcl (defun reinit ()
  #+win32 (setf sb!win32::*ansi-codepage* nil)
  (setf *default-external-format* nil)
  
  ;; WITHOUT-GCING implies WITHOUT-INTERRUPTS.
  (without-gcing
    (os-cold-init-or-reinit)
    (thread-init-or-reinit)
    (stream-reinit t)
    #-win32 (signal-cold-init-or-reinit)
    (float-cold-init-or-reinit))
  (gc-reinit)
  (handler-case (foreign-reinit)
    (error (err) (declare (ignore err))))
  (time-reinit)
  ;; If the debugger was disabled in the saved core, we need to
  ;; re-disable ldb again.
  #-sbcl(call-hooks "initialization" *init-hooks*))
|#