#!/bin/bash

# Rider PR Filter Plugin Build Script

echo "======================================"
echo "Rider PR Filter Plugin 빌드 시작"
echo "======================================"

# Gradle Wrapper 버전 확인
GRADLE_VERSION=$(./gradlew --version 2>/dev/null | grep "Gradle" | awk '{print $2}')
echo "현재 Gradle 버전: $GRADLE_VERSION"

# Gradle 9 미만 차단
# IntelliJ Platform Gradle Plugin 2.x가 Gradle 9.0+ 를 요구한다.
GRADLE_MAJOR="${GRADLE_VERSION%%.*}"
if [[ "$GRADLE_MAJOR" =~ ^[0-9]+$ ]] && (( GRADLE_MAJOR < 9 )); then
    echo "❌ Gradle 9.0 이상이 필요합니다 (현재: $GRADLE_VERSION)."
    echo "   gradle/wrapper/gradle-wrapper.properties의 distributionUrl을 확인하세요."
    exit 1
fi

# 빌드 실행
echo ""
echo "플러그인 빌드 중..."
./gradlew buildPlugin

if [ $? -eq 0 ]; then
    echo ""
    echo "======================================"
    echo "✅ 빌드 성공!"
    echo "======================================"
    echo ""
    echo "생성된 파일: build/distributions/rider-pr-filter-1.0.0.zip"
    echo ""
    echo "설치 방법:"
    echo ""
    echo "방법 1) 자동 설치 (권장)"
    echo "  ./install.sh"
    echo ""
    echo "방법 2) 샌드박스 Rider에서 테스트"
    echo "  ./run.sh"
    echo ""
    echo "방법 3) 수동 설치"
    echo "  1. Rider 열기"
    echo "  2. Settings > Plugins"
    echo "  3. 톱니바퀴 > Install Plugin from Disk..."
    echo "  4. build/distributions/rider-pr-filter-1.0.0.zip 선택"
    echo "  5. Rider 재시작"
    echo ""

    # 자동 설치 여부 물어보기
    read -p "지금 자동 설치를 진행하시겠습니까? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./install.sh
    fi
    echo ""
else
    echo ""
    echo "======================================"
    echo "❌ 빌드 실패"
    echo "======================================"
    echo ""
    echo "문제 해결:"
    echo "1. JDK 21 확인: java -version (IntelliJ Platform 2024.2+ 는 JDK 21 필요)"
    echo "2. Gradle wrapper 업데이트: ./gradlew wrapper --gradle-version 9.7.1"
    echo "3. IntelliJ IDEA에서 프로젝트 열어서 빌드 시도"
    echo ""
    exit 1
fi
