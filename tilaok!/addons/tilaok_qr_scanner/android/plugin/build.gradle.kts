plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

group = "org.hoplyxd.tilaok.scanner"
version = "1.0.0"

android {
    namespace = "org.hoplyxd.tilaok.scanner"
    compileSdk = 36
    buildToolsVersion = "36.1.0"

    defaultConfig {
        minSdk = 24
        manifestPlaceholders["godotPluginName"] = "TilaokQrScanner"
        manifestPlaceholders["godotPluginPackageName"] = "org.hoplyxd.tilaok.scanner"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    compileOnly("org.godotengine:godot:4.7.2.stable")
    implementation("androidx.activity:activity:1.10.1")
    implementation("androidx.fragment:fragment:1.8.6")
    implementation("androidx.camera:camera-camera2:1.5.1")
    implementation("androidx.camera:camera-lifecycle:1.5.1")
    implementation("androidx.camera:camera-view:1.5.1")
    implementation("com.google.zxing:core:3.5.3")
    testImplementation("junit:junit:4.13.2")
}

val copyDebugAarToGodot by tasks.registering(Copy::class) {
    from(layout.buildDirectory.file("outputs/aar/plugin-debug.aar"))
    into(rootProject.layout.projectDirectory.dir("../bin/debug"))
    rename { "TilaokQrScanner-debug.aar" }
}

val copyReleaseAarToGodot by tasks.registering(Copy::class) {
    from(layout.buildDirectory.file("outputs/aar/plugin-release.aar"))
    into(rootProject.layout.projectDirectory.dir("../bin/release"))
    rename { "TilaokQrScanner-release.aar" }
}

tasks.named("assemble").configure {
    finalizedBy(copyDebugAarToGodot, copyReleaseAarToGodot)
}
