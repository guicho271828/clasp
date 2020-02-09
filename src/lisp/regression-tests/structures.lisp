(in-package #:clasp-tests)

;; Bug 444
(defstruct defstruct-predicate.a)
(defstruct (defstruct-predicate.b (:include defstruct-predicate.a)))

(test defstruct-predicate
      (defstruct-predicate.a-p (make-defstruct-predicate.b)))

(setf (find-class 'defstruct-predicate.a) nil
      (find-class 'defstruct-predicate.b) nil)

;; Bug 445
(defstruct copy-structure.foo bar)

(test copy-structure
      (let* ((foo1 (make-copy-structure.foo :bar nil))
             (foo2 (copy-structure foo1)))
        (setf (copy-structure.foo-bar foo2) t)
        (not (eq (copy-structure.foo-bar foo1) (copy-structure.foo-bar foo2)))))

(setf (find-class 'copy-structure.foo) nil)

;; Normal-case
(test structure-no-keyword-name-normal
      (let ((instance nil))
        (defstruct otto a b c)
        (setq instance (make-otto :a 1 :b 2 :c 3))
        (multiple-value-bind
              (copy a b c)
            (values (copy-otto instance) (otto-a instance)(otto-b instance)(otto-c instance))
          (and (otto-p copy)(eql a 1)(eql b 2)(eql c 3)))))

;; Following the pattern of above
(setf (find-class 'otto) nil)

(test structure-keyword-name-normal
      (let ((instance nil))
        (defstruct :otto1 a b c)
        (setq instance (make-otto1 :a 1 :b 2 :c 3))
        (multiple-value-bind
              (copy a b c)
            (values (copy-otto1 instance) (otto1-a instance)(otto1-b instance)(otto1-c instance))
          (and (otto1-p copy)(eql a 1)(eql b 2)(eql c 3)))))

(setf (find-class 'otto1) nil)


;; has no OTTO2-P by definition in ansi
(test structure-keyword-name-list
      (let ((instance nil))
        (defstruct (:otto2 (:type list)) a b c)
        (setq instance (make-otto2 :a 1 :b 2 :c 3))
        (multiple-value-bind
              (copy a b c)
            (values (copy-otto2 instance) (otto2-a instance)(otto2-b instance)(otto2-c instance))
          (and (eql a 1)(eql b 2)(eql c 3)))))

(setf (find-class 'otto2) nil)

;; has no OTTO3-P by definition in ansi
(test structure-keyword-name-vector
      (let ((instance nil))
        (defstruct (:otto3 (:type vector)) a b c)
        (setq instance (make-otto3 :a 1 :b 2 :c 3))
        (multiple-value-bind
              (copy a b c)
            (values (copy-otto3 instance) (otto3-a instance)(otto3-b instance)(otto3-c instance))
          (and (eql a 1)(eql b 2)(eql c 3)))))

(setf (find-class 'otto3) nil)

;;; defstruct used to ignore in slot-descriptions the value after :read-only assuming t
(defstruct foo-0a (bar 42 :read-only nil))
(defstruct foo-0b (bar 42 :read-only t))
(defstruct foo-0c (bar 42))
(test structure-use-readonly-value-positive
      (let ((object (make-foo-0a)))
        (setf (foo-0a-bar object) 42)))

(test-expect-error structure-use-readonly-value-negative
      (let ((object (make-foo-0b)))
        (setf (foo-0b-bar object) 42)))

(test structure-use-readonly-value-implicit
      (let ((object (make-foo-0c)))
        (setf (foo-0c-bar object) 42)))

;;; (DEFSTRUCT (STRUCT-TEST-07 :CONC-NAME) A07 B07) should result in accessors a07, b07

(DEFSTRUCT (STRUCT-TEST-07 :CONC-NAME) A07 B07)

(test struct-test-07-5.simplified
      (let ((obj (make-STRUCT-TEST-07 :a07 23 :b07 42)))
        (and (a07 obj)(b07 obj))))

(DEFSTRUCT (STRUCT-TEST-15 (:PREDICATE NIL)) A15 B15)
(test STRUCT-TEST-15/10 (null (FBOUNDP 'STRUCT-TEST-15-P)))

(DEFSTRUCT (STRUCT-TEST-15a (:PREDICATE)) A15 B15)
(test STRUCT-TEST-15/10a (FBOUNDP 'STRUCT-TEST-15A-P))
(DEFSTRUCT (STRUCT-TEST-15b :PREDICATE) A15 B15)
(test STRUCT-TEST-15/10b (FBOUNDP 'STRUCT-TEST-15B-P))
(DEFSTRUCT (STRUCT-TEST-38 (:TYPE LIST) :NAMED) A38 B38 C38)
(test STRUCT-TEST-38-2
      (LET ((S (MAKE-STRUCT-TEST-38)))
        (AND (FBOUNDP 'STRUCT-TEST-38-P)
             (FUNCTIONP #'STRUCT-TEST-38-P)
             (SYMBOL-FUNCTION 'STRUCT-TEST-38-P)
             (NOT (NOT (FUNCALL #'STRUCT-TEST-38-P S)))
             (NOT (NOT (STRUCT-TEST-38-P S))))))

(DEFSTRUCT (STRUCT-TEST-45 (:TYPE LIST) (:INITIAL-OFFSET 2)) A45 B45)
;;; used to error with duplicate slot nil
(test STRUCT-TEST-45
      (eval '(DEFSTRUCT
              (STRUCT-TEST-47 (:TYPE LIST) (:INITIAL-OFFSET 3)
               (:INCLUDE STRUCT-TEST-45))
              C47
              D47)))

(defstruct foo-2 (bar 42 :read-only t))

;;; if read-only is not repeated, assume it is set (don't require it explicitely)
(test sbcl-cross-compile-2
      (eval '(progn
              (defstruct (ifoo-1 (:include foo-2 (bar 43))))
              t)))

(test sbcl-cross-compile-3
      (eval '(progn
              (defstruct (ifoo-2 (:include foo-2 (bar 43 :read-only t))))
              t)))

;;; Should error with something like this (from sbcl)
;;; The slot BAR is :READ-ONLY in superclass, and so must be :READ-ONLY in subclass.
;;; This does not error, but at least we don't generate (setf bar)
;;; To be fixed in override-slotd
(test-expect-error sbcl-cross-compile-4
                   (eval '(progn
                           (defstruct (ifoo-3 (:include foo-2 (bar 43 :read-only nil))))
                           t)))

;;; tests with include
(defstruct node tail-p)
;;; must not define node-tail-p in valued-node, since it would override the function from the parent
(test include-level-2
      (not (find-if #'(lambda(form)
                   (and (listp form)
                        (eql (first form) 'cl:defun)
                        (eql (second form) 'node-tail-p)))
                    (macroexpand '(defstruct (valued-node (:conc-name node-) (:include node)))))))

;;; Should find it , if conc-name leads to different accessor name
(test include-level-2a
      (find-if #'(lambda(form)
                   (and (listp form)
                        (eql (first form) 'cl:defun)
                        (eql (second form) 'nodea-tail-p)))
                    (macroexpand '(defstruct (valued-nodea (:conc-name nodea-) (:include node))))))

(defstruct (valued-node (:conc-name node-) (:include node)))

(defstruct (combination (:include valued-node)))
;;; should generate combination-tailp, but doesn't
;;; That breaks cross-compiling sbcl
;;; Might be wrong in fix-old-slotd
(test include-level-2b
      (fboundp 'combination-tail-p))

(defstruct bar0 a)
(defstruct (bar1 (:include bar0)) b)

;;; must not re-generate accessor bar0-a, but must generate bar0-b & bar0-c
;;; so it is not enough to look at the immediate parent
;;; ccl check in sd-refname-in-included-struct-p all the chain up
(test include-level-3
      (not (find-if #'(lambda(form)
                   (and (listp form)
                        (or (eql (first form) 'cl:defun) #+sbcl (eql (first form) 'SB-C:XDEFUN))
                        (eql (second form) 'bar0-a)))
                    (macroexpand '(defstruct (bar2 (:include bar1)(:conc-name bar0-)) c)))))

(test include-level-3a
      (find-if #'(lambda(form)
                   (and (listp form)
                        (or (eql (first form) 'cl:defun) #+sbcl (eql (first form) 'SB-C:XDEFUN))
                        (eql (second form) 'bar0-b)))
               (macroexpand '(defstruct (bar2 (:include bar1)(:conc-name bar0-)) c))))
 
(defstruct blah a)
(defstruct (sub-blah (:include blah)) b)
(defstruct (sub-sub-blah (:include sub-blah (a 23 :read-only t))) c)

(test-expect-error include-level-4
                   (let ((object (make-sub-sub-blah)))
                     (setf (sub-sub-blah-a object) 15)
                     object))
;;;sub-blah1-a is not generated, but sub-blah1-b
(defstruct (sub-blah1 (:include blah)(:conc-name blah-)) b)
(defstruct (sub-sub-blah1 (:include sub-blah1 (a 23 :read-only t))) c)

(test-expect-error include-level-5
                   (let ((object (make-sub-sub-blah1)))
                     (setf (sub-sub-blah1-a object) 15)
                     object))

(test include-level-5a
      (let ((object (make-sub-sub-blah1 :a 1 :b 2 :c 3)))
        (values
         (sub-sub-blah1-a object)
         (sub-sub-blah1-b object)
         (sub-sub-blah1-c object)
         (setf (sub-sub-blah1-b object) 23)
         (setf (sub-sub-blah1-b object) 42)
         object)))
