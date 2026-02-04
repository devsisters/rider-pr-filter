#!/bin/bash

# Rider PR Filter Plugin Install Script

set -e

PLUGIN_NAME="rider-pr-filter"
PLUGIN_VERSION="1.0.0"
PLUGIN_ZIP_NAME="${PLUGIN_NAME}-${PLUGIN_VERSION}.zip"
PLUGIN_DIR_NAME="rider-pr-filter"

echo "======================================"
echo "Rider PR Filter Plugin 설치"
echo "======================================"
echo ""

# 빌드 파일 찾기 (배포판 또는 개발 환경)
PLUGIN_ZIP=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. 배포판 경로 확인 (install.sh와 같은 디렉토리)
if [ -f "$SCRIPT_DIR/$PLUGIN_ZIP_NAME" ]; then
    PLUGIN_ZIP="$SCRIPT_DIR/$PLUGIN_ZIP_NAME"
    echo "📦 배포판 플러그인 발견: $PLUGIN_ZIP_NAME"
# 2. 개발 환경 경로 확인
elif [ -f "$SCRIPT_DIR/build/distributions/$PLUGIN_ZIP_NAME" ]; then
    PLUGIN_ZIP="$SCRIPT_DIR/build/distributions/$PLUGIN_ZIP_NAME"
    echo "🔨 개발 빌드 플러그인 발견: build/distributions/$PLUGIN_ZIP_NAME"
else
    echo "❌ 플러그인 파일을 찾을 수 없습니다."
    echo ""
    echo "다음 위치를 확인했습니다:"
    echo "  - $SCRIPT_DIR/$PLUGIN_ZIP_NAME (배포판)"
    echo "  - $SCRIPT_DIR/build/distributions/$PLUGIN_ZIP_NAME (개발)"
    echo ""
    echo "개발 환경이라면 먼저 빌드를 실행하세요:"
    echo "  ./build.sh 또는 ./gradlew buildPlugin"
    exit 1
fi

# Rider 플러그인 디렉토리 찾기 (macOS)
RIDER_PLUGINS_BASE="$HOME/Library/Application Support/JetBrains"

if [ ! -d "$RIDER_PLUGINS_BASE" ]; then
    echo "❌ JetBrains 설정 디렉토리를 찾을 수 없습니다: $RIDER_PLUGINS_BASE"
    echo "Rider가 설치되어 있는지 확인하세요."
    exit 1
fi

# 설치 가능한 Rider 버전 찾기 (공백이 포함된 경로를 올바르게 처리)
RIDER_VERSIONS=()
while IFS= read -r line; do
    RIDER_VERSIONS+=("$line")
done < <(ls -d "$RIDER_PLUGINS_BASE"/Rider* 2>/dev/null | sort -r)

if [ ${#RIDER_VERSIONS[@]} -eq 0 ]; then
    echo "❌ 설치된 Rider를 찾을 수 없습니다."
    echo ""
    echo "대신 Gradle로 샌드박스 Rider를 실행하시겠습니까?"
    echo "명령어: ./gradlew runIde"
    exit 1
fi

# 가장 최신 버전 자동 선택 (이미 sort -r로 내림차순 정렬됨)
SELECTED_INDEX=0
SELECTED_VERSION=$(basename "${RIDER_VERSIONS[$SELECTED_INDEX]}")

echo "발견된 Rider 설치:"
for i in "${!RIDER_VERSIONS[@]}"; do
    VERSION_NAME=$(basename "${RIDER_VERSIONS[$i]}")
    if [ $i -eq $SELECTED_INDEX ]; then
        echo "  ✓ $VERSION_NAME (자동 선택)"
    else
        echo "    $VERSION_NAME"
    fi
done
echo ""
echo "→ 가장 최신 버전에 설치: $SELECTED_VERSION"

# 플러그인 디렉토리 경로
PLUGINS_DIR="${RIDER_VERSIONS[$SELECTED_INDEX]}/plugins"
INSTALL_DIR="$PLUGINS_DIR/$PLUGIN_DIR_NAME"

echo ""
echo "설치 위치: $INSTALL_DIR"
echo ""

# 기존 플러그인 제거
if [ -d "$INSTALL_DIR" ]; then
    echo "기존 플러그인을 제거합니다..."
    rm -rf "$INSTALL_DIR"
fi

# 플러그인 디렉토리 생성
mkdir -p "$PLUGINS_DIR"

# ZIP 파일 압축 해제
echo "플러그인을 설치합니다..."
unzip -q "$PLUGIN_ZIP" -d "$PLUGINS_DIR"

# lib 디렉토리가 있는지 확인하고 올바른 위치로 이동
if [ -d "$PLUGINS_DIR/$PLUGIN_NAME/lib" ]; then
    # ZIP 내부에 plugin-name 디렉토리가 있는 경우
    if [ "$PLUGINS_DIR/$PLUGIN_NAME" != "$INSTALL_DIR" ]; then
        mv "$PLUGINS_DIR/$PLUGIN_NAME" "$INSTALL_DIR"
    fi
elif [ -f "$PLUGINS_DIR/lib/$PLUGIN_NAME-$PLUGIN_VERSION.jar" ]; then
    # lib 디렉토리가 직접 압축된 경우
    mkdir -p "$INSTALL_DIR"
    mv "$PLUGINS_DIR/lib" "$INSTALL_DIR/"
fi

echo ""
echo "======================================"
echo "✅ 설치 완료!"
echo "======================================"
echo ""
echo "설치된 위치: $INSTALL_DIR"
echo ""
echo "⚠️  Rider를 재시작해야 플러그인이 활성화됩니다."
echo ""
echo "Rider 재시작 후:"
echo "1. PR 뷰를 엽니다"
echo "2. 상단에 검색바가 표시됩니다"
echo "3. 패턴을 입력하고 Enter를 누르면 필터가 적용됩니다"
echo ""
echo "예제 패턴:"
echo "  - *.cs            → C# 파일만"
echo "  - Shop*.*         → Shop으로 시작하는 모든 파일"
echo "  - Shop*.cs;*.json → Shop으로 시작하는 CS 파일과 모든 JSON 파일"
echo ""
