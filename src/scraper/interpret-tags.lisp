(in-package :cscrape)

(defun interpret-tags (tags)
  (let ((source-info (gather-source-files tags)))
    (calculate-character-offsets source-info))
  (let (cur-lambda cur-docstring cur-declare cur-namespace)
    (dolist (tag tags)
      (cond
        ((typep tag 'tags:namespace-tag)
         (setf cur-namespace (tags:namespace tag)))
        ((typep tag 'tags:lambda-tag)
         (setf cur-lambda tag)
         (setf cur-docstring nil)
         (setf cur-declare nil))
        ((typep tag 'tags:docstring-tag)
         (setf cur-docstring tag))
        ((typep tag 'tags:declare-tag)
         (setf cur-declare tag))
        ((typep tag 'tags:expose-code-tag)
         (setf (tags:lambda-tag tag) cur-lambda)
         (setf (tags:declare-tag tag) cur-declare)
         (setf (tags:docstring-tag tag) cur-docstring)
         (setf (tags:namespace-tag tag) cur-namespace))
        (t #| nothing |#)))))
