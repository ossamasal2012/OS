"""
Runs inside GitHub Actions, AFTER a fresh `flutter create --platforms=android`
scaffold has been copied into ./android. Inserts the permissions and the
boot-completed receiver that alarms/reminders need.

Uses two anchors that have been stable across every Flutter Android
template version: the opening `<application` tag (permissions go right
before it) and the closing `</application>` tag (the receiver goes right
before it, i.e. as the last child of <application>). No XML parser needed —
plain text insertion at these two anchors is robust and dependency-free.
"""
import sys

MANIFEST_PATH = "android/app/src/main/AndroidManifest.xml"

PERMISSIONS = """    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
"""

RECEIVER = """    <receiver android:exported="false"
        android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
        <intent-filter>
            <action android:name="android.intent.action.BOOT_COMPLETED"/>
            <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
            <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        </intent-filter>
    </receiver>
"""


def main():
    with open(MANIFEST_PATH, encoding="utf-8") as f:
        content = f.read()

    if "RECEIVE_BOOT_COMPLETED" in content:
        print("Manifest already patched, skipping.")
        return

    if "<application" not in content or "</application>" not in content:
        print("ERROR: couldn't find <application> tags in generated manifest.", file=sys.stderr)
        sys.exit(1)

    content = content.replace("<application", PERMISSIONS + "\n    <application", 1)
    content = content.replace("</application>", RECEIVER + "</application>", 1)

    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        f.write(content)
    print("AndroidManifest.xml patched successfully.")


if __name__ == "__main__":
    main()
