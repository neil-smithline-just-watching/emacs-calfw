;;; calfw-cal.el --- calendar view for emacs diary

;; Copyright (C) 2011  SAKURAI Masashi

;; Author: SAKURAI Masashi <m.sakurai at kiwanami.net>
;; Keywords: calendar

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

;; Display diary items in the calfw buffer.

;; (require 'calfw-cal)
;;
;; M-x cfw:open-diary-calendar

;; Key binding
;; i : insert an entry on the date
;; RET or Click : jump to the entry
;; q : kill-buffer


;; Thanks for furieux's initial code.

;;; Code:

(require 'calfw)
(require 'calendar)

(defun cfw:cal-modify-diary-entry-string (string)
  "[internal] Add text properties to string, allowing calfw to act on it."
  (propertize string 
              'mouse-face 'highlight
              'help-echo string
              'cfw-marker (copy-marker (point-at-bol))))

(defun cfw:cal-collect-schedules-period (begin end)
  "[internal] Return diary schedule items between BEGIN and END."
  (let ((diary-modify-entry-list-string-function 
         'cfw:cal-modify-diary-entry-string))
    (loop for date in (cfw:enumerate-days begin end) 
          append
          (diary-list-entries date 1 t))))

(defun cfw:cal-onclick ()
  "Jump to the clicked diary item."
  (interactive)
  (let ((marker (get-text-property (point) 'cfw-marker)))
    (when (and marker (marker-buffer marker))
      (switch-to-buffer (marker-buffer marker))
      (goto-char (marker-position marker)))))

(defvar cfw:cal-text-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] 'cfw:cal-onclick)
    (define-key map (kbd "<return>") 'cfw:cal-onclick)
    map)
  "key map on the calendar item text.")

(defun cfw:cal-schedule-period-to-calendar (begin end)
  "[internal] Return calfw calendar items between BEGIN and END
from the diary schedule data."
  (loop
   for i in (cfw:cal-collect-schedules-period begin end)
   for (date line . rest)  = i
   with contents = nil
   do
   (setq contents (cfw:contents-add 
                   date (propertize line 'keymap cfw:cal-text-keymap) 
                   contents))
   finally return contents))

(defvar cfw:cal-schedule-map
  (cfw:define-keymap
   '(
     ("q" . kill-buffer)
     ("i" . cfw:cal-from-calendar)
     ))
  "Key map for the calendar buffer.")

(defun cfw:cal-create-source (&optional color)
  "Create diary calendar source."
  (make-cfw:source
   :name "calendar diary"
   :color (or color "SaddleBrown")
   :data 'cfw:cal-schedule-period-to-calendar))

(defun cfw:open-diary-calendar ()
  "Open the diary schedule calendar in the new buffer."
  (interactive)
  (let* ((source1 (cfw:cal-create-source))
         (cp (cfw:create-calendar-component-buffer
              :view 'month
              :custom-map cfw:cal-schedule-map
              :contents-sources (list source1))))
    (switch-to-buffer (cfw:cp-get-buffer cp))))

(defun cfw:cal-from-calendar ()
  "Insert a new item. This command should be executed on the calfw calendar."
  (interactive)
  (let* ((mdy (cfw:cursor-to-nearest-date))
         (m (calendar-extract-month mdy))
         (d (calendar-extract-day   mdy))
         (y (calendar-extract-year  mdy)))
    (diary-make-entry (calendar-date-string (cfw:date m d y) t t))
    ))

;; (progn (eval-current-buffer) (cfw:open-diary-calendar))

(provide 'calfw-cal)
;;; calfw-cal.el ends here
