# Quick Start Guide

## 빠른 시작

### 1. 빌드하기

#### Option A: 빌드 스크립트 사용 (권장)

```bash
cd /Users/devsisters/dev/rider-pr-filter
./build.sh
```

#### Option B: Gradle 직접 사용

```bash
# Gradle 8.5 사용 (SDKMAN 설치 필요)
sdk install gradle 8.5
sdk use gradle 8.5

# 빌드
gradle buildPlugin

# 또는 wrapper 사용
./gradlew buildPlugin
```

#### Option C: IntelliJ IDEA 사용

1. IntelliJ IDEA에서 `/Users/devsisters/dev/rider-pr-filter` 프로젝트 열기
2. Gradle 탭에서 `Tasks` > `intellij` > `buildPlugin` 더블클릭
3. `build/distributions/` 폴더에서 ZIP 파일 확인

### 2. Rider에 설치하기

1. Rider 열기
2. `Settings` (⌘,) > `Plugins` 이동
3. 톱니바퀴 아이콘 ⚙️ 클릭
4. `Install Plugin from Disk...` 선택
5. `build/distributions/rider-pr-filter-1.0.0.zip` 선택
6. `OK` 클릭
7. **Rider 재시작**

### 3. 사용하기

#### VCS Toolbar에서 사용

1. VCS 창 (⌘9) 열기
2. Toolbar에서 **Filter** 버튼 클릭 (🔍 아이콘)
3. 패턴 입력 (예: `*.cs` 또는 `*.cs;*.json`)
4. OK 클릭

#### Settings에서 설정

1. `Settings` > `Tools` > `PR File Filter`
2. **Enable file filtering** 체크
3. **Include patterns**: 포함할 파일 (예: `*.cs;*.json`)
4. **Exclude patterns**: 제외할 파일 (예: `*.meta;*.asset;*.prefab`)
5. Apply/OK

### 4. 패턴 예시

#### Unity 개발자용
```
Include: *.cs;*.json;*.shader
Exclude: *.meta;*.asset;*.prefab;*.unity
```

#### C# 코드만 보기
```
Include: *.cs
Exclude:
```

#### 설정 파일만 보기
```
Include: *.json;*.xml;*.yaml;*.yml
Exclude:
```

## Gradle 9.x 문제 해결

현재 시스템에 Gradle 9.2.1이 설치되어 있습니다. IntelliJ 플러그인과 호환성 문제가 있을 수 있습니다.

### 해결 방법 1: SDKMAN으로 Gradle 8.5 설치

```bash
# SDKMAN 설치 (아직 없다면)
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Gradle 8.5 설치 및 사용
sdk install gradle 8.5
sdk use gradle 8.5

# 빌드
cd /Users/devsisters/dev/rider-pr-filter
gradle buildPlugin
```

### 해결 방법 2: Homebrew로 설치

```bash
# Gradle 8.x 설치
brew install gradle@8

# PATH 설정
export PATH="/opt/homebrew/opt/gradle@8/bin:$PATH"

# 빌드
cd /Users/devsisters/dev/rider-pr-filter
gradle buildPlugin
```

### 해결 방법 3: IntelliJ IDEA 사용 (가장 쉬움)

IntelliJ IDEA는 자체 Gradle 래퍼를 사용하므로 버전 충돌이 없습니다.

1. IntelliJ IDEA 실행
2. `Open` > `/Users/devsisters/dev/rider-pr-filter` 선택
3. Gradle 프로젝트가 자동으로 로드됨
4. `Build` > `Build Project` 또는 Gradle 탭에서 `buildPlugin` 실행

## 문제 해결

### 빌드 실패 시

```bash
# Gradle 버전 확인
gradle --version

# Java 버전 확인 (17 이상 필요)
java -version

# Gradle 캐시 정리
cd /Users/devsisters/dev/rider-pr-filter
rm -rf .gradle build
gradle clean
gradle buildPlugin
```

### 플러그인이 Rider에서 인식되지 않을 때

1. ZIP 파일이 올바르게 생성되었는지 확인
2. Rider 버전이 2023.3 이상인지 확인
3. Rider를 완전히 종료하고 재시작
4. `Help` > `Find Action` > "Registry" 검색 > 플러그인 관련 설정 확인

### 필터가 작동하지 않을 때

현재 버전은 IntelliJ Platform API 제한으로 인해 PR 화면의 파일 목록을 직접 필터링하지 못할 수 있습니다. 대신:

1. Settings에서 패턴 설정
2. VCS Changes 뷰에서 필터 적용 확인
3. 향후 업데이트에서 PR 직접 필터링 기능 추가 예정

## 다음 단계

- 플러그인을 프로젝트 팀원들과 공유
- GitHub에 업로드하여 버전 관리
- JetBrains Marketplace에 게시 고려
- 피드백을 바탕으로 기능 개선

## 도움이 필요하면

- `README.md` - 전체 문서
- `build.sh` - 자동 빌드 스크립트
- 소스 코드: `src/main/kotlin/com/devsisters/prfilter/`
