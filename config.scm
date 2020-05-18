;; url: https://git.io/JfuIH

(use-modules (gnu)
	     (gnu packages))
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
	      '("nss-certs" "vim" "git" "icecat" "wget"))
	    %base-packages))
  (services
    (append
      (list (service gnome-desktop-service-type)
            (service openssh-service-type)
            (set-xorg-configuration
              (xorg-configuration
                (keyboard-layout keyboard-layout))))
      %desktop-services)) (bootloader
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (target "/boot/efi")
      (keyboard-layout keyboard-layout)))
  (swap-devices (list "/dev/sda2"))
  (file-systems
    (cons* (file-system
             (mount-point "/boot/efi")
             (device (uuid (system "blkid -s UUID -o value /dev/sda1") ;46A7-ECCA"
			   'fat32))
             (type "vfat"))
           (file-system
             (mount-point "/")
             (device
               (uuid (system "blkid -s UUID -o value /dev/sda3") ;17cac86f-e36c-4757-a21b-44ec5c12a2fd
                     'ext4))
             (type "ext4"))
           %base-file-systems)))
