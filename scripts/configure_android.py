#!/usr/bin/env python3
import os
import re

def configure_settings_gradle():
    path = "android/settings.gradle"
    if not os.path.exists(path):
        return
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Update kotlin plugin version
    content = re.sub(
        r'id\s+["\']org\.jetbrains\.kotlin\.android["\']\s+version\s+["\'][^"\']+["\']',
        'id "org.jetbrains.kotlin.android" version "1.9.22"',
        content
    )

    # Add google services plugin to settings plugins block if present
    if "com.google.gms.google-services" not in content and "plugins {" in content:
        content = re.sub(
            r'plugins\s*\{',
            'plugins {\n    id "com.google.gms.google-services" version "4.4.2" apply false',
            content
        )

    # Inject R8 override into pluginManagement
    if "com.android.tools:r8" not in content and "pluginManagement {" in content:
        r8_block = '''pluginManagement {
    buildscript {
        repositories {
            google()
            mavenCentral()
            maven { url = uri("https://storage.googleapis.com/r8-releases/raw") }
        }
        dependencies {
            classpath("com.android.tools:r8:8.3.37")
        }
    }
'''
        content = content.replace("pluginManagement {", r8_block, 1)

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Configured android/settings.gradle")

def configure_root_build_gradle():
    path = "android/build.gradle"
    if not os.path.exists(path):
        return
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Update kotlin version if ext.kotlin_version exists
    content = re.sub(
        r"ext\.kotlin_version\s*=\s*['\"][^'\"]+['\"]",
        "ext.kotlin_version = '1.9.22'",
        content
    )

    # Inject R8 and Google Services into root buildscript if needed
    if "com.android.tools:r8" not in content:
        r8_root = '''buildscript {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/r8-releases/raw") }
    }
    dependencies {
        classpath("com.android.tools:r8:8.3.37")
        classpath("com.google.gms:google-services:4.4.2")
    }
}

'''
        content = r8_root + content
    elif "com.google.gms:google-services" not in content:
        content = re.sub(
            r'dependencies\s*\{',
            'dependencies {\n        classpath("com.google.gms:google-services:4.4.2")',
            content
        )

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Configured android/build.gradle")

def configure_app_build_gradle():
    path = "android/app/build.gradle"
    if not os.path.exists(path):
        return
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Ensure namespace and applicationId match in.mantraapp.app
    content, n_ns = re.subn(r'namespace\s*=?\s*["\'][^"\']+["\']', 'namespace = "in.mantraapp.app"', content)
    content, n_app = re.subn(r'applicationId\s*=?\s*["\'][^"\']+["\']', 'applicationId = "in.mantraapp.app"', content)
    print(f"Configured build.gradle: namespace replacements={n_ns}, applicationId replacements={n_app}")
    if n_app == 0:
        raise ValueError("Failed to replace applicationId in android/app/build.gradle!")

    # Set minSdkVersion to 23
    content = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 23', content)
    content = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23', content)

    # Force stable exifinterface 1.3.7 to avoid D8 NullPointerException
    if "androidx.exifinterface:exifinterface" not in content:
        content += '''

configurations.all {
    resolutionStrategy {
        force 'androidx.exifinterface:exifinterface:1.3.7'
    }
}
'''

    # Apply google-services plugin if google-services.json exists
    if "com.google.gms.google-services" not in content:
        content += '''

if (file('google-services.json').exists()) {
    apply plugin: 'com.google.gms.google-services'
}
'''

    # Ensure release build uses debug signing config for testing/CI builds
    if "signingConfig signingConfigs.debug" not in content and "signingConfig = signingConfigs.debug" not in content:
        content = re.sub(
            r'buildTypes\s*\{\s*release\s*\{',
            'buildTypes {\n        release {\n            signingConfig signingConfigs.debug',
            content
        )

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Configured android/app/build.gradle")

def configure_app_build_gradle_kts():
    path = "android/app/build.gradle.kts"
    if not os.path.exists(path):
        return
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    content, n_ns = re.subn(r'namespace\s*=\s*["\'][^"\']+["\']', 'namespace = "in.mantraapp.app"', content)
    content, n_app = re.subn(r'applicationId\s*=\s*["\'][^"\']+["\']', 'applicationId = "in.mantraapp.app"', content)
    print(f"Configured build.gradle.kts: namespace replacements={n_ns}, applicationId replacements={n_app}")
    if n_app == 0:
        raise ValueError("Failed to replace applicationId in android/app/build.gradle.kts!")
    content = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23', content)

    if "com.google.gms.google-services" not in content:
        content += '''

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
'''

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Configured android/app/build.gradle.kts")

if __name__ == "__main__":
    configure_settings_gradle()
    configure_root_build_gradle()
    configure_app_build_gradle()
    configure_app_build_gradle_kts()
    print("Android configuration script completed successfully.")
