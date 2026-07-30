"""
Appends the core-library-desugaring setup to android/app/build.gradle (or
.kts) after a fresh `flutter create` scaffold. Appending a *second*
android{}/dependencies{} block instead of editing the existing one is
deliberate: Gradle composes repeated blocks rather than requiring exactly
one per file, so this can't corrupt whatever flutter create generated —
there is nothing to parse or get subtly wrong.
"""
import os

GROOVY_PATH = "android/app/build.gradle"
KOTLIN_PATH = "android/app/build.gradle.kts"

GROOVY_SNIPPET = """

// --- added for flutter_local_notifications (java.time support) ---
android {
    compileOptions {
        coreLibraryDesugaringEnabled true
    }
}
dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
"""

KOTLIN_SNIPPET = """

// --- added for flutter_local_notifications (java.time support) ---
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
"""


def main():
    if os.path.exists(KOTLIN_PATH):
        path, snippet = KOTLIN_PATH, KOTLIN_SNIPPET
    elif os.path.exists(GROOVY_PATH):
        path, snippet = GROOVY_PATH, GROOVY_SNIPPET
    else:
        raise SystemExit("ERROR: no android/app/build.gradle(.kts) found.")

    with open(path, encoding="utf-8") as f:
        content = f.read()

    if "desugar_jdk_libs" in content:
        print(f"{path} already patched, skipping.")
        return

    with open(path, "a", encoding="utf-8") as f:
        f.write(snippet)
    print(f"{path} patched successfully.")


if __name__ == "__main__":
    main()
