# Quick Start Guide

## 사전 요구사항

| 항목 | 버전 | 비고 |
|------|------|------|
| JDK | **21** | IntelliJ Platform 2024.2+ 가 JDK 21에서 동작합니다. |
| Gradle | **9.0 이상** | Wrapper가 자동으로 받으므로 직접 설치할 필요 없습니다. |

JDK가 없다면 (macOS / Homebrew):

```bash
brew install openjdk@21

# /usr/libexec/java_home 이 인식하도록 링크 (sudo 불필요)
mkdir -p ~/Library/Java/JavaVirtualMachines
ln -sfn /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk \
        ~/Library/Java/JavaVirtualMachines/openjdk-21.jdk

# 확인
/usr/libexec/java_home -v 21
```

> Gradle 9 미만이나 JDK 17에서는 빌드되지 않습니다.
> IntelliJ Platform Gradle Plugin 2.x가 Gradle 9.0+ 를 요구하고,
> Rider 2026.2 SDK는 JDK 21로 컴파일되어 있습니다.

## 빠른 시작

### 1. 빌드하기

#### Option A: 빌드 스크립트 사용 (권장)

```bash
./build.sh
```

#### Option B: Gradle Wrapper 직접 사용

```bash
./gradlew buildPlugin
```

Wrapper가 필요한 Gradle 버전을 알아서 받아오므로 Gradle을 따로 설치할 필요가 없습니다.

#### Option C: IntelliJ IDEA 사용

1. IntelliJ IDEA에서 프로젝트 디렉터리 열기
2. Gradle 탭에서 `Tasks` > `intellij` > `buildPlugin` 더블클릭
3. `build/distributions/` 폴더에서 ZIP 파일 확인

### 2. Rider에 설치하기

1. Rider 열기
2. `Settings` (⌘,) > `Plugins` 이동
3. 톱니바퀴 아이콘 ⚙️ 클릭
4. `Install Plugin from Disk...` 선택
5. `build/distributions/rider-pr-filter-<버전>.zip` 선택
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

## 문제 해결

### 빌드 실패 시

```bash
# Gradle 버전 확인
gradle --version

# Java 버전 확인 (17 이상 필요)
java -version

# Gradle 캐시 정리
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
