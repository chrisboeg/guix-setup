;; place at ~/.config/guix/channels.scm or /etc/guix/channels.scm
;; use `hash -r` to make sure previous locations are forgotten
;; url: 

(cons* (channel
        (name 'nonguix)
        (url "https://gitlab.com/nonguix/nonguix"))
       %default-channels)
