;;; anything-etags+.el ---Another Etags anything.el interface

;; Filename: anything-etags+.el
;; Description:Another Etags anything.el interface
;; Author: Joseph <jixiuf@gmail.com>
;; Maintainer: Joseph <jixiuf@gmail.com>
;; Copyright (C) 2011~, Joseph, all rights reserved.
;; Created: 2011-02-04
;; Version: 0.1.0
;; URL: 
;; Keywords: anything, etags
;; Compatibility: (Test on GNU Emacs 23.2.1)
;;
;; Features that might be required by this library:
;;
;; `anything' `etags'
;;
;;
;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This package use `anything' as a interface to find tag with Etags.
;;
;;  it support multiple tag files.
;;  (setq tags-table-list '("/java/tags/TAGS"
;;                          "/java/tags/linux.tag"
;;                          "/java/tags/tag3"))
;;
;;  (global-set-key "\M-." 'anything-etags+-select-at-point-one-key)
;;   `M-.' call  anything-etags+-select-at-point
;;   `C-uM-.' call anything-etags+-select
;;   or
;; (define-key anything-command-map (kbd "e") 'anything-etags+-select-at-point)
;; (define-key anything-command-map (kbd "C-e") 'anything-etags+-select)
;;
;; anything-etags+.el also support history go back ,go forward and list tag
;; histories you have visited.
;;  `anything-etags+-history'
;;    List all tag you have visited with `anything'.
;;  `anything-etags+-history-go-back'
;;    Go back cyclely.
;;  `anything-etags+-history-go-forward'
;;    Go Forward cyclely.
;; anything-etags+.el will manager ring variable `find-tag-marker-ring',
;; so you may feel boring if you don't use command provided by anything-etags+.el
;;
;;
;;
;; if you want to work with etags-table.el ,you just need
;; add this line to to init file after loading etags-table.el
;;
;;     (add-hook 'anything-etags+-select-hook 'etags-table-recompute)
;;
;;
;;; Installation:
;;
;; Don't need anything-etags.el (another etags interface).
;; Just put anything-etags+.el to your load-path.
;; The load-path is usually ~/elisp/.
;; It's set in your ~/.emacs like this:
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;;
;; And the following to your ~/.emacs startup file.
;;
;; (require 'anything-etags+)
;;
;; No need more.
;;
;; this is my config file about etags
;; (require 'anything-etags+)
;; (setq anything-etags+-use-short-file-name nil)
;; ;;you can use  C-uM-. input symbol (default thing-at-point 'symbol)
;; (global-set-key "\M-." 'anything-etags+-select-one-key)
;; ;;list all visited tags
;; (global-set-key "\M-*" 'anything-etags+-history)
;; ;;go back directly 
;; (global-set-key "\M-," 'anything-etags+-history-action-go-back)
;; ;;go forward directly 
;; (global-set-key "\M-/" 'anything-etags+-history-action-go-forward)
;;
;; and how to work with etags-table.el
;; (require 'etags-table)
;; (setq etags-table-alist
;;       (list
;;        '("/home/me/Projects/foo/.*\\.[ch]$" "/home/me/Projects/lib1/TAGS" "/home/me/Projects/lib2/TAGS")
;;        '("/home/me/Projects/bar/.*\\.py$" "/home/me/Projects/python/common/TAGS")
;;        '("/tmp/.*\\.c$"  "/java/tags/linux.tag" "/tmp/TAGS" )
;;        '(".*\\.java$"  "/opt/sun-jdk-1.6.0.22/src/TAGS" )
;;        '(".*\\.[ch]$"  "/java/tags/linux.ctags")
;;        ))
;; (add-hook 'anything-etags+-select-hook 'etags-table-recompute)

;;; Commands:

;; Below are complete command list:
;;
;;  `anything-etags+-select'
;;    Tag jump using etags and `anything'.
;;  `anything-etags+-select-at-point'
;;    Tag jump with current symbol using etags and `anything'.
;;  `anything-etags+-select-one-key'
;;    it will call  `anything-etags+-select' or
;;                  `anything-etags+-select-at-point'
;;   depend on whether you press `C-u'.
;;
;;  `anything-etags+-history'
;;    List all tag you have visited with `anything'.
;;  `anything-etags+-history-go-back'
;;    Go back cyclely.
;;  `anything-etags+-history-go-forward'
;;    Go Forward cyclely.
;;     
;; 
;;
;;; Customizable Options:
;;
;; Below are customizable option list:
;; `anything-etags+-use-short-file-name'(Default t)
;;     don't use absolute path (source file) after each candidates.

;;; Code:

;; Some functions are borrowed from anything-etags.el and etags-select.el.

;;; Require
(require 'custom)
(require 'etags)
(require 'anything)
(require 'anything-config nil t)        ;optional
(require 'anything-match-plugin nil t)  ;optional

;;; Custom

(defgroup anything-etags+ nil
  "Another Etags anything.el interface."
  :prefix "anything-etags+-"
  :group 'convenience)

(defcustom anything-etags+-use-short-file-name t
  "Use short source file name as each candidate's display.
 search '(DISPLAY . REAL)' in anything.el for more info."
  :type 'boolean
  :group 'anything-etags+)

;; (defcustom anything-etags+-disable-history-manager nil
;;   "don't use anything-etags+.el to manager `find-tag-marker-ring'.
;;  if this variable is not none `anything-etags+-history'
;; `anything-etags+-history-go-back' `anything-etags+-history-go-forward'
;;  can not work.
;;  if you want use `etags-stack.el' you should set this to ture"
;;   :type 'boolean
;;   :group 'anything-etags+)

;;; Hooks

(defvar anything-etags+-select-hook nil
  "hooks run before `anything' funcion with
   source `anything-c-source-etags+-select'")

;;; Variables

(defvar anything-etags+-current-marker-in-tag-marker-ring nil
  "a marker in `find-tag-marker-ring', going back and going
forward are related to this variable.")

;; (defvar anything-etags+-history-tmp-marker nil
;;   "this variable will remember current position
;;    when you call `anything-etags+-history'.
;;   after you press `RET' execute `anything-etags+-history-action'
;;  it will be push into `find-tag-marker-ring'")

(defvar anything-idle-delay-4-anything-etags+ 1.0
  "see `anything-idle-delay'. I will set it locally
   in `anything-etags+-select'")

(defvar previous-opened-buffer-in-persistent-action nil
  "record it to kill-it in persistent-action,in order to
   not open too much buffer.")

(defvar anything-etags+-use-xemacs-etags-p
  (fboundp 'get-tag-table-buffer)
  "Use XEmacs etags?")

;;; Functions
(defun anything-etags+-match-string (num &optional string))

(if (string-match "XEmacs" emacs-version)
    (fset 'anything-etags+-match-string 'match-string)
  (fset 'anything-etags+-match-string 'match-string-no-properties))

(defun anything-etags+-case-fold-search ()
  "Get case-fold search."
  (when (boundp 'tags-case-fold-search)
    (if (memq tags-case-fold-search '(nil t))
        tags-case-fold-search
      case-fold-search)))

(defun anything-etags+-get-tag-files ()
  "Get tag files."
  (if anything-etags+-use-xemacs-etags-p
      (buffer-tag-table-list)
    (mapcar 'tags-expand-table-name tags-table-list)))


(defun anything-etags+-rename-tag-file-buffer-maybe(buf)
  (with-current-buffer buf
    (if (string-match "Anything" (buffer-name))
        buf
      (rename-buffer (concat" *Anything etags+:" (buffer-name) "*")))))

(defun anything-etags+-get-tag-table-buffer (tag-file)
  "Get tag table buffer for a tag file."
  (when (file-exists-p tag-file)
    (let ((tag-table-buffer) (current-buf (current-buffer))
          (tags-revert-without-query t)
          (large-file-warning-threshold nil))
      (if anything-etags+-use-xemacs-etags-p
          (setq tag-table-buffer (get-tag-table-buffer tag-file))
        (visit-tags-table-buffer tag-file)
        (setq tag-table-buffer (get-file-buffer tag-file)))
      (set-buffer current-buf)
      (anything-etags+-rename-tag-file-buffer-maybe tag-table-buffer))))

(defun anything-etags+-get-available-tag-table-buffers()
  "Get tag table buffer for a tag file."
  (delete nil (mapcar 'anything-etags+-get-tag-table-buffer
                      (anything-etags+-get-tag-files))))

(defun anything-etags+-get-candidates()
  (let ((tag-files (anything-etags+-get-tag-files))
        (pattern anything-pattern);;default use whole anything-pattern to search in tag files 
        candidates)
    ;; first collect candidates using first part of anything-pattern
    (when (featurep 'anything-match-plugin)
      ;;for example  (amp-mp-make-regexps "boo far") -->("boo" "far")
      (setq pattern (car (amp-mp-make-regexps anything-pattern))))
    (dolist (tag-table-buffer (anything-etags+-get-available-tag-table-buffers))
      (setq candidates
            (append
             candidates
             (anything-etags+-get-candidates-from-tag-file pattern tag-table-buffer))))
    candidates))

(defun anything-etags+-get-candidates-from-tag-file (tagname tag-table-buffer)
  "find tagname in tag-table-buffer. "
  (catch 'failed
    (let ((case-fold-search (anything-etags+-case-fold-search))
          tag-info tag-line src-file-name
          tag-regex candidates)
      (if (string-match "\\\\_<\\|\\\\_>" tagname)
          (progn
            (setq tagname (replace-regexp-in-string "\\\\_<\\|\\\\_>" ""  tagname))
            (setq tag-regex (concat "^.*?\\(" "\^?\\(.+[:.']" tagname "\\)\^A"
                               "\\|" "\^?" tagname "\^A"
                               "\\|" "\\<" tagname "[ \f\t()=,;]*\^?[0-9,]"
                               "\\)")))
        (setq tag-regex (concat "^.*?\\(" "\^?\\(.+[:.'].*" tagname ".*\\)\^A"
                                "\\|" "\^?.*" tagname ".*\^A"
                                "\\|" ".*" tagname ".*[ \f\t()=,;]*\^?[0-9,]"
                                "\\)")))
      (with-current-buffer tag-table-buffer
        (modify-syntax-entry ?_ "w")
        (goto-char (point-min))
        (while (search-forward  tagname nil t) ;;take care this is not re-search-forward ,speed it up
          (beginning-of-line)
          (when (re-search-forward tag-regex (point-at-eol) 'goto-eol)
            (beginning-of-line)
            (save-excursion (setq tag-info (etags-snarf-tag)))
            (re-search-forward "\\s-*\\(.*?\\)\\s-*\^?" (point-at-eol) t)
            (setq tag-line (anything-etags+-match-string 1))
            (setq tag-line (replace-regexp-in-string  "/\\*.*\\*/" "" tag-line))
            (setq tag-line (replace-regexp-in-string  "\t" (make-string tab-width ? ) tag-line))
            (end-of-line)
            ;;(setq src-file-name (etags-file-of-tag))
            (setq src-file-name (file-of-tag))
            (let ((display)(real (list  src-file-name tag-info)))
              (if anything-etags+-use-short-file-name
                  (setq src-file-name (file-name-nondirectory src-file-name)))
              (setq display (concat tag-line
                                      (or (ignore-errors
                                            (make-string (- (window-width) 6
                                                            (string-width tag-line)
                                                            (string-width src-file-name))
                                                         ? )) "")
                                      src-file-name))
              (add-to-list 'candidates (cons display real)))))
        (modify-syntax-entry ?_ "_"))
      candidates)))

(defun anything-etags+-find-tag(candidate)
  "Find tag that match CANDIDATE from `tags-table-list'.
   And switch buffer and jump tag position.."
  (let ((src-file-name (car candidate))
        (tag-info (nth 1 candidate))
        src-file-buf)
    (when (file-exists-p src-file-name)
      ;; Jump to tag position when
      ;; tag file is valid.
      (setq src-file-buf (find-file src-file-name))
      (etags-goto-tag-location  tag-info)
      
      (when (and anything-in-persistent-action ;;color
                 (fboundp 'anything-match-line-color-current-line))
        (anything-match-line-color-current-line))
      
      (if anything-in-persistent-action ;;prevent from opening too much buffer in persistent action
          (progn
            (if (and previous-opened-buffer-in-persistent-action
                     (not (equal previous-opened-buffer-in-persistent-action src-file-buf)))
                (kill-buffer  previous-opened-buffer-in-persistent-action))
            (setq previous-opened-buffer-in-persistent-action src-file-buf))
        (setq previous-opened-buffer-in-persistent-action nil)))))

(defun anything-c-etags+-goto-location (candidate)
  (unless anything-in-persistent-action
;;    (unless anything-etags+-disable-history-manager
      (when (and
           (not (ring-empty-p find-tag-marker-ring))
           anything-etags+-current-marker-in-tag-marker-ring
           (not (equal anything-etags+-current-marker-in-tag-marker-ring (ring-ref find-tag-marker-ring 0))))
       (while (not (ring-empty-p find-tag-marker-ring ))
        (ring-remove find-tag-marker-ring)
        ))
 ;;     )
    (ring-insert find-tag-marker-ring (point-marker))  ;;you can use M=* go back
    (setq anything-etags+-current-marker-in-tag-marker-ring (point-marker))
    )
  (anything-etags+-find-tag candidate);;core func.
  )

(defun anything-etags+-select-internal(init-pattern prompt)
  (run-hooks 'anything-etags+-select-hook)
  (anything '(anything-c-source-etags+-select)
              ;; Initialize input with current symbol
              init-pattern  prompt nil))

(defun anything-etags+-select()
  (interactive)
  "Tag jump using etags and `anything'.
If SYMBOL-NAME is non-nil, jump tag position with SYMBOL-NAME."
  (let ((anything-execute-action-at-once-if-one t)
        (anything-candidate-number-limit nil)
        (anything-idle-delay anything-idle-delay-4-anything-etags+))
    (anything-etags+-select-internal nil "Find Tag(require 3 char): ")))

(defun anything-etags+-select-at-point()
  "Tag jump with current symbol using etags and `anything'."
  (interactive)
  (let ((anything-execute-action-at-once-if-one t)
        (anything-candidate-number-limit nil)
        (anything-idle-delay 0))
    ;; Initialize input with current symbol
    (anything-etags+-select-internal
     (concat "\\_<" (regexp-quote (thing-at-point 'symbol)) "\\_>")
     "Find Tag: ")))

(defun anything-etags+-select-one-key (&optional args)
  "you can bind this to `M-.'"
  (interactive "P")
  (if args
      (anything-etags+-select)
      (anything-etags+-select-at-point)))

(defvar anything-c-source-etags+-select
      '((name . "Etags+")
        (candidates . anything-etags+-get-candidates)
        (volatile);;candidates
        ;;match function ,run after all candidates are collected
        ;;do narrowing ,actually all candidates should be returned
        (match (lambda (candidate)
                 ;; list basename matches first
                 (string-match
                  (replace-regexp-in-string "\\\\_<\\|\\\\_>" ""  anything-pattern)
                  candidate)))
        (requires-pattern  . 3);;need at least 3 char
        (delayed);; (setq anything-idle-delay-4-anthing-etags+ 1)
        (action ("Goto the location" . anything-c-etags+-goto-location))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Go Back and Go Forward

;;util func

;;(anything-etags+-is-marker-avaiable (ring-ref find-tag-marker-ring 0))
(defun anything-etags+-is-marker-available(marker)
  "return nil if marker is nil or  in dead buffer ,
   return marker if it is live"
  (if (and marker
           (markerp marker)
           (marker-buffer marker))
      marker
      ))
;;; func about history
(defun anything-etags+-history-get-candidate-from-marker(marker)
  "genernate candidate from marker candidate= (display . marker)."
  (let ((buf (marker-buffer marker))
        (pos (marker-position marker))
        line-num line-text candidate display
        file-name empty-string1 empty-string2)
    (when  buf
;;      (save-excursion
;;        (set-buffer buf)
      (with-current-buffer buf
        (if anything-etags+-use-short-file-name
            (setq file-name (or (file-name-nondirectory (buffer-file-name)) (buffer-name)))
          (setq file-name (or (buffer-file-name) (buffer-name))))
        (goto-char pos)
        (setq line-num (int-to-string (count-lines (point-min) pos)))
        (setq line-text (buffer-substring-no-properties (point-at-bol)(point-at-eol)))
        (setq line-text (replace-regexp-in-string "^[ \t]*\\|[ \t]*$" "" line-text))
        (setq line-text (replace-regexp-in-string  "/\\*.*\\*/" "" line-text))
        (setq line-text (replace-regexp-in-string  "\t" (make-string tab-width ? ) line-text)))
;;          )
      (if(equal marker anything-etags+-current-marker-in-tag-marker-ring)
          ;;this one will be preselected
          (setq line-text (concat "\t" line-text)))
      (setq empty-string1  (or (ignore-errors
                                (make-string (- (/ (window-width) 2) 6
                                                (string-width line-text)) 
                                             ? )) "  "))
      (setq empty-string2 (or (ignore-errors
                                (make-string (- (/ (window-width) 2) 6
                                                (string-width  line-num)
                                                (string-width file-name))
                                             ? ))"  "))
      (setq display (concat line-text empty-string1 "  in: " empty-string2
                            file-name ":[" line-num "]"))
      (setq candidate  (cons display marker)))))

;;(anything-etags+-history-get-candidate-from-marker (ring-remove (ring-copy find-tag-marker-ring)))
;; (ring-remove )
;; (ring-length find-tag-marker-ring)
;; (anything-etags+-history-get-candidates)
;; time_init
(defun anything-etags+-history-candidates()
  "generate candidates from `find-tag-marker-ring'.
  and remove unavailable markers in `find-tag-marker-ring'"
  (let ((candidates (mapcar 'anything-etags+-history-get-candidate-from-marker (ring-elements find-tag-marker-ring))))
    ;; (when anything-etags+-history-tmp-marker
    ;;   (setq candidates (append (list (anything-etags+-history-get-candidate-from-marker anything-etags+-history-tmp-marker)) candidates)))
    candidates))

(defun anything-etags+-history-init()
  "remove #<marker in no buffer> from `find-tag-marker-ring'.
   and remove those markers older than #<marker in no buffer>."
      (let ((tmp-marker-ring))
        (while (not (ring-empty-p find-tag-marker-ring))
          (anything-aif (anything-etags+-is-marker-available (ring-remove find-tag-marker-ring 0))
              (setq tmp-marker-ring (append tmp-marker-ring (list it)));;new item first
            (while (not (ring-empty-p find-tag-marker-ring));;remove all old marker
              (ring-remove find-tag-marker-ring))))
        ;;reinsert all available marker to `find-tag-marker-ring'
        (mapcar (lambda(marker) (ring-insert-at-beginning find-tag-marker-ring marker)) tmp-marker-ring))
    ;; (when (not (ring-empty-p find-tag-marker-ring))
    ;;   (let ((last-marker-in-find-tag-marker-ring (ring-ref  find-tag-marker-ring 0)))
    ;;     (when (and (equal anything-etags+-current-marker-in-tag-marker-ring  last-marker-in-find-tag-marker-ring)
    ;;                (or (not (equal (marker-buffer last-marker-in-find-tag-marker-ring) (current-buffer)))
    ;;                    (> (abs (- (marker-position last-marker-in-find-tag-marker-ring) (point))) 350)))
    ;;       (setq anything-etags+-history-tmp-marker (point-marker)))))
    )

(defun anything-etags+-history-clear-all(&optional candidate)
  "param `candidate' is unused."
  (while (not (ring-empty-p find-tag-marker-ring));;remove all marker
          (ring-remove find-tag-marker-ring)))


(defun anything-etags+-history-go-back()
  "Go Back. "
  (interactive)
    (anything-etags+-history-init)
    (when (and
           (anything-etags+-is-marker-available anything-etags+-current-marker-in-tag-marker-ring)
           (ring-member find-tag-marker-ring anything-etags+-current-marker-in-tag-marker-ring))
      (let* ((next-marker (ring-next find-tag-marker-ring anything-etags+-current-marker-in-tag-marker-ring)))
        (anything-etags+-history-go-internel next-marker)
        (setq anything-etags+-current-marker-in-tag-marker-ring next-marker))))

(defun anything-etags+-history-go-forward()
  "Go Forward. "
  (interactive)
    (anything-etags+-history-init)
    (when (and
           (anything-etags+-is-marker-available anything-etags+-current-marker-in-tag-marker-ring)
           (ring-member find-tag-marker-ring anything-etags+-current-marker-in-tag-marker-ring))
      (let* ((previous-marker (ring-previous find-tag-marker-ring anything-etags+-current-marker-in-tag-marker-ring)))
        (anything-etags+-history-go-internel previous-marker)
        (setq anything-etags+-current-marker-in-tag-marker-ring previous-marker))))

(defun anything-etags+-history-go-internel (candidate-marker)
  "Go to the location depend on candidate."
  (let ((buf (marker-buffer candidate-marker))
        (pos (marker-position candidate-marker)))
    (when buf
      (switch-to-buffer buf)
      (set-buffer buf)
      (goto-char pos))))

;; (action .func),candidate=(Display . REAL), now in this func
;; param candidate is 'REAL' ,the marker.
(defun anything-etags+-history-action-go(candidate)
  "List all history."
  (anything-etags+-history-go-internel candidate)
  (unless  anything-in-persistent-action
    (setq anything-etags+-current-marker-in-tag-marker-ring candidate)
    ;; (when anything-etags+-history-tmp-marker
    ;;   (ring-insert find-tag-marker-ring anything-etags+-history-tmp-marker)
    ;;   (setq anything-etags+-history-tmp-marker nil))
    )
  (when (and anything-in-persistent-action ;;color
             (fboundp 'anything-match-line-color-current-line))
    (anything-match-line-color-current-line)))

(defvar anything-c-source-etags+-history
      '((name . "Etags+ History: ")
        (header-name .( (lambda (name) (concat name "`RET': Go ,`C-z' Preview. `C-e': Clear all history."))))
        (init .  anything-etags+-history-init)
        (candidates . anything-etags+-history-candidates)
        (volatile)
        (action . (("Go" . anything-etags+-history-action-go)
                   ("Clear all history" . anything-etags+-history-clear-all)))))

(defun anything-etags+-history()
  (interactive)
  (let ((anything-execute-action-at-once-if-one t)
        (anything-quit-if-no-candidate
         (lambda () (message "No history record in `find-tag-marker-ring'"))))
    (anything '(anything-c-source-etags+-history)
              ;; Initialize input with current symbol
              ""  nil nil "^\t")))

(provide 'anything-etags+)

;;;anything-etags+.el ends here.
