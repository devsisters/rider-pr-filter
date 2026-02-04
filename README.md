# Rider PR File Filter Plugin

Rider의 Pull Request 화면에서 파일을 확장자 패턴으로 필터링할 수 있는 플러그인입니다.

## 기능

- **PR 화면 전용 검색바**: Pull Request를 볼 때만 자동으로 나타나는 검색바
- **Enter 키로 필터 적용**: 입력 후 Enter를 눌러 필터를 적용 (성능 개선)
- **와일드카드 패턴 지원**: `*.cs`, `*.json`, `Shop*.*` 등의 패턴 사용
- **파일 이름 및 경로 검색**: 파일 이름과 전체 경로 모두에서 패턴 매칭
- **여러 패턴 동시 지원**: 세미콜론(;)으로 여러 패턴 구분 (예: `*.cs;*.json;Shop*.*`)
- **자동 패턴 저장**: 마지막으로 사용한 패턴을 자동으로 기억

## 빌드 및 설치

### 필요 사항
- JDK 17 이상
- Gradle 8.x (Gradle 9.x는 호환성 문제가 있을 수 있음)

### 빠른 시작

```bash
# 1. 빌드 (자동 설치 옵션 포함)
./build.sh

# 2. 자동 설치 (Rider에 직접 설치)
./install.sh

# 또는 샌드박스 Rider에서 테스트
./run.sh
```

### 상세 빌드 방법

```bash
# Gradle wrapper 사용 (권장)
./gradlew buildPlugin

# 또는 시스템 Gradle 사용
gradle buildPlugin
```

빌드가 완료되면 `build/distributions/rider-pr-filter-1.0.0.zip` 파일이 생성됩니다.

### 설치 방법

#### 방법 1: 자동 설치 (권장)

```bash
./install.sh
```

설치 스크립트가 자동으로:
- 설치된 Rider 버전을 찾아서 선택
- 플러그인을 적절한 위치에 설치
- 설치 완료 안내

#### 방법 2: 샌드박스에서 테스트

```bash
./run.sh
```

플러그인이 로드된 별도의 Rider 인스턴스가 실행됩니다. (개발/테스트용)

#### 방법 3: 수동 설치

1. Rider를 엽니다
2. `Settings` (또는 `Preferences`) > `Plugins` 이동
3. 톱니바퀴 아이콘 클릭 > `Install Plugin from Disk...` 선택
4. `build/distributions/rider-pr-filter-1.0.0.zip` 파일 선택
5. Rider 재시작

## 사용 방법

### PR 화면에서 직접 필터링 (추천)

1. Rider에서 Pull Request를 엽니다
2. PR 화면 상단에 **검색바**가 자동으로 나타납니다
3. 검색바에 패턴을 입력합니다
4. **Enter 키를 누르면** 필터가 적용됩니다
   - 예: `*.cs` → Enter - C# 파일만 표시
   - 예: `*.cs;*.json` → Enter - C# 파일과 JSON 파일만 표시
   - 예: `Shop*.*` → Enter - Shop으로 시작하는 모든 파일 표시
5. **×** 버튼을 클릭하면 필터가 즉시 초기화됩니다

### 패턴 예시

#### Unity 개발자용
```
*.cs;*.json;*.shader
```
(메타 파일, 에셋 등을 제외하고 코드만 표시)

#### 특정 프리픽스 파일만 보기
```
Shop*.*;Player*.*
```
(Shop 또는 Player로 시작하는 모든 파일)

#### 특정 프리픽스 + 확장자 조합
```
Shop*.cs;Shop*.json
```
(Shop으로 시작하는 C#과 JSON 파일만)

#### C# 코드만 보기
```
*.cs
```

#### 설정 파일만 보기
```
*.json;*.xml;*.yaml;*.yml
```

## 작동 방식

플러그인은 다음과 같이 작동합니다:

1. **PR 화면 감지**: Pull Request 탭이 열리면 자동으로 검색바를 추가
2. **실시간 필터링**: 검색바에 입력된 패턴으로 파일 목록 필터링
3. **패턴 저장**: 마지막 사용 패턴을 자동 저장하여 다음에 재사용

### 참고사항

- PR 화면("Pull Request #123")에만 검색바가 나타납니다
- 일반 VCS Changes 뷰에는 나타나지 않습니다
- Settings에서 기본 패턴을 설정할 수 있습니다

## Gradle 9.x 호환성 문제 해결

현재 Gradle 9.x와 IntelliJ 플러그인 간 호환성 문제가 있습니다. 다음 방법으로 해결할 수 있습니다:

### 방법 1: Gradle 8.x 사용

```bash
# SDKMAN 사용
sdk install gradle 8.5
sdk use gradle 8.5

# 또는 Homebrew (macOS)
brew install gradle@8
```

### 방법 2: IntelliJ IDEA에서 빌드

1. IntelliJ IDEA에서 프로젝트 열기
2. `File` > `Settings` > `Build, Execution, Deployment` > `Build Tools` > `Gradle`
3. `Gradle JVM`을 JDK 17로 설정
4. `Use Gradle from` 을 `gradle-wrapper.properties file` 로 설정
5. `Build` > `Build Project`

## 프로젝트 구조

```
rider-pr-filter/
├── build.gradle.kts          # Gradle 빌드 설정
├── settings.gradle.kts        # Gradle 프로젝트 설정
├── gradle.properties          # Gradle 속성
├── src/main/
│   ├── kotlin/com/devsisters/prfilter/
│   │   ├── PRFilterSettings.kt          # 필터 설정 저장
│   │   ├── PRFilterConfigurable.kt      # Settings UI
│   │   └── ToggleFilterAction.kt        # Toolbar 액션
│   └── resources/META-INF/
│       └── plugin.xml                    # 플러그인 메타데이터
└── README.md
```

## 개발

### 플러그인 실행 (디버깅)

```bash
# 샌드박스 Rider 실행
./run.sh

# 또는 직접 Gradle 명령 사용
./gradlew runIde
```

이 명령은 플러그인이 설치된 별도의 Rider 인스턴스를 실행합니다.

### 코드 수정 후 테스트

```bash
# 1. 빌드 및 자동 설치
./build.sh

# 2. Rider 재시작
```

또는 샌드박스에서 테스트:
```bash
./run.sh
```

## 기여

버그 리포트나 기능 제안은 이슈를 통해 제출해주세요.
