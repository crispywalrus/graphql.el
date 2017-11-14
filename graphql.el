;;; graphql.el --- GraphQL utilities                 -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Sean Allred

;; Author: Sean Allred <code@seanallred.com>
;; Keywords: hypermedia, tools, lisp
;; Package-Version: 0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Graphql.el provides a generally-applicable domain-specific language
;; for creating and executing GraphQL queries against your favorite
;; web services.

;;; Code:

(require 'pcase)

(defun graphql--encode-atom (g)
  (cond
   ((stringp g)
    g)
   ((symbolp g)
    (symbol-name g))
   ((numberp g)
    (number-to-string g))
   ((and (consp g)
         (not (consp (cdr g))))
    (symbol-name (car g)))))
(defun graphql--encode-list (l)
  (when (and (consp l) (consp (car l)))
    (mapconcat #'graphql--encode l " ")))
(defun graphql--encode-parameter-pair (pair)
  (graphql--encode-parameter (car pair) (cdr pair)))
(defun graphql--encode-parameter (key value)
  (format "%s:%s"
          key
          (cond
           ((symbolp value)
            (symbol-name value))
           ((listp value)
            (format "{%s}" (mapconcat #'graphql--encode-parameter-pair value ",")))
           ((stringp value)
            (format "\"%s\"" value))
           ((numberp value)
            value)
           (t
            (graphql--encode value)))))

(defun graphql--get-keys (g)
  (let (graph keys)
    (while g
      (if (keywordp (car g))
          (let* ((param (pop g))
                 (value (pop g)))
            (push (cons param value) keys))
        (push (pop g) graph)))
    (list keys (nreverse graph))))

(defun graphql--encode (g)
  "Encode G as a GraphQL string."
  (or (graphql--encode-atom g)
      (graphql--encode-list g)
      (pcase (graphql--get-keys g)
        (`(,keys ,graph)
         (let ((root (car graph))
               (name (alist-get :name keys))
               (arguments (alist-get :arguments keys))
               (rest (cdr graph)))
           (concat
            (symbol-name root)
            (when arguments
              ;; Format arguments "key:value, ..."
              (format "(%s)"
                      (mapconcat #'graphql--encode-parameter-pair arguments ",")))
            (when (or name rest) " ")
            (when name
              (format "%S ") name)
            (when rest
              (format "{ %s }"
                      (if (listp rest)
                          (mapconcat #'graphql--encode rest " ")
                        (graphql--encode rest))))))))))

(defun graphql-encode (g)
  "Encode G as a GraphQL string."
  (let ((s (graphql--encode g)))
    ;; clean up
    (set-text-properties 0 (length s) nil s)
    s))

(provide 'graphql)
;;; graphql.el ends here