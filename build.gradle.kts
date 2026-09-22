plugins {
    id("java")
    // Gradle 9 필요: IntelliJ Platform Gradle Plugin 2.x가 Gradle 9.0+ 를 요구하고,
    // Kotlin 1.9.x Gradle 플러그인은 Gradle 9에서 동작하지 않는다.
    id("org.jetbrains.kotlin.jvm") version "2.4.20"
    // IntelliJ Platform Gradle Plugin 2.x.
    // 구 org.jetbrains.intellij 1.x는 2024.2+ 플랫폼을 지원하지 않아 Rider 2026.2 타겟에는 쓸 수 없다.
    id("org.jetbrains.intellij.platform") version "2.19.0"
}

group = "com.devsisters"
version = "1.0.1"

repositories {
    mavenCentral()
    intellijPlatform {
        defaultRepositories()
    }
}

dependencies {
    intellijPlatform {
        // IC(IntelliJ Community)가 아닌 RD(Rider).
        // plugin.xml이 com.intellij.modules.rider에 의존하므로 IC 샌드박스에서는 플러그인이 로드되지 않는다.
        // Rider는 installer(.dmg) 배포본을 지원하지 않는다. useInstaller=false 라야 runIde가 동작한다.
        rider("2026.2.2") {
            useInstaller = false
        }
        bundledPlugin("Git4Idea")

        // 플랫폼이 모듈로 쪼개져 있어 VCS 변경목록 UI는 명시적으로 선언해야 컴파일 클래스패스에 올라온다.
        //   ChangesTree, ChangesBrowserNode -> intellij.platform.vcs.impl.shared
        //   ChangesViewContentManager       -> intellij.platform.vcs.impl
        bundledModule("intellij.platform.vcs.impl")
        bundledModule("intellij.platform.vcs.impl.shared")
    }
}

intellijPlatform {
    // 이 플러그인은 설정 UI를 노출하지 않는다. Rider를 띄워야 하는 무거운 단계라 끈다.
    buildSearchableOptions = false

    pluginConfiguration {
        ideaVersion {
            sinceBuild = "262"
            // 상한 없음: 사내 배포용이라 IDE 업그레이드마다 재빌드하지 않도록 until-build를 생략한다.
            untilBuild = provider { null }
        }
    }
}

// IntelliJ Platform 2024.2+ 는 JDK 21에서 동작한다.
kotlin {
    jvmToolchain(21)
}

tasks.wrapper {
    gradleVersion = "9.7.1"
}
