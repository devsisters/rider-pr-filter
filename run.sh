#!/bin/bash

# Rider PR Filter Plugin - Run in Sandbox

echo "======================================"
echo "샌드박스 Rider 실행"
echo "======================================"
echo ""
echo "플러그인이 자동으로 로드된 Rider가 실행됩니다."
echo ""

# 빌드가 안 되어있으면 먼저 빌드
if [ ! -f "build/distributions/rider-pr-filter-1.0.0.zip" ]; then
    echo "빌드 파일이 없습니다. 먼저 빌드를 실행합니다..."
    ./gradlew buildPlugin
    if [ $? -ne 0 ]; then
        echo "❌ 빌드 실패"
        exit 1
    fi
    echo ""
fi

echo "Rider를 시작합니다..."
echo ""

# runIde 실행 (백그라운드로 실행)
./gradlew runIde
