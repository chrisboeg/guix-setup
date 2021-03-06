;; url: https://git.io/JfuIH

(use-modules (gnu)
	     (gnu packages)
	     (gnu services pm))
(use-modules (ice-9 popen)
             (ice-9 rdelim))
(use-modules (nongnu packages linux)
             (nongnu system linux-initrd))
(use-service-modules desktop networking ssh xorg)
(use-package-modules certs)

(operating-system
  (kernel linux)
  (initrd microcode-initrd)
  (firmware (list linux-firmware))
  (locale "en_DK.utf8")
  (timezone "Europe/Copenhagen")
  (keyboard-layout (keyboard-layout "dk"))
  (host-name "sirhc")
  (users (cons* (user-account
                  (name "cb")
                  (comment "cb")
                  (group "users")
                  (home-directory "/home/cb")
                  (supplementary-groups
                    '("wheel" "netdev" "audio" "video")))
                %base-user-accounts))
  (packages
    (append (map specification->package
	      '(
		"nss-certs"
		"vim"
		"git"
		"icecat"
		"wget"
		"udevil"
		"emacs"
		"tlp"
		"restic"
		"fuse"
		"alacritty"
		"gnupg"
		"openssh"
		"wireguard-tools"
		"pulseaudio"
		"pavucontrol"
		"sbcl"
		"xclip"
		"slock"
		"wget"
		"unzip"
		"zip"
		"acpi"
		"cryptsetup"
		"libreoffice"
		"inkscape"
		"gimp"
		"xmodmap"
		"xinit"
		"xset"
		"xsetroot"
		"xev"
		"curl"
		"zathura-pdf-mupdf"
		))
	    %base-packages))
  (services
    (append
      (list (service openssh-service-type)
	    (screen-locker-service slock "slock")
	    (service tlp-service-type
                    (tlp-configuration
                     (cpu-boost-on-ac? #t)))
	    (service thermald-service-type)
            (set-xorg-configuration
              (xorg-configuration
                (keyboard-layout keyboard-layout))))
      %desktop-services))
  (bootloader
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (target "/boot/efi")
      (keyboard-layout keyboard-layout)))
  (swap-devices '("/swapfile"))
  (mapped-devices
    (list (mapped-device
            (source
              (uuid (let* ((port (open-input-pipe "blkid -s UUID -o value /dev/sda2"))
	      		   (str (read-line port)))
	      	      (close-pipe port)
	      	      str)))
            (target "cryptroot")
            (type luks-device-mapping))))
  (file-systems
    (cons* (file-system
             (mount-point "/boot/efi")
	     (device (uuid 
	               (let* ((port (open-input-pipe "blkid -s UUID -o value /dev/sda1"))
	                      (str (read-line port)))
	                 (close-pipe port)
	                 str)
		       'fat32))
             (type "vfat"))
           (file-system
             (mount-point "/")
	     (device "/dev/mapper/cryptroot")
             (type "ext4")
	     (dependencies mapped-devices))
           %base-file-systems)))
