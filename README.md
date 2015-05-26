# Device Tree for GT-I8160 (codina)

I assume you have been familiar with CyanogenMod ROM development since this device tree is still buggy and I'm accepting pull requests... :D

Issues I've encountered:

- Creating a new user (multi-user mode) make the system crash.
- The recorded video is green, but the audio is recorded well.
- Flashlight is slow since it use camera interface. (should use sysfs interface)

__NOTE:__ This device tree supports 2 different build variant: default & sdboot variant. Use _default variant_ if you want to install the build into internal partition, but use _sdboot variant_ if you want to install the build into SD card which hacks is explained [here](https://github.com/nieltg/codina-initramfs-sdboot).

## Step 1: Local Manifests & Sync

These are repositories I use. You can put this file on `.repo/local_manifests/codina.xml` or any name you want to use.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
	
	<!-- kernels & bootables -->
	<project path="kernel/codina/ace2nutzer" name="ace2nutzer/Samsung_STE_Kernel" revision="3.0.101" />
	
	<!-- cm11 base -->
	<project path="vendor/samsung/u8500-common" name="TeamCanjica/android_vendor_samsung_u8500-common" revision="cm-11.0" />
	
	<!-- cm12 custom -->
	<project path="device/samsung/codina" name="nieltg/android_device_samsung_codina" />
	<project path="device/samsung/codina_sdboot" name="nieltg/android_device_samsung_codina_sdboot" />
	
	<project path="hardware/u8500" name="nieltg/android_hardware_u8500" revision="cm-12.0" />
	
</manifest>
```

## Step 2: Preparation

Some repositories must be patched before building. I've provided a script to do that. You can execute these commands on your build root.

```bash
. build/envsetup.sh ; export USE_CCACHE=1
codina-patch-apply
```

## Step 3: Compile

You can execute this command to compile. On my system, it tooks about 4-5 hours to get a full build.

```bash
brunch codina
```

If you want to compile _sdboot_ variant ROM, use this command instead.

```bash
brunch codina_sdboot
```

## Step 4: Modify Zip

This device tree products flashable zip with invalid `boot.img` which is not the kernel. You must change it with raw kernel which is found at `out/target/product/codina/kernel`. Rename it to `boot.img` and put it back to the zip.

For sdboot build (and you have installed sdboot kernel), you can remove `boot.img` and its flashing routine in `update-script` to prevent flashing same kernel again and again. You also can remove things are match with this pattern: `, \"capabilities\", (.*), \"selabel\", \"(.*)\"` to prevent flashing errors if you are using older CWM like me.

Then, you can __backup__ & flash the zip. __You do it all at your own risk!__

