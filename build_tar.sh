#!/usr/bin/env bash
#
# Copyright 2026 rsuntk
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# clean stale output dir
rm -rf out; mkdir out

echo "A12s Kernel Cooker 1000"
echo "Original by @Gabriel2392, @clangsdorff, simplified by @rsuntk"
echo ""

GITHEAD=${GITHEAD:-"fc5b87cf"}
BUILD_DATE=${BUILD_DATE:-"19700101_000000_000"}

CODENAME="HiggsBoson"
FILENAME="AP-${CODENAME}-Kernel_5.10-${GITHEAD}-${BUILD_DATE}"

SOURCE_DIR="$(pwd)/sources"
SCRIPTS_DIR="$(pwd)/scripts"
RAMDISK_DIR="${SOURCE_DIR}/ramdisk"
AVB_KEY="${SCRIPTS_DIR}/mkbootimg/gki/testdata/testkey_rsa4096.pem"

IN_DTBO_00="${SOURCE_DIR}/dtbs/a12s_eur_open_w00_r00.dtbo"
IN_DTBO_01="${SOURCE_DIR}/dtbs/a12s_eur_open_w00_r01.dtbo"
IN_DTB="${SOURCE_DIR}/dtbs/s5e3830.dtb"

OUT_DIR="$(pwd)/out"
OUT_RAMDISK_DIR="${OUT_DIR}/ramdisk"
OUT_RAMDISK="${OUT_DIR}/ramdisk.cpio"
OUT_BOOTIMG="${OUT_DIR}/boot.img"
OUT_DTBIMAGE="${OUT_DIR}/dtb.img"
OUT_DTBOIMG="${OUT_DIR}/dtbo.img"
OUT_KERNEL="${SOURCE_DIR}/kernel/Image"

BOOT_PART_SIZE=46137344
DTBO_PART_SIZE=8388608

AVBTOOL="${SCRIPTS_DIR}/avbtool"
MKBOOTIMG="${SCRIPTS_DIR}/mkbootimg/mkbootimg.py"
MKDTBOIMG="${SCRIPTS_DIR}/mkdtboimg.py"

ramdisk_dirs=(
debug_ramdisk
dev
metadata
mnt
proc
second_stage_resources
sys
)

# copy files from ramdisk/ to out/ramdisk/
cp -a "$RAMDISK_DIR/." "$OUT_RAMDISK_DIR/"
for d in "${ramdisk_dirs[@]}"; do
    mkdir -p "$OUT_RAMDISK_DIR/$d"
done

# cook the ramdisk
chmod 750 "$RAMDISK_DIR/init"
chmod 640 "$RAMDISK_DIR/fstab.s5e3830"
chmod 644 "$RAMDISK_DIR/dpolicy"
cp -f "$RAMDISK_DIR/fstab.s5e3830" "$OUT_RAMDISK_DIR/fstab.s5e3830"
cp -f "$RAMDISK_DIR/init" "$OUT_RAMDISK_DIR/init"
cp -f "$RAMDISK_DIR/dpolicy" "$OUT_RAMDISK_DIR/dpolicy"

# pack the ramdisk
echo "- Creating ramdisk.cpio [gzip]"
(cd $OUT_RAMDISK_DIR && find . | sort | cpio --quiet -o -H newc -R root:root | gzip -9 -n -c > $OUT_RAMDISK)

# build dtb.img and dtbo.img
echo "- Creating dtb.img"
python3 "$MKDTBOIMG" create "$OUT_DTBIMAGE" --page_size=2048 --version=0 "$IN_DTB" --id=0 --rev=0 --custom0=0x0 --custom1=0xff
echo "- Creating dtbo.img"
python3 "$MKDTBOIMG" create "$OUT_DTBOIMG" --page_size=2048 --version=0 \
    "$IN_DTBO_00" --id=0 --rev=0 --custom0=0x0 --custom1=0x0 \
    "$IN_DTBO_01" --id=0 --rev=0 --custom0=0x1 --custom1=0x20

echo "- Building boot.img"
# build boot.img
python3 $MKBOOTIMG --header_version 2 \
    --kernel "$OUT_KERNEL" \
    --ramdisk "$OUT_RAMDISK" \
    --dtb "$OUT_DTBIMAGE" \
    --base 0x10000000 --kernel_offset 0x00008000 --ramdisk_offset 0x01000000 \
    --tags_offset 0x00000100 --dtb_offset 0x00000000 --pagesize 2048 \
    --board SRPUE06B013 \
    --cmdline "androidboot.hardware=s5e3830 androidboot.selinux=enforce loop.max_part=7" \
    --os_version 13.0.0 --os_patch_level 2024-10 \
    --output "$OUT_BOOTIMG"

echo "- Signing boot.img [rsa4096]"
# sign the boot.img and dtbo.img
python3 "$AVBTOOL" add_hash_footer --image "$OUT_BOOTIMG" --partition_name boot \
    --partition_size $BOOT_PART_SIZE --algorithm SHA256_RSA4096 --key "$AVB_KEY"

echo "- Signing dtbo.img [rsa4096]"
python3 "$AVBTOOL" add_hash_footer --image "$OUT_DTBOIMG" --partition_name dtbo \
    --partition_size $DTBO_PART_SIZE --algorithm SHA256_RSA4096 --key "$AVB_KEY"

echo "- Compressing img [lz4]"
cd "${OUT_DIR}"
lz4 -B6 --content-size dtbo.img dtbo.img.lz4 > /dev/null 2>&1
lz4 -B6 --content-size boot.img boot.img.lz4 > /dev/null 2>&1

echo "- Compressing img.lz4 [tar]"
tar -cf "${FILENAME}.tar" boot.img.lz4 dtbo.img.lz4
echo "- Odin AP flashable: ${FILENAME}.tar (md5: $(md5sum ./${FILENAME}.tar | cut -d' ' -f1))"
echo "- Uploading to temp.sh"
curl -F "file=@${FILENAME}.tar" https://temp.sh/upload
cd - > /dev/null 2>&1

