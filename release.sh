#!/bin/bash

# Rider PR Filter Plugin 릴리즈 스크립트
# Build → Package → Update XML을 순서대로 실행합니다.
# 중간에 실패하면 다음 단계로 진행하지 않습니다.

set -e  # 에러 발생 시 즉시 종료

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 함수: 단계 헤더 출력
print_step() {
    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${BOLD}$1${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 함수: 성공 메시지 출력
print_success() {
    echo ""
    echo -e "${GREEN}✓ $1${NC}"
    echo ""
}

# 함수: 에러 메시지 출력
print_error() {
    echo ""
    echo -e "${RED}✗ $1${NC}"
    echo ""
}

# 시작 메시지
clear
echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   Rider PR Filter Plugin 릴리즈 시작  ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""

# 버전 확인
VERSION=$(grep '^version = ' build.gradle.kts | sed 's/version = "\(.*\)"/\1/')
echo -e "릴리즈 버전: ${YELLOW}${BOLD}v${VERSION}${NC}"
echo ""

# 사용자 확인
read -p "이 버전으로 릴리즈를 진행하시겠습니까? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}릴리즈가 취소되었습니다.${NC}"
    exit 0
fi

# ============================================
# 1단계: 빌드
# ============================================
print_step "1/3 단계: 플러그인 빌드 중..."

# Gradle 버전 확인
GRADLE_VERSION=$(./gradlew --version 2>/dev/null | grep "Gradle" | awk '{print $2}')
echo -e "Gradle 버전: ${GRADLE_VERSION}"
echo ""

# Gradle 9.x 경고
if [[ "$GRADLE_VERSION" == 9.* ]]; then
    echo -e "${YELLOW}⚠️  경고: Gradle 9.x는 호환성 문제가 있을 수 있습니다.${NC}"
    echo -e "${YELLOW}   Gradle 8.5 사용을 권장합니다.${NC}"
    echo ""
fi

# 빌드 실행
./gradlew clean buildPlugin

if [ $? -eq 0 ]; then
    print_success "빌드 완료!"
    PLUGIN_ZIP="build/distributions/rider-pr-filter-${VERSION}.zip"
    if [ -f "$PLUGIN_ZIP" ]; then
        echo -e "생성된 파일: ${GREEN}${PLUGIN_ZIP}${NC}"
        FILE_SIZE=$(du -h "$PLUGIN_ZIP" | cut -f1)
        echo -e "파일 크기: ${GREEN}${FILE_SIZE}${NC}"
    fi
else
    print_error "빌드 실패!"
    echo -e "${RED}에러: Gradle 빌드가 실패했습니다.${NC}"
    echo ""
    echo "문제 해결:"
    echo "  1. JDK 17 이상 확인: java -version"
    echo "  2. Gradle wrapper 업데이트: ./gradlew wrapper --gradle-version 8.5"
    echo "  3. IntelliJ IDEA에서 프로젝트 열어서 빌드 시도"
    echo ""
    exit 1
fi

# ============================================
# 2단계: 패키징
# ============================================
print_step "2/3 단계: 배포용 패키지 생성 중..."

# package.sh 실행
./package.sh

if [ $? -eq 0 ]; then
    print_success "패키징 완료!"
    if [ -f "distribution/rider-pr-filter.zip" ]; then
        PACKAGE_SIZE=$(du -h "distribution/rider-pr-filter.zip" | cut -f1)
        echo -e "패키지 파일: ${GREEN}distribution/rider-pr-filter.zip${NC}"
        echo -e "패키지 크기: ${GREEN}${PACKAGE_SIZE}${NC}"
    fi
else
    print_error "패키징 실패!"
    echo -e "${RED}에러: 패키징 스크립트가 실패했습니다.${NC}"
    exit 1
fi

# ============================================
# 3단계: updatePlugins.xml 업데이트
# ============================================
print_step "3/3 단계: updatePlugins.xml 업데이트 중..."

# GitHub 레포 설정 (필요시 변경)
GITHUB_REPO="junseokoh-dev/rider-pr-filter"

# update-plugin-xml.sh 실행
./update-plugin-xml.sh "$VERSION" "$GITHUB_REPO"

if [ $? -eq 0 ]; then
    print_success "updatePlugins.xml 업데이트 완료!"
else
    print_error "updatePlugins.xml 업데이트 실패!"
    echo -e "${RED}에러: XML 업데이트 스크립트가 실패했습니다.${NC}"
    exit 1
fi

# ============================================
# 완료 메시지
# ============================================
echo ""
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║      🎉 릴리즈 준비 완료! 🎉          ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}생성된 파일:${NC}"
echo -e "  📦 플러그인: ${GREEN}build/distributions/rider-pr-filter-${VERSION}.zip${NC}"
echo -e "  📦 배포 패키지: ${GREEN}distribution/rider-pr-filter.zip${NC}"
echo -e "  📄 업데이트 정보: ${GREEN}updatePlugins.xml${NC}"
echo ""
echo -e "${BOLD}다음 단계:${NC}"
echo ""
echo -e "${YELLOW}1. GitHub Release 생성${NC}"
echo -e "   ${BLUE}gh release create v${VERSION} \\${NC}"
echo -e "   ${BLUE}  build/distributions/rider-pr-filter-${VERSION}.zip \\${NC}"
echo -e "   ${BLUE}  --title \"v${VERSION}\" \\${NC}"
echo -e "   ${BLUE}  --notes \"릴리즈 노트 작성\"${NC}"
echo ""
echo -e "${YELLOW}2. updatePlugins.xml 호스팅${NC}"
echo -e "   GitHub Pages, S3 등에 업로드:"
echo -e "   ${BLUE}https://junseokoh-dev.github.io/rider-pr-filter/updatePlugins.xml${NC}"
echo ""
echo -e "${YELLOW}3. 사용자 안내${NC}"
echo -e "   Rider → Settings → Plugins → ⚙️ → Manage Plugin Repositories"
echo -e "   Custom Repository URL 추가"
echo ""
echo -e "${GREEN}모든 작업이 완료되었습니다!${NC}"
echo ""
