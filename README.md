# Device Tree for GT-I8160 (codina)

I assume you have been familiar with CyanogenMod ROM development since this device tree is still buggy and I'm accepting pull requests... :D

Issues I've encountered:

- InCallUI is shown very late & the Settings app is laggy.
- The recorded video is green, but the audio is recorded well.
- Flashlight is slow since it use camera interface. (should use sysfs interface)

__NOTE:__ This device tree supports 2 different build variant: default & sdboot variant. Use _default variant_ if you want to install the build into internal partition, but use _sdboot variant_ if you want to install the build into SD card which hacks is explained [here](https://github.com/nieltg/codina-initramfs-sdboot).

Personally, I test my builds by installing them to my SD card. If you don't use _sdboot_, you can just modify `rootdir/variants/current` symlink and point it to `default` instead of `sdboot`. If you want to remove _sdboot_ completely, read these commits: [3b60524](https://github.com/nieltg/android_device_samsung_codina/commit/3b60524db27edfbd4204b23fd57847147471f4ce), [d426316](https://github.com/nieltg/android_device_samsung_codina/commit/d42631627a98e3fe56cbddf84204352efaa3b140), and [3c3bfa5](https://github.com/nieltg/android_device_samsung_codina/commit/3c3bfa57a89e57d9a780b152e3f9c53c33bd7c98) then revert things associated with sdboot.

## Step 1: Local Manifests & Sync

These are repositories I use. You can put this file on `.repo/local_manifests/codina.xml` or any name you want to use.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
	
	<!-- kernels & bootables -->
	<project path="kernel/codina/ace2nutzer" name="ace2nutzer/Samsung_STE_Kernel" revision="3.0.101" />
	<project path="bootable/codinaramfs" name="nieltg/codina-initramfs-sdboot" revision="master" />
	
	<!-- cm11 base -->
	<project path="vendor/samsung/u8500-common" name="Dhoine/android_vendor_samsung_u8500-common" revision="cm-11.0" />
	
	<!-- cm12 custom -->
	<project path="device/samsung/codina" name="nieltg/android_device_samsung_codina" />
	<project path="hardware/u8500" name="nieltg/android_hardware_u8500" revision="cm-12.0" />
	
</manifest>
```

## Step 2: Preparation

Some repositories must be patched before building. I've provided a script to do that. You can execute these commands on your build root.

You also should check `rootdir/variants/current` symlink in the device tree. Point it to `default` if you don't want to build _sdboot variant_ which explanation you can read [here](https://github.com/nieltg/codina-initramfs-sdboot).

```bash
. build/envsetup.sh ; export USE_CCACHE=1
device/samsung/codina/patches/patch-apply
```

## Step 3: Compile

Like usual, there is nothing special here. On my system, it tooks about 4-5 hours to get a full build.

```bash
brunch codina
```

## Step 4: Modify Zip

This device tree products flashable zip with invalid `boot.img` which is not the kernel. You must change it with raw kernel which is found at `out/target/product/codina/kernel`. Rename it to `boot.img` and put it back to the zip.

For sdboot build (and you have installed sdboot kernel), you can remove `boot.img` and its flashing routine in `update-script` to prevent flashing same kernel again and again. You also can remove things are match with this pattern: `, \"capabilities\", (.*), \"selabel\", \"(.*)\"` to prevent flashing errors if you are using older CWM like me.

Then, you can __backup__ & flash the zip. __You do it all at your own risk!__

