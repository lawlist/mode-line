(setq line-number-display-limit-width 1000) ;; default is 200

(defvar ml-deplacement-commands '(dired-next-line
                                  dired-previous-line
                                  newline
                                  mwheel-scroll
                                  self-insert-command
                                  left-char
                                  right-char
                                  previous-line
                                  next-line
                                  forward-paragraph
                                  backward-paragraph
                                  handle-switch-frame
                                  handle-select-window
                                  scroll-up
                                  scroll-down))

(defvar ml-this-command nil)

(defvar ml-last-command nil)

(defvar ml-selected-window--pre-command-hook nil)

(defvar ml-selected-window--post-command-hook nil)

(defvar ml-record-minor-mode-alist nil
  "The recorded value of the sorted minor-mode-alist.")
(make-variable-buffer-local 'ml-record-minor-mode-alist)

(defvar ml-record-date-time nil
  "The recorded value of the date-time.")
(make-variable-buffer-local 'ml-record-date-time)

(defvar ml-record-tabbar-current-tabset nil
  "The recorded value of the tabbar-current-tabset.")
(make-variable-buffer-local 'ml-record-tabbar-current-tabset)

(defvar ml-record-shortened-directory nil
  "The recorded value of the shortened-directory.")
(make-variable-buffer-local 'ml-record-shortened-directory)

(defvar ml-record-eol-type nil
  "The recorded value of the eol-type.")
(make-variable-buffer-local 'ml-record-eol-type)

(defun shorten-directory (dir max-length)
"http://amitp.blogspot.com/2011/08/emacs-custom-mode-line.html
Show up to `max-length' characters of a directory name `dir'."
  (let ((path (reverse (split-string (abbreviate-file-name dir) "/")))
        (output ""))
    (when (and path (equal "" (car path)))
      (setq path (cdr path)))
    (while (and path (< (length output) (- max-length 4)))
      (setq output (concat (car path) "/" output))
      (setq path (cdr path)))
    (when path
      (setq output (concat ".../" output)))
    output))

(defun ml-set-format ()
  (setq mode-line-format '(
     " "
     (:eval
        (cond
          ((and
              buffer-read-only
              (buffer-modified-p)
              (eq ml-selected-window--post-command-hook (selected-window)))
            (propertize "!*" 'face 'bold))
          ((and
              buffer-read-only
              (buffer-modified-p)
              (not (eq ml-selected-window--post-command-hook (selected-window))))
            "!*")
          ((and
              buffer-read-only
              (not (buffer-modified-p))
              (eq ml-selected-window--post-command-hook (selected-window)))
            (propertize "!-" 'face 'bold))
          ((and
              buffer-read-only
              (not (buffer-modified-p))
              (not (eq ml-selected-window--post-command-hook (selected-window))))
            "!-")
          ((and
              (buffer-modified-p)
              (eq ml-selected-window--post-command-hook (selected-window)))
            (propertize "**" 'face 'bold))
          ((and
              (buffer-modified-p)
              (eq ml-selected-window--post-command-hook (selected-window)))
            "**")
          (t "--")))
     " | "
     (:eval
        (if
            (and
              (eq ml-this-command ml-last-command)
              (memq ml-this-command ml-deplacement-commands))
          ml-record-shortened-directory
          (setq ml-record-shortened-directory
                (cond
                  ((or (null buffer-file-name)
                       (null default-directory))
                    (if (eq ml-selected-window--post-command-hook (selected-window))
                      (propertize "%b" 'face 'bold)
                      "%b"))
                  ((and (null buffer-file-name)
                        default-directory)
                    (if (eq ml-selected-window--post-command-hook (selected-window))
                      (concat
                        (shorten-directory default-directory 10)
                        (propertize "%b" 'face 'bold))
                      (concat
                        (shorten-directory default-directory 10)
                        "%b")))
                  (buffer-file-name
                    (if (eq ml-selected-window--post-command-hook (selected-window))
                      (concat
                        (shorten-directory (file-name-directory buffer-file-name) 10)
                        (propertize "%b" 'face 'bold))
                      (concat
                        (shorten-directory (file-name-directory buffer-file-name) 10)
                        "%b")))))))
     " | "
     (:eval
        (if (eq ml-selected-window--post-command-hook (selected-window))
          (propertize "L" 'face 'bold)
          "L"))
     ":%l"
     (:eval
        (let ((cc (current-column)))
          (concat
            " "
            (if (eq ml-selected-window--post-command-hook (selected-window))
              (propertize "C" 'face 'bold)
              "C")
            ":"
            (if (and (> cc fill-column) (eq ml-selected-window--post-command-hook (selected-window)))
              (propertize (number-to-string cc) 'face 'ml-fill-column-face)
              (number-to-string cc)))))
     " "
     (:eval
        (if (eq ml-selected-window--post-command-hook (selected-window))
          (propertize "P" 'face 'bold)
          "P"))
     ":"
     (:eval (format "%s" (point)))
     " "
     (:eval
        (if (eq ml-selected-window--post-command-hook (selected-window))
          (propertize "S" 'face 'bold)
          "S"))
     ":"
     "%I %z"
     (:eval
        (if
            (and
              (eq ml-this-command ml-last-command)
              (memq ml-this-command ml-deplacement-commands))
          ml-record-eol-type
          (setq ml-record-eol-type (mode-line-eol-desc))))
     " | "
     (:eval
        (if
            (and
              (eq ml-this-command ml-last-command)
              (memq ml-this-command ml-deplacement-commands))
          ml-record-date-time
          (setq ml-record-date-time
            (concat
              (if (eq ml-selected-window--post-command-hook (selected-window))
                (propertize (format-time-string "%m/%d/%Y") 'face 'bold)
                (format-time-string "%m/%d/%Y"))
              (format-time-string " @ %1I:%M %p")))))
     " | "
     (:eval
       (if
            (and
              (eq ml-this-command ml-last-command)
              (memq ml-this-command ml-deplacement-commands))
          ml-record-minor-mode-alist
          (let* (
              (recursive-edit-help-echo "Recursive edit, type C-M-c to get out")
              (help-echo-message--major-mode
                (concat
                  "Major mode\n"
                  "mouse-1: Display major mode menu\n"
                  "mouse-2: Show help for major mode\n"
                  "mouse-3: Toggle major modes"))
              (help-echo-message--minor-mode
                (concat
                  "Minor mode\n"
                  "mouse-1: Display minor mode menu\n"
                  "mouse-2: Show help for minor mode\n"
                  "mouse-3: Toggle minor modes"))
              (active-minor-modes
                (delq nil
                  (mapcar
                    (lambda (x)
                      (let ((car-x (car x)))
                        (when
                            (and
                              (symbolp car-x)
                              (symbol-value car-x)
                              (not (eq 'mc/mode-line (cadr x))))
                          x)))
                    minor-mode-alist)))
              (sorted-list
                (sort
                  active-minor-modes
                  (lambda (x y)
                    (let* (
                        (xname (cadr x))
                        (yname (cadr y)) )
                      (when (symbolp xname) (setq xname (symbol-value xname)))
                      (when (symbolp yname) (setq yname (symbol-value yname)))
                      (when (and (stringp xname) (not (string= "" xname))
                                 (stringp yname) (not (string= "" yname)))
                        (when (eq ?\s (aref xname 0))
                          (setq xname (replace-regexp-in-string "^\s" "" xname)))
                        (when (eq ?\s (aref yname 0))
                          (setq yname (replace-regexp-in-string "^\s" "" yname)))
                        (string< xname yname))))))
              (major-minor-mode-list
                (list
                  (propertize "%[" 'face
                                      (if (eq ml-selected-window--post-command-hook (selected-window))
                                        '(:foreground "red"))
                                   'help-echo recursive-edit-help-echo)
                  `(:propertize ("" mode-name)
                    help-echo ,help-echo-message--major-mode
                    ;; face bold
                    mouse-face mode-line-highlight
                    local-map ,mode-line-major-mode-keymap)
                  (propertize "%]" 'face
                                      (if (eq ml-selected-window--post-command-hook (selected-window))
                                        '(:foreground "red"))
                                   'help-echo recursive-edit-help-echo)
                  " |"
                  '("" mode-line-process)
                  `(:propertize ("" ,sorted-list)
                    ;; face bold
                    mouse-face mode-line-highlight
                    help-echo ,help-echo-message--minor-mode
                    local-map ,mode-line-minor-mode-keymap))) )
            (setq ml-record-minor-mode-alist (format-mode-line major-minor-mode-list))
            major-minor-mode-list)))
     (:eval
        (when (buffer-narrowed-p)
          (concat " |" (propertize "%n" 'help-echo "mouse-2: Remove narrowing from buffer"
            'face 'bold
            'mouse-face 'mode-line-highlight
            'local-map (make-mode-line-mouse-map 'mouse-2 #'mode-line-widen)))))  )))

(defun ml-post-command-hook-fn ()
  (setq ml-selected-window--post-command-hook (selected-window)))

(defun ml-pre-command-hook-fn ()
  (setq ml-selected-window--pre-command-hook (selected-window))
  (setq ml-this-command this-command)
  (setq ml-last-command last-command))

(define-minor-mode ml-mode
"This is a minor-mode for `ml-mode`."
  :init-value nil
  :lighter " ML"
  :keymap nil
  :global t
  :group nil
  (cond
    (ml-mode
      (add-hook 'pre-command-hook 'ml-pre-command-hook-fn)
      (add-hook 'post-command-hook 'ml-post-command-hook-fn)
      (add-hook 'text-mode-hook 'ml-set-format)
      (when (called-interactively-p 'any)
        (message "Globally turned ON `ml-mode'.")))
    (t
      (kill-local-variable 'mode-line-format)
      (remove-hook 'pre-command-hook 'ml-pre-command-hook-fn)
      (remove-hook 'post-command-hook 'ml-post-command-hook-fn)
      (remove-hook 'text-mode-hook 'ml-update-fn)
      (when (called-interactively-p 'any)
        (message "Globally turned OFF `ml-mode'.") ))))

(ml-mode 1) ;; globally turn on minor-mode

(provide 'lawlist-ml)