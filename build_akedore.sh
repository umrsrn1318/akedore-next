#!/bin/bash
# build_akedore.sh [ksu|nosu] - build AKEDORE Next kernel for POCO F1 (beryllium).
# EDITION=AutoBoost: GPU game boost (710 -> 802 MHz) on by default; empty = Standard (710 MHz, boost off).
# PROFILE=std (default: GPU 710 MHz, all thermal zones) or PROFILE=oc (GPU 802 MHz, relaxed thermal).
# Needs an LLVM/clang toolchain (tested: Neutron clang 24) in $CLANG_DIR/bin, plus aarch64/arm GNU binutils prefixes.
# Output: out[-nosu]/arch/arm64/boot/Image.gz-dtb (flash with AnyKernel3).
set -e
VARIANT=${1:-ksu}; S=$(cd "$(dirname "$0")" && pwd)
case $VARIANT in ksu) O=out ;; nosu) O=out-nosu ;; *) echo "usage: $0 [ksu|nosu]"; exit 1 ;; esac
PROFILE=${PROFILE:-std}
ED=${EDITION:+-$EDITION}; [ -n "$ED" ] && AB=-e || AB=-d; O=$O$ED
case $PROFILE in std) DTCF= ;; oc) DTCF=-DFSOCIETY_OC; O=$O-oc ;; *) echo "PROFILE=std|oc"; exit 1 ;; esac
[ -n "$CLANG_DIR" ] && export PATH=$CLANG_DIR/bin:$PATH
[ $VARIANT = ksu ] && [ ! -f "$S/KernelSU/kernel/Makefile" ] && git -C "$S" submodule update --init
M="make -C $S -j$(nproc) O=$O ARCH=arm64 SUBARCH=arm64 LLVM=1 LLVM_IAS=1 CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm HOSTCC=gcc HOSTCXX=g++ OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu- FSOCIETY_DTC_CPP_FLAGS=$DTCF"
export KCFLAGS="-Wno-error"
$M beryllium_defconfig
if [ $VARIANT = ksu ]; then
  # ReSukiSU v4.2.0-rc3 (KernelSU submodule), manual hooks; SUSFS build: -d KSU_MANUAL_HOOK -e KSU_SUSFS
  "$S/scripts/config" --file "$S/$O/.config" --set-str LOCALVERSION "-akedore-next-v1$ED-KSU" $AB FSOCIETY_GPU_AUTOBOOST -e KSU -e KSU_MANUAL_HOOK -d KSU_SUSFS \
    -d KSU_KPROBES_KSUD -d KSU_HACK_ARM64_BRANCH_LINK -d KSU_TAMPER_SYSCALL_TABLE
else
  "$S/scripts/config" --file "$S/$O/.config" --set-str LOCALVERSION "-akedore-next-v1$ED-NonKSU" $AB FSOCIETY_GPU_AUTOBOOST -d KSU
fi
$M olddefconfig
$M
ls -la "$S/$O/arch/arm64/boot/Image.gz-dtb"
