# volumio-cyw4373e-drivers
Update drivers for cyw4373e wireless/bluetooth module for raspberry pi

Source code and documentation for the cyw4373e drivers are available here:
https://www.ezurio.com/documentation/application-note-integrating-sterling-lwb5-usb-dongle-with-raspberry-pi-os-on-rpi5

Whenever new sources for the cyw4373e device are available, they need to be manually downloaded, unpacked, and placed in `source_files`, then update `CYW4373E_SOURCES` associative array in `re-build.sh` to match the new condition, if necessary.

## How does it work

To cross-compile the cyw4373e drivers, we need to first cross-compile the whole kernel for each architecture, then the `re-build.sh` script can follow the original instruction to compile the drivers. The resulting modules are then installed into a custom path and finally compressed into a tarball.

First run the download script from the project root directory. This will download the Linux kernel for the given version (version can be set inside the script):

```bash
# Download and build
$ build_script/download_build.sh
```

Once the Linux Kernel sources are downloaded, run the `re-build.sh` script to compile the kernels, drivers and package them into a single tarball:

```bash
# Build using current sources (no download)
$ build_script/re-build.sh
```

Resulting tarball is finally placed in `output` directory.

There is no need to cleanup or download again the source if you need to run `re-build.sh` again. The script will clean the building environment itself.

**IMPORTANT**: do not forget to run `depmod -a` **after** unpacking the modules tarball over the destination image, othewise the kernel will still use the stock modules and cyw4373e won't work correctly.