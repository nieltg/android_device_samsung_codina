# Device Tree for Samsung Galaxy Ace 2 (GT-I8160)

Notes & Issues:

- Replace `boot.img` inside the zip with `out/target/product/codina/kernel`
  before flashing to your device or it will stuck at Samsung logo.

- There is sdboot variant (install to 2nd & 3rd SD card partitions instead of
  internal, EXPERIMENTAL) in this build system which you can activate by
  making `rootdir/variants/current points` to `rootdir/variants/sdboot` and
  add nieltg/codina-initramfs-sdboot@9e76caf6989d36e38c55c1ca7bfd7625090cfbbf
  repository as `bootable/codinaramfs`.

