;;; org-special-block-extras.el --- Twenty-six new custom blocks for Org-mode   -*- lexical-binding: t; -*-

;; Copyright (c) 2020 Musa Al-hassy

;; Author: Musa Al-hassy <alhassy@gmail.com>
;; Version: 0.7
;; Package-Requires: ((s "1.12.0") (dash "2.16.0") (emacs "26.1") (dash-functional "1.2.0"))
;; Keywords: org, blocks, colors, convenience
;; URL: https://alhassy.github.io/org-special-block-extras

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Common operations such as colouring text for HTML and LaTeX
;; backends are provided.  Below is an example.
;;
;; #+begin_red org
;; /This/
;;       *text*
;;              _is_
;;                   red!
;; #+end_red
;;
;; This file has been tangled from a literate, org-mode, file;
;; and so contains further examples demonstrating the special
;; blocks it introduces.
;;
;;
;; The system is extensible:
;; Users register a handler ORG-SPECIAL-BLOCK-EXTRAS/TYPE
;; for a new custom block TYPE, which is then invoked.
;; The handler takes three arguments:
;; - CONTENTS: The string contents delimited by the custom block.
;; - BACKEND:  The current exportation backend; e.g., 'html or 'latex.
;; The handler must return a string.

;;; Code:

;; String and list manipulation libraries
;; https://github.com/magnars/dash.el
;; https://github.com/magnars/s.el

(require 's)               ;; “The long lost Emacs string manipulation library”
(require 'dash)            ;; “A modern list library for Emacs”
(require 'subr-x)          ;; Extra Lisp functions; e.g., ‘when-let’.
(require 'cl-lib)          ;; New Common Lisp library; ‘cl-???’ forms.
(require 'dash-functional) ;; Function library; ‘-const’, ‘-compose’, ‘-orfn’,
                           ;; ‘-not’, ‘-partial’, etc.

;;;###autoload
(define-minor-mode org-special-block-extras-mode
  "Provide twenty-six new custom blocks for Org-mode."
  nil nil nil
  (if org-special-block-extras-mode
      (progn
        (advice-add #'org-html-special-block
           :before-until (apply-partially #'org-special-block-extras--advice 'html))
        
        (advice-add #'org-latex-special-block
           :before-until (apply-partially #'org-special-block-extras--advice 'latex))
        (defalias #'org-special-block-extras--parallel
                  #'org-special-block-extras--2parallel)
        
        (defalias #'org-special-block-extras--parallelNB
                  #'org-special-block-extras--2parallelNB)
        (setq org-export-allow-bind-keywords t)
      ) ;; Must be on a new line; I'm using noweb-refs
    (advice-remove #'org-html-special-block
                   (apply-partially #'org-special-block-extras--advice 'html))
    
    (advice-remove #'org-latex-special-block
                   (apply-partially #'org-special-block-extras--advice 'latex))
    )) ;; Must be on a new line; I'm using noweb-refs

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Core utility
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun org-special-block-extras--advice (backend blk contents _)
  "Invoke the appropriate custom block handler, if any.

A given custom block BLK has a TYPE extracted from it, then we
send the block CONTENTS along with the current export BACKEND to
the formatting function ORG-SPECIAL-BLOCK-EXTRAS--TYPE if it is
defined, otherwise, we leave the CONTENTS of the block as is.

We also support the seemingly useless blocks that have no
contents at all, not even an empty new line."
  (let* ((type    (nth 1 (nth 1 blk)))
         (handler (intern (format "org-special-block-extras--%s" type))))
    (ignore-errors (apply handler backend (or contents "") nil))))

(defun org-special-block-extras--extract-arguments (contents &rest args)
"Get list of CONTENTS string with ARGS lines stripped out and values of ARGS.

Example usage:

    (-let [(contents′ . (&alist 'k₀ … 'kₙ))
           (…extract-arguments contents 'k₀ … 'kₙ)]
          body)

Within ‘body’, each ‘kᵢ’ refers to the ‘value’ of argument
‘:kᵢ:’ in the CONTENTS text and ‘contents′’ is CONTENTS
with all ‘:kᵢ:’ lines stripped out.

+ If ‘:k:’ is not an argument in CONTENTS, then it is assigned value NIL.
+ If ‘:k:’ is an argument in CONTENTS but is not given a value in CONTENTS,
  then it has value the empty string."
  (let ((ctnts contents)
        (values (cl-loop for a in args
                         for regex = (format ":%s:\\(.*\\)" a)
                         for v = (cadr (s-match regex contents))
                         collect (cons a v))))
    (cl-loop for a in args
             for regex = (format ":%s:\\(.*\\)" a)
             do (setq ctnts (s-replace-regexp regex "" ctnts)))
    (cons ctnts values)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Load support for 20 colour custom blocks and 20 colour link types

(defvar org-special-block-extras--colors
  '(black blue brown cyan darkgray gray green lightgray lime
          magenta olive orange pink purple red teal violet white
          yellow)
  "Colours that should be available on all systems.")

(cl-loop for colour in org-special-block-extras--colors
      do (eval (read (format
                      "(defun org-special-block-extras--%s (backend contents)
                     (format (pcase backend
                     (`latex \"\\\\begingroup\\\\color{%s}%%s\\\\endgroup\\\\,\")
                     (_  \"<span style=\\\"color:%s;\\\">%%s</span>\"))
                     contents))"
                      colour colour colour))))

(defun org-special-block-extras--color (backend contents)
  "Format CONTENTS according to the ‘:color:’ they specify for BACKEND."
  (-let* (((contents′ . (&alist 'color))
           (org-special-block-extras--extract-arguments contents 'color))
         (block-coloring
          (intern (format "org-special-block-extras--%s" (s-trim color)))))
    (if (member (intern (s-trim color)) org-special-block-extras--colors)
        (funcall block-coloring backend contents′)
      (error "Error: “#+begin_color:%s” ⇒ Unsupported colour!" color))))

;; [[𝒞:text₀][text₁]] ⇒ Colour ‘textₖ’ by 𝒞, where k is 1, if present, otherwise 0.
;; If text₁ is present, it is suggested to use ‘color:𝒞’, defined below.
(cl-loop for colour in org-special-block-extras--colors
         do (org-link-set-parameters
             (format "%s" colour)
              :follow `(lambda (path) (message "Colouring “%s” %s." path (quote ,colour)))
              :export `(lambda (label description backend)
                        (-let [block-colouring
                               (intern (format "org-special-block-extras--%s" (quote ,colour)))]
                          (funcall block-colouring backend (or description label))))
              :face `(:foreground ,(format "%s" colour))))

;; Generic ‘color’ link type [[color:𝒞][text]] ⇒ Colour ‘text’ by 𝒞.
;; If 𝒞 is an unsupported colour, ‘text’ is rendered in large font
;; and surrounded by red lines.
(org-link-set-parameters "color"
   :follow (lambda (_))
   :face (lambda (colour)
           (if (member (intern colour) org-special-block-extras--colors)
               `(:foreground ,(format "%s" colour))
             `(:height 300
               :underline (:color "red" :style wave)
               :overline  "red" :strike-through "red")))
 :help-echo (lambda (window object position)
              (save-excursion
                (goto-char position)
                (-let* (((&plist :path) (cadr (org-element-context))))
                  (if (member (intern path) org-special-block-extras--colors)
                      "Colour links just colour the descriptive text"
                    (format "Error: “color:%s” ⇒ Unsupported colour!" path)))))
   :export (lambda (colour description backend)
             (-let [block-colouring
                    (intern (format "org-special-block-extras--%s" colour))]
               (if (member (intern colour) org-special-block-extras--colors)
                   (funcall block-colouring backend description)
                 (error "Error: “color:%s” ⇒ Unsupported colour!" colour)))))

(defun org-special-block-extras--latex-definitions (backend contents)
  "Declare but do not display the CONTENTS according to the BACKEND."
  (loop for (this that) in (-partition 2 '("<p>" ""
                                           "</p>" ""
                                           "\\{" "{"
                                           "\\}" "}"))
        do (setq contents (s-replace this that contents)))
  (format (pcase backend
            ('html "<p style=\"display:none\">\\[%s\\]</p>")
            (_ "%s"))
          contents))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Parallel blocks: 𝓃parallel[NB] for n:2..5, optionally with ‘N’o ‘b’ar
;; in-between the columns.
;;
;; Common case is to have three columns, and we want to avoid invoking the
;; attribute via org, so making this.

(cl-loop for cols in '("1" "2" "3" "4" "5")
      do (cl-loop for rule in '("solid" "none")
      do (eval (read (concat
"(defun org-special-block-extras--" cols "parallel"
(if (equal rule "solid") "" "NB")
"(backend contents)"
"(format (pcase backend"
"(`html \"<div style=\\\"column-rule-style:" rule ";column-count:" cols ";\\\"%s</div>\")"
"(`latex \"\\\\par \\\\setlength{\\\\columnseprule}{" (if (equal rule "solid") "2" "0") "pt}"
"          \\\\begin{minipage}[t]{\\\\linewidth}"
"          \\\\begin{multicols}{" cols "}"
"          %s"
"          \\\\end{multicols}\\\\end{minipage}\"))"
"(s-replace \":columnbreak:\" (if (equal 'html backend) \"\" \"\\\\columnbreak\")
contents)))")))))

(defvar org-special-block-extras-hide-editor-comments nil
  "Should editor comments be shown in the output or not.")

(defun org-special-block-extras--edcomm (backend contents)
"Format CONTENTS as an first-class editor comment according to BACKEND.

The CONTENTS string has two optional argument switches:
1. :ed: ⇒ To declare an editor of the comment.
2. :replacewith: ⇒ [Nullary] The text preceding this clause
   should be replaced by the text after it."
  (-let* (
           ;; Get arguments
           ((contents₁ . (&alist 'ed))
            (org-special-block-extras--extract-arguments contents 'ed))

           ;; Strip out any <p> tags
           (_ (setq contents₁ (s-replace-regexp "<p>" "" contents₁)))
           (_ (setq contents₁ (s-replace-regexp "</p>" "" contents₁)))

           ;; Are we in the html backend?
           (html? (equal backend 'html))

           ;; fancy display style
           (boxed (lambda (x)
                    (if html?
                        (concat "<span style=\"border-width:1px"
                                 ";border-style:solid;padding:5px\">"
                                 "<strong>" x "</strong></span>")
                    (concat "\\fbox{\\bf " x "}"))))

           ;; Is this a replacement clause?
           ((this that) (s-split ":replacewith:" contents₁))
           (replacement-clause? that) ;; There is a ‘that’
           (replace-keyword (if html? "&nbsp;<u>Replace:</u>"
                              "\\underline{Replace:}"))
           (with-keyword    (if html? "<u>With:</u>"
                              "\\underline{With:}"))
           (editor (format "[%s:%s"
                           (if (s-blank? ed) "Editor Comment" ed)
                           (if replacement-clause?
                               replace-keyword
                             "")))
           (contents₂ (if replacement-clause?
                          (format "%s %s %s" this
                                  (funcall boxed with-keyword)
                                  that)
                        contents₁))

           ;; “[Editor Comment:”
           (edcomm-begin (funcall boxed editor))
           ;; “]”
           (edcomm-end (funcall boxed "]")))

    (setq org-export-allow-bind-keywords t) ;; So users can use “#+bind” immediately
    (if org-special-block-extras-hide-editor-comments
        ""
      (format (pcase backend
                ('latex "%s %s %s")
                (_ "<p> %s %s %s</p>"))
              edcomm-begin contents₂ edcomm-end))))

(org-link-set-parameters
 "edcomm"
  :follow (lambda (_))
  :export (lambda (label description backend)
            (org-special-block-extras--edcomm
             backend
             (format ":ed:%s\n%s" label description)))
  :help-echo (lambda (window object position)
               (save-excursion
                 (goto-char position)
                 (-let* [(&plist :path) (cadr (org-element-context))]
                   (format "%s made this remark" (s-upcase path)))))
  :face '(:foreground "red" :weight bold))

(defun org-special-block-extras--details (backend contents)
"Format CONTENTS as a ‘folded region’ according to BACKEND.

CONTENTS may have a ‘:title’ argument specifying a title for
the folded region."
(-let* (;; Get arguments
        ((contents′ . (&alist 'title))
         (org-special-block-extras--extract-arguments contents 'title)))
  (when (s-blank? title) (setq title "Details"))
  (setq title (s-trim title))
  (format
   (s-collapse-whitespace ;; Remove the whitespace only in the nicely presented
                          ;; strings below
    (pcase backend
      (`html "<details class=\"code-details\">
                 <summary>
                   <strong>
                     <font face=\"Courier\" size=\"3\" color=\"green\"> %s
                     </font>
                   </strong>
                 </summary>
                 %s
              </details>")
      (`latex "\\begin{quote}
                 \\begin{tcolorbox}[colback=white,sharp corners,boxrule=0.4pt]
                   \\textbf{%s:}
                   %s
                 \\end{tcolorbox}
               \\end{quote}")))
    title contents′)))

(org-link-set-parameters
  "link-here"
  :follow (lambda (path) (message "This is a local anchor link named “%s”" path))
  :export #'org-special-block-extras--link-here)

(defun org-special-block-extras--link-here (label description backend)
  "Export a link to the current location in an Org file.

The LABEL determines the name of the link.

+ Only the syntax ‘link-here:label’ is supported.
+ Such links are displayed using an “octicon-link”
  and so do not support the DESCRIPTION syntax
  ‘[[link:label][description]]’.
+ Besides the HTML BACKEND, such links are silently omitted."
    (pcase backend
      (`html  (format (s-collapse-whitespace
          "<a class=\"anchor\" aria-hidden=\"true\" id=\"%s\"
          href=\"#%s\"><svg class=\"octicon octicon-link\" viewBox=\"0 0 16
          16\" version=\"1.1\" width=\"16\" height=\"16\"
          aria-hidden=\"true\"><path fill-rule=\"evenodd\" d=\"M4
          9h1v1H4c-1.5 0-3-1.69-3-3.5S2.55 3 4 3h4c1.45 0 3 1.69 3 3.5 0
          1.41-.91 2.72-2 3.25V8.59c.58-.45 1-1.27 1-2.09C10 5.22 8.98 4 8
          4H4c-.98 0-2 1.22-2 2.5S3 9 4 9zm9-3h-1v1h1c1 0 2 1.22 2
          2.5S13.98 12 13 12H9c-.98 0-2-1.22-2-2.5 0-.83.42-1.64
          1-2.09V6.25c-1.09.53-2 1.84-2 3.25C6 11.31 7.55 13 9 13h4c1.45 0
          3-1.69 3-3.5S14.5 6 13 6z\"></path></svg></a>") label label))
      (_ "")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The badge link types
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(org-link-set-parameters "badge"
  :follow (lambda (path) (--> (s-split "|" path)
                         (or (nth 3 it) path)
                         (browse-url it)))
  :export #'org-special-block-extras--link--badge)

(defvar org-special-block-extras--link--twitter-excitement
  "This looks super neat ^_^ :"
  "The string prefixing the URL being shared.")

(defun org-special-block-extras--link--badge
  (label description backend &optional social)
  "Export a link presented as an SVG badge.

The LABEL should be of the shape ‘key|value|color|url|logo’
resulting in a badge “|key|value|” where the ‘key’
is coloured grey and the ‘value’ is coloured ‘color’.

The optional SOCIAL toggle indicates if we want an icon for
Twitter, Reddit, Github, etc, instead of a badge.
When SOCIAL is provided, we interpret LABEL as an atomic string.

+ Only the syntax ‘badge:key|value|color|url’ is supported.
  - ‘key’ and ‘value’ have their underscores interpreted as spaces.
     ⇒ Underscores are interpreted as spaces;
     ⇒ ‘__’ is interpreted as an underscore;
     ⇒ ‘|’ is not a valid substring, but ‘-, %, ?’ are okay.
  - ‘|color|url|logo’ are optional;
     if ‘url’ is ‘|here’ then the resulting badge behaves
     like ‘link-here:key’.
  - ‘color’ may be: ‘brightgreen’ or ‘success’,
                    ‘red’         or ‘important’,
                    ‘orange’      or ‘critical’,
                    ‘lightgrey’   or ‘inactive’,
                    ‘blue’        or ‘informational’,
            or ‘green’, ‘yellowgreen’, ‘yellow’, ‘blueviolet’, ‘ff69b4’, etc.
+ Such links are displayed using a SVG badges
  and so do not support the DESCRIPTION syntax
  ‘[[link:label][description]]’.
+ Besides the HTML BACKEND, such links are silently omitted."
  (-let* (((lbl msg clr url logo) (s-split "|" label))
          (_ (unless (or (and lbl msg) social)
               (error "%s\t⇒\tBadges are at least “badge:key|value”!" label)))
          ;; Support dashes and other symbols
          (_ (unless social
               (setq lbl (s-replace "-" "--" lbl)
                     msg (s-replace "-" "--" msg))
               (setq lbl (url-hexify-string lbl)
                     msg (url-hexify-string msg))))
          (img (format "<img src=\"https://img.shields.io/badge/%s-%s-%s%s\">"
                        lbl msg clr
                        (if logo (concat "?logo=" logo) ""))))
    (when social
      (-->
          `(("reddit"            "https://www.reddit.com/r/%s")
            ("github/followers"  "https://www.github.com/%s?tab=followers")
            ("github/forks"      "https://www.github.com/%s/fork")
            ("github"            "https://www.github.com/%s")
            ("twitter/follow"    "https://twitter.com/intent/follow?screen_name=%s")
            ("twitter/url"
             ,(format
               "https://twitter.com/intent/tweet?text=%s:&url=%%s"
               org-special-block-extras--link--twitter-excitement)
             ,(format
               "<img src=\"https://img.shields.io/twitter/url?url=%s\">"
               label)))
        (--filter (s-starts-with? (first it) social) it)
        (car it)
        (or it (error "Badge: Unsupported social type “%s”" social))
        (setq url (format (second it) label)
              img (or (third it)
                      (format "<img src=\"https://img.shields.io/%s/%s?style=social\">"
                      social label)))))
    (pcase backend
        (`html (if url
                 (if (equal url "here")
                     (format "<a id=\"%s\" href=\"#%s\">%s</a>" lbl lbl img)
                   (format "<a href=\"%s\">%s</a>" url img))
               img))
        (_ ""))))

(loop for (social link) in '(("reddit/subreddit-subscribers" "reddit-subscribe-to")
                             ("github/stars")
                             ("github/watchers")
                             ("github/followers")
                             ("github/forks")
                             ("twitter/follow")
                             ("twitter/url?=url=" "tweet"))
      for link′ = (or link (s-replace "/" "-" social))
      do (org-link-set-parameters link′
           :export (eval `(-cut org-special-block-extras--link--badge
                         <> <> <> ,social))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'org-special-block-extras)

;;; org-special-block-extras.el ends here
