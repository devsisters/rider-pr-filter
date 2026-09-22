plugins {
    id("java")
    id("org.jetbrains.kotlin.jvm") version "1.9.22"
    id("org.jetbrains.intellij") version "1.17.0"
}

group = "com.devsisters"
version = "1.0.0"

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib")
}

intellij {
    version.set("2023.3.2")
    type.set("IC")
    plugins.set(listOf("vcs-git"))
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

tasks {
    withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        kotlinOptions.jvmTarget = "17"
    }

    patchPluginXml {
        sinceBuild.set("233")
        // 상한 없음: 사내 배포용이라 IDE 업그레이드마다 재빌드하지 않도록 until-build를 생략한다.
        // (빈 문자열을 지정하면 plugin.xml에 until-build 속성이 기록되지 않는다)
        untilBuild.set("")
    }
}

tasks.wrapper {
    gradleVersion = "8.5"
}
