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

REGEN_DEFCONFIG=${REGEN_DEFCONFIG:-"true"}
REGEN_SAVEDEFCONFIG=${REGEN_SAVEDEFCONFIG:-"false"}
TARGET_DEFCONFIG=${TARGET_DEFCONFIG:-"exynos850-a12snsxx_defconfig"}
EMBED_KSU=${EMBED_KSU:-"false"}
PERMISSIVE=${PERMISSIVE:-"true"} # temporary, allow GSI to boot, debug

# KSU info start
KSU_REPO_OWNER=${KSU_REPO_OWNER:-"backslashxx"}
KSU_REPO_BRANCH=${KSU_REPO_BRANCH:-"master"}
KSU_REPO_NAME=${KSU_REPO_NAME:-"KernelSU"}
KSU_TARGET_BRANCH=${KSU_TARGET_BRANCH:-"master"}

if [[ "$EMBED_KSU" == "true" ]]; then
echo "KernelSU embed: owner=$KSU_REPO_OWNER, repo_branch=$KSU_REPO_BRANCH, repo_name=$KSU_REPO_NAME, target_branch=$KSU_TARGET_BRANCH"
curl -LSs "https://raw.githubusercontent.com/${KSU_REPO_OWNER}/${KSU_REPO_NAME}/${KSU_REPO_BRANCH}/kernel/setup.sh" | bash -s ${KSU_TARGET_BRANCH}
KSU_CONFIG="ksu.config"
else
KSU_CONFIG=
fi
# KSU info end

# Permissive section start
if [[ "$PERMISSIVE" == "true" ]]; then
PERMISSIVE_CONFIG="permissive.config"
else
PERMISSIVE_CONFIG=
fi
# Permissive section end

if [[ "$REGEN_SAVEDEFCONFIG" == "true" ]]; then
REGEN_DEFCONFIG=1
fi

if [[ "$REGEN_DEFCONFIG" == "true" ]]; then
make -C $(pwd) O=out $TARGET_DEFCONFIG $PERMISSIVE_CONFIG $KSU_CONFIG -j2
fi

if [[ "$REGEN_SAVEDEFCONFIG" == "true" ]]; then
make -C $(pwd) O=out savedefconfig -j2
mv out/defconfig arch/arm64/configs/$TARGET_DEFCONFIG
rm -rf out
else
make -C $(pwd) O=out -j$(nproc --all)
fi
