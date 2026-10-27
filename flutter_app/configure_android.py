import os
import re

def main():
    print("--- Starting Android Configuration ---")

    # 1. Update AndroidManifest.xml for Camera & Internet permissions
    manifest_path = os.path.join("android", "app", "src", "main", "AndroidManifest.xml")
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest = f.read()

        permissions = (
            '    <uses-permission android:name="android.permission.INTERNET"/>\n'
            '    <uses-permission android:name="android.permission.CAMERA"/>\n'
        )

        if "android.permission.CAMERA" not in manifest:
            manifest = manifest.replace("<application", permissions + "    <application", 1)
            with open(manifest_path, "w", encoding="utf-8") as f:
                f.write(manifest)
            print("Successfully added permissions to AndroidManifest.xml")
        else:
            print("Permissions already present in AndroidManifest.xml")
    else:
        print(f"Warning: Manifest not found at {manifest_path}")

    # 2. Update build.gradle or build.gradle.kts for minSdk 21
    gradle_files = [
        os.path.join("android", "app", "build.gradle"),
        os.path.join("android", "app", "build.gradle.kts")
    ]

    for gradle_path in gradle_files:
        if os.path.exists(gradle_path):
            with open(gradle_path, "r", encoding="utf-8") as f:
                content = f.read()

            original = content
            # Groovy DSL
            content = re.sub(r'minSdkVersion\s+.*', 'minSdkVersion 21', content)
            # Kotlin DSL
            content = re.sub(r'minSdk\s*=.*', 'minSdk = 21', content)

            if content != original:
                with open(gradle_path, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"Successfully updated minSdk in {gradle_path}")
            else:
                print(f"minSdk already configured or pattern not matched in {gradle_path}")

    print("--- Android Configuration Complete ---")

if __name__ == "__main__":
    main()
