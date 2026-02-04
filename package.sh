#!/bin/bash

# Rider PR Filter Plugin Package Script
# 배포용 ZIP 파일을 생성합니다.

set -e

echo "======================================"
echo "Rider PR Filter Plugin 패키징"
echo "======================================"
echo ""

PLUGIN_ZIP="build/distributions/rider-pr-filter-1.0.0.zip"
PACKAGE_DIR="build/package"
DISTRIBUTION_DIR="distribution"
OUTPUT_ZIP="$DISTRIBUTION_DIR/rider-pr-filter.zip"

# 1. 빌드 파일 확인
if [ ! -f "$PLUGIN_ZIP" ]; then
    echo "❌ 빌드 파일을 찾을 수 없습니다: $PLUGIN_ZIP"
    echo "먼저 ./build.sh를 실행하여 플러그인을 빌드하세요."
    exit 1
fi

# 2. 디렉토리 준비
echo "1. 디렉토리 준비 중..."
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"
mkdir -p "$DISTRIBUTION_DIR"

# 3. 파일 복사
echo "2. 파일 복사 중..."
cp "$PLUGIN_ZIP" "$PACKAGE_DIR/"
cp install.sh "$PACKAGE_DIR/"
chmod +x "$PACKAGE_DIR/install.sh"

# 4. ZIP 파일 생성
echo "3. 배포용 ZIP 생성 중..."
rm -f "$OUTPUT_ZIP"
cd "$PACKAGE_DIR"
zip -q "../../distribution/rider-pr-filter.zip" rider-pr-filter-1.0.0.zip install.sh
cd ../..

echo "✅ 패키징 완료"
echo ""

# 5. 결과 출력
FILE_SIZE=$(du -h "$OUTPUT_ZIP" | cut -f1)
echo "======================================"
echo "✅ 배포 패키지 생성 완료!"
echo "======================================"
echo ""
echo "파일: $OUTPUT_ZIP"
echo "크기: $FILE_SIZE"
echo ""
echo "배포 방법:"
echo "1. $OUTPUT_ZIP 파일을 배포"
echo "2. 사용자가 압축 해제"
echo "3. ./install.sh 실행"
echo ""
echo "테스트:"
echo "  cd /tmp"
echo "  unzip $(pwd)/$OUTPUT_ZIP"
echo "  ./install.sh"
echo ""
