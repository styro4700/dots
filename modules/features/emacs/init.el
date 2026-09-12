;; -*- lexical-binding: t; -*-

(use-package emacs
  :init
  (setq inhibit-startup-message t
        make-backup-files nil
        ring-bell-function 'ignore
        use-short-answers t
        display-line-numbers-type 'relative

        ;; sane editing defaults
        indent-tabs-mode nil
        tab-width 4
        require-final-newline t
        sentence-end-double-space nil

        ;; stop scattering clutter files everywhere
        auto-save-default nil
        create-lockfiles nil

        ;; ui noise reduction
        use-dialog-box nil
        frame-resize-pixelwise t)

  ;; --- THEME ---
  (add-to-list 'default-frame-alist '(background-color . "#000000"))
  (add-to-list 'default-frame-alist '(foreground-color . "#d0d0d0"))
  (add-to-list 'default-frame-alist '(cursor-color     . "#d0d0d0"))

  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (global-display-line-numbers-mode t)

  :custom-face
  (default              ((t (:background "#000000" :foreground "#d0d0d0"))))
  (cursor               ((t (:background "#d0d0d0"))))
  (fringe               ((t (:background "#000000"))))
  (region               ((t (:background "#3a3a3a"))))
  (mode-line            ((t (:background "#1a1a1a" :foreground "#d0d0d0" :box nil))))
  (mode-line-inactive   ((t (:background "#000000" :foreground "#505050" :box nil))))
  (line-number          ((t (:foreground "#404040" :background "#000000"))))
  (line-number-current-line ((t (:foreground "#d0d0d0" :background "#000000"))))

  ;; syntax highlighting grayscale
  (font-lock-comment-face        ((t (:foreground "#707070" :italic t))))
  (font-lock-string-face         ((t (:foreground "#a0a0a0"))))
  (font-lock-keyword-face        ((t (:foreground "#d0d0d0" :bold t))))
  (font-lock-function-name-face  ((t (:foreground "#e0e0e0" :bold t))))
  (font-lock-variable-name-face  ((t (:foreground "#d0d0d0"))))
  (font-lock-type-face           ((t (:foreground "#c0c0c0"))))
  (font-lock-constant-face       ((t (:foreground "#c0c0c0")))))

(use-package no-littering
  :ensure t)

;;(use-package evil
;;  :ensure t
;;  :init
;;  (setq evil-want-integration t
;;        evil-want-keybinding nil)   ; let evil-collection manage keybindings instead
;;  :config
;;  (evil-mode 1))
;;
;;(use-package evil-collection
;;  :ensure t
;;  :after evil
;;  :config
;;  (evil-collection-init))          ; consistent evil bindings in dired, magit, etc.

(use-package avy
  :ensure t
  :bind ("M-j" . avy-goto-char-in-line))

(use-package vertico
  :ensure t
  :init (vertico-mode))

(use-package orderless :ensure t
  :custom (completion-styles '(orderless basic)))

(use-package marginalia
  :ensure t
  :init (marginalia-mode))

(use-package which-key
  :ensure t
  :init (which-key-mode))

(use-package magit
  :ensure t)
