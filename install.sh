#!/bin/bash

# Rider PR Filter Plugin Install Script

set -e

PLUGIN_NAME="rider-pr-filter"
PLUGIN_DIR_NAME="rider-pr-filter"

echo "======================================"
echo "Rider PR Filter Plugin 설치"
echo "======================================"
echo ""

# 이 스크립트는 배포 ZIP 안에 단독으로 들어가므로 gradle.properties 를 읽을 수 없다.
# 대신 실제로 찾은 ZIP 파일명에서 버전을 역으로 읽어 버전 문자열을 하드코딩하지 않는다.
PLUGIN_ZIP=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 후보 경로에서 가장 최근에 수정된 플러그인 ZIP 하나를 고른다.
find_plugin_zip() {
    local dir="$1"
    local newest=""
    local candidate
    for candidate in "$dir/$PLUGIN_NAME"-*.zip; do
        [ -f "$candidate" ] || continue
        if [ -z "$newest" ] || [ "$candidate" -nt "$newest" ]; then
            newest="$candidate"
        fi
    done
    [ -n "$newest" ] && printf '%s' "$newest"
}

# 1. 배포판 경로 확인 (install.sh와 같은 디렉토리)
PLUGIN_ZIP=$(find_plugin_zip "$SCRIPT_DIR")
if [ -n "$PLUGIN_ZIP" ]; then
    echo "📦 배포판 플러그인 발견: $(basename "$PLUGIN_ZIP")"
else
    # 2. 개발 환경 경로 확인
    PLUGIN_ZIP=$(find_plugin_zip "$SCRIPT_DIR/build/distributions")
    if [ -n "$PLUGIN_ZIP" ]; then
        echo "🔨 개발 빌드 플러그인 발견: build/distributions/$(basename "$PLUGIN_ZIP")"
    else
        echo "❌ 플러그인 파일을 찾을 수 없습니다."
        echo ""
        echo "다음 위치를 확인했습니다:"
        echo "  - $SCRIPT_DIR/$PLUGIN_NAME-*.zip (배포판)"
        echo "  - $SCRIPT_DIR/build/distributions/$PLUGIN_NAME-*.zip (개발)"
        echo ""
        echo "개발 환경이라면 먼저 빌드를 실행하세요:"
        echo "  ./build.sh 또는 ./gradlew buildPlugin"
        exit 1
    fi
fi

# rider-pr-filter-1.2.3.zip -> 1.2.3
PLUGIN_ZIP_NAME="$(basename "$PLUGIN_ZIP")"
PLUGIN_VERSION="${PLUGIN_ZIP_NAME#"$PLUGIN_NAME"-}"
PLUGIN_VERSION="${PLUGIN_VERSION%.zip}"
echo "   버전: $PLUGIN_VERSION"

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

# 설치할 Rider 버전 선택
echo "발견된 Rider 설치:"
for i in "${!RIDER_VERSIONS[@]}"; do
    VERSION_NAME=$(basename "${RIDER_VERSIONS[$i]}")
    if [ $i -eq 0 ]; then
        printf "  [%d] %s (최신)\n" "$((i + 1))" "$VERSION_NAME"
    else
        printf "  [%d] %s\n" "$((i + 1))" "$VERSION_NAME"
    fi
done
echo ""

SELECTED_INDEX=""

# 1) 커맨드라인 인자로 번호 또는 버전 이름을 지정한 경우
if [ -n "${1:-}" ]; then
    if [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le ${#RIDER_VERSIONS[@]} ]; then
        SELECTED_INDEX=$(($1 - 1))
    else
        for i in "${!RIDER_VERSIONS[@]}"; do
            if [ "$(basename "${RIDER_VERSIONS[$i]}")" = "$1" ]; then
                SELECTED_INDEX=$i
                break
            fi
        done
    fi

    if [ -z "$SELECTED_INDEX" ]; then
        echo "❌ 잘못된 인자입니다: $1"
        echo "   번호(1-${#RIDER_VERSIONS[@]}) 또는 위 목록의 버전 이름을 지정하세요."
        exit 1
    fi
    echo "→ 인자로 선택됨: $(basename "${RIDER_VERSIONS[$SELECTED_INDEX]}")"
# 2) 대화형 입력으로 직접 선택
elif [ -t 0 ]; then
    while true; do
        if ! read -r -p "설치할 버전 번호를 선택하세요 [1-${#RIDER_VERSIONS[@]}] (기본값: 1): " CHOICE; then
            echo ""
            echo "❌ 설치를 취소했습니다."
            exit 1
        fi
        CHOICE="${CHOICE:-1}"
        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le ${#RIDER_VERSIONS[@]} ]; then
            SELECTED_INDEX=$((CHOICE - 1))
            break
        fi
        echo "  ⚠️  1에서 ${#RIDER_VERSIONS[@]} 사이의 번호를 입력하세요."
    done
# 3) 비대화형 실행(파이프 등)이면 최신 버전으로 진행
else
    SELECTED_INDEX=0
    echo "ℹ️  비대화형 실행이므로 최신 버전을 사용합니다."
    echo "   특정 버전을 설치하려면: ./install.sh <번호|버전이름>"
fi

SELECTED_VERSION=$(basename "${RIDER_VERSIONS[$SELECTED_INDEX]}")

echo ""
echo "→ 선택된 버전: $SELECTED_VERSION"

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
