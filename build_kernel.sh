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

export ARCH=arm64
export DTC_FLAGS="-@"
export KCFLAGS=-w # temporary, ignore all warnings
export KBUILD_BUILD_USER="rsuntk"
export KBUILD_BUILD_HOST="yukiprjkt-lab"
export LLVM=1
export LLVM_IAS=1

REGEN_DEFCONFIG=${REGEN_DEFCONFIG:-"1"}
REGEN_SAVEDEFCONFIG=${REGEN_SAVEDEFCONFIG:-"0"}
TARGET_DEFCONFIG=${TARGET_DEFCONFIG:-"exynos850-xcover5xx_defconfig"}

if [[ "$REGEN_SAVEDEFCONFIG" == "1" ]]; then
REGEN_DEFCONFIG=1
fi

if [[ "$REGEN_DEFCONFIG" == "1" ]]; then
make -C $(pwd) O=out $TARGET_DEFCONFIG -j2
fi

if [[ "$REGEN_SAVEDEFCONFIG" == "1" ]]; then
make -C $(pwd) O=out savedefconfig -j2
mv out/defconfig arch/arm64/configs/$TARGET_DEFCONFIG
rm -rf out
else
make -C $(pwd) O=out -j$(nproc --all)
fi
