#!/bin/bash

# updatePlugins.xml 자동 업데이트 스크립트
# 사용법: ./update-plugin-xml.sh [새버전] [GitHub레포]
# 예제: ./update-plugin-xml.sh 1.0.1 junseokoh-dev/rider-pr-filter

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_PLUGINS_XML="${SCRIPT_DIR}/updatePlugins.xml"
BUILD_GRADLE="${SCRIPT_DIR}/build.gradle.kts"

# 함수: 사용법 출력
usage() {
    echo "사용법: $0 [새버전] [GitHub레포]"
    echo ""
    echo "인자:"
    echo "  새버전      - 새 플러그인 버전 (예: 1.0.1)"
    echo "  GitHub레포  - GitHub 레포지토리 (예: junseokoh-dev/rider-pr-filter)"
    echo ""
    echo "예제:"
    echo "  $0 1.0.1 junseokoh-dev/rider-pr-filter"
    echo ""
    echo "인자 없이 실행하면 build.gradle.kts에서 버전을 자동으로 읽어옵니다."
    exit 1
}

# build.gradle.kts에서 현재 버전 읽기
get_version_from_gradle() {
    if [ ! -f "$BUILD_GRADLE" ]; then
        echo -e "${RED}오류: build.gradle.kts 파일을 찾을 수 없습니다.${NC}"
        exit 1
    fi

    VERSION=$(grep '^version = ' "$BUILD_GRADLE" | sed 's/version = "\(.*\)"/\1/')

    if [ -z "$VERSION" ]; then
        echo -e "${RED}오류: build.gradle.kts에서 버전을 찾을 수 없습니다.${NC}"
        exit 1
    fi

    echo "$VERSION"
}

# build.gradle.kts에서 IDE 버전 범위 읽기
get_ide_versions_from_gradle() {
    if [ ! -f "$BUILD_GRADLE" ]; then
        echo -e "${RED}오류: build.gradle.kts 파일을 찾을 수 없습니다.${NC}"
        exit 1
    fi

    SINCE_BUILD=$(grep 'sinceBuild.set(' "$BUILD_GRADLE" | sed 's/.*sinceBuild.set("\(.*\)").*/\1/')
    UNTIL_BUILD=$(grep 'untilBuild.set(' "$BUILD_GRADLE" | sed 's/.*untilBuild.set("\(.*\)").*/\1/')

    if [ -z "$SINCE_BUILD" ] || [ -z "$UNTIL_BUILD" ]; then
        echo -e "${RED}오류: build.gradle.kts에서 IDE 버전 정보를 찾을 수 없습니다.${NC}"
        exit 1
    fi

    echo "$SINCE_BUILD:$UNTIL_BUILD"
}

# 인자 파싱
NEW_VERSION="${1}"
GITHUB_REPO="${2:-junseokoh-dev/rider-pr-filter}"

# 버전이 지정되지 않으면 build.gradle.kts에서 읽기
if [ -z "$NEW_VERSION" ]; then
    echo -e "${YELLOW}버전이 지정되지 않았습니다. build.gradle.kts에서 버전을 읽어옵니다...${NC}"
    NEW_VERSION=$(get_version_from_gradle)
    echo -e "${GREEN}감지된 버전: ${NEW_VERSION}${NC}"
fi

# IDE 버전 범위 읽기
IDE_VERSIONS=$(get_ide_versions_from_gradle)
SINCE_BUILD=$(echo "$IDE_VERSIONS" | cut -d':' -f1)
UNTIL_BUILD=$(echo "$IDE_VERSIONS" | cut -d':' -f2)

echo -e "${GREEN}IDE 버전 범위: ${SINCE_BUILD} ~ ${UNTIL_BUILD}${NC}"

# updatePlugins.xml 파일 존재 확인
if [ ! -f "$UPDATE_PLUGINS_XML" ]; then
    echo -e "${RED}오류: updatePlugins.xml 파일을 찾을 수 없습니다: ${UPDATE_PLUGINS_XML}${NC}"
    exit 1
fi

# GitHub Release URL 생성
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${NEW_VERSION}/rider-pr-filter-${NEW_VERSION}.zip"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}updatePlugins.xml 업데이트 중...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "새 버전:    ${YELLOW}${NEW_VERSION}${NC}"
echo -e "다운로드 URL: ${YELLOW}${DOWNLOAD_URL}${NC}"
echo -e "IDE 버전:   ${YELLOW}${SINCE_BUILD} ~ ${UNTIL_BUILD}${NC}"
echo ""

# XML 파일 백업
cp "$UPDATE_PLUGINS_XML" "${UPDATE_PLUGINS_XML}.bak"
echo -e "${GREEN}✓ 백업 생성: ${UPDATE_PLUGINS_XML}.bak${NC}"

# sed를 사용하여 XML 업데이트 (macOS 호환)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS용 sed
    sed -i '' "s|version=\"[^\"]*\"|version=\"${NEW_VERSION}\"|g" "$UPDATE_PLUGINS_XML"
    sed -i '' "s|url=\"[^\"]*\"|url=\"${DOWNLOAD_URL}\"|g" "$UPDATE_PLUGINS_XML"
    sed -i '' "s|since-build=\"[^\"]*\"|since-build=\"${SINCE_BUILD}\"|g" "$UPDATE_PLUGINS_XML"
    sed -i '' "s|until-build=\"[^\"]*\"|until-build=\"${UNTIL_BUILD}\"|g" "$UPDATE_PLUGINS_XML"
else
    # Linux용 sed
    sed -i "s|version=\"[^\"]*\"|version=\"${NEW_VERSION}\"|g" "$UPDATE_PLUGINS_XML"
    sed -i "s|url=\"[^\"]*\"|url=\"${DOWNLOAD_URL}\"|g" "$UPDATE_PLUGINS_XML"
    sed -i "s|since-build=\"[^\"]*\"|since-build=\"${SINCE_BUILD}\"|g" "$UPDATE_PLUGINS_XML"
    sed -i "s|until-build=\"[^\"]*\"|until-build=\"${UNTIL_BUILD}\"|g" "$UPDATE_PLUGINS_XML"
fi

echo -e "${GREEN}✓ updatePlugins.xml 업데이트 완료!${NC}"
echo ""

# 변경사항 확인
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}업데이트된 내용:${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
grep -A 2 '<plugin' "$UPDATE_PLUGINS_XML" | head -n 3
echo ""

# 다음 단계 안내
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}다음 단계:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "1. 플러그인 빌드: ${YELLOW}./gradlew buildPlugin${NC}"
echo -e "2. GitHub Release 생성: ${YELLOW}v${NEW_VERSION}${NC} 태그로"
echo -e "3. 빌드된 ZIP 파일을 Release에 업로드:"
echo -e "   ${YELLOW}build/distributions/rider-pr-filter-${NEW_VERSION}.zip${NC}"
echo -e "4. updatePlugins.xml을 웹서버에 업로드 (GitHub Pages, S3 등)"
echo ""
echo -e "${GREEN}완료!${NC}"
