#!/bin/bash

# 플러그인 버전/이름 공용 정의.
# 단일 출처는 gradle.properties 의 pluginVersion 이며, 이 파일은 그 값을 셸로 넘겨준다.
# 사용법: 다른 스크립트 상단에서 source "$(dirname "$0")/version.sh"
#
# install.sh 는 배포 ZIP 안에 단독으로 들어가므로 이 파일을 쓰지 않고,
# 함께 들어있는 플러그인 ZIP 파일명에서 버전을 역으로 읽는다.

VERSION_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PLUGIN_NAME="rider-pr-filter"
PLUGIN_VERSION="$(sed -n 's/^[[:space:]]*pluginVersion[[:space:]]*=[[:space:]]*//p' "$VERSION_SH_DIR/gradle.properties" | tr -d '[:space:]' | head -1)"

if [ -z "$PLUGIN_VERSION" ]; then
    echo "❌ gradle.properties 에서 pluginVersion 을 찾을 수 없습니다." >&2
    echo "   예) pluginVersion=1.0.1" >&2
    exit 1
fi

PLUGIN_ZIP_NAME="${PLUGIN_NAME}-${PLUGIN_VERSION}.zip"
PLUGIN_ZIP_PATH="build/distributions/${PLUGIN_ZIP_NAME}"
