import os
import shutil
import zipfile

def package():
    base_dir = r"D:\AHLNANEW - Copy"
    desktop_zip = r"C:\Users\kazaz\Desktop\ahlna.zip"
    d_zip = r"D:\ahlna.zip"
    temp_dir = r"D:\AHLNANEW - Copy\temp_package_ahlna"

    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    os.makedirs(temp_dir)

    root_folder = os.path.join(temp_dir, "ahlna")
    os.makedirs(root_folder)

    # 1. Admin App
    admin_folder = os.path.join(root_folder, "1- لوحة تحكم إدارة المطعم الرئيسية (AHLNA Admin App)")
    os.makedirs(admin_folder)

    installer_src = os.path.join(base_dir, r"installer\dist\AhlnaDaquqAdminInstaller.exe")
    installer_dst = os.path.join(admin_folder, "AhlnaDaquqAdminInstaller (مثبت_تلقائي).exe")
    shutil.copy2(installer_src, installer_dst)

    portable_folder = os.path.join(admin_folder, "النسخة_المحمولة")
    release_dir = os.path.join(base_dir, r"build\windows\x64\runner\Release")
    shutil.copytree(release_dir, portable_folder)

    # 2. Driver App
    driver_folder = os.path.join(root_folder, "2- تطبيق السائق الدلفري للهاتف (Driver App - Android)")
    os.makedirs(driver_folder)
    driver_dest = os.path.join(driver_folder, "تطبيق_السائق_الدلفري_Driver_App.apk")
    driver_candidates = [
        r"D:\AHLNA-APP\Driver_App.apk",
        os.path.join(base_dir, r"build\app\outputs\flutter-apk\app-admin-release.apk"),
        os.path.join(base_dir, r"build\app\outputs\apk\admin\release\app-admin-release.apk"),
        r"D:\AHLNA-APP - Copy\build\app\outputs\flutter-apk\app-admin-release.apk",
    ]
    found_driver = False
    for candidate in driver_candidates:
        if os.path.exists(candidate) and os.path.getsize(candidate) > 1000000:
            shutil.copy2(candidate, driver_dest)
            print(f"Copied driver APK from {candidate} (size: {os.path.getsize(driver_dest)} bytes)")
            found_driver = True
            break
    if not found_driver:
        print("WARNING: Driver APK could not be found!")

    driver_info = os.path.join(driver_folder, "معلومات_تطبيق_السائق.txt")
    with open(driver_info, "w", encoding="utf-8") as f:
        f.write("تطبيق سائق التوصيل الخاص بـ أهلنا داقوق\nنسخة أندرويد APK جاهزة للتثبيت المباشر على هاتف السائق.")

    # 3. Customer App
    customer_folder = os.path.join(root_folder, "3- تطبيق الزبون للهاتف (Customer App - Android)")
    os.makedirs(customer_folder)
    customer_apk = os.path.join(base_dir, r"build\app\outputs\flutter-apk\app-client-release.apk")
    if os.path.exists(customer_apk):
        shutil.copy2(customer_apk, os.path.join(customer_folder, "AHLNA_Customer_App.apk"))

    customer_info = os.path.join(customer_folder, "معلومات_تطبيق_الزبون.txt")
    with open(customer_info, "w", encoding="utf-8") as f:
        f.write("تطبيق الزبون الخاص بـ أهلنا داقوق الإصدار 1.3.0 (Build 45)\nنسخة أندرويد APK جاهزة للتثبيت المباشر.")

    # 4. Readme
    readme_path = os.path.join(root_folder, "اقرأني_دليل_التشغيل_AHLNA.txt")
    with open(readme_path, "w", encoding="utf-8") as f:
        f.write("""=======================================================
حزمة برامج وتطبيقات أهلنا داقوق (AHLNA DAQUQ APPS)
الإصدار المحدث: سبتمبر 2026
=======================================================

محتويات الحزمة:
1- لوحة تحكم إدارة المطعم الرئيسية (Windows Admin Desktop):
   - تحتوي على مثبت تلقائي (AhlnaDaquqAdminInstaller) يقوم بتثبيت البرنامج مع إنشاء اختصارات سطح المكتب والتشغيل التلقائي مع بدء الويندوز.
   - تحتوي على النسخة المحمولة (النسخة_المحمولة) للتشغيل المباشر دون تثبيت.
   - مميزات النسخة الجديدة:
     * إشعار جانبي بالويندوز (Toast Notification) فور وصول أي طلب جديد مع صوت تنبيهي واضح.
     * تشغيل تلقائي للوحة التحكم عند تشغيل الحاسبة.
     * فتح تفاصيل الطلب والزبون بمجرد الضغط على كرت الطلب في شاشة الطلبات الحالية.
     * إزالة أيقونة التعجب (!) غير الضرورية من الكروت لتسهيل العمل.
     * حل مشكلة الأيقونة البيضاء واعتماد أيقونة الشعار الرسمية بجودة عالية.
     * دعم كامل لإرسال الإشعارات الجماعية وتعديل المنيو والطلبات.

2- تطبيق السائق الدلفري (Driver App):
   - ملف APK مخصص لهاتف السائق لمتابعة واستلام وتوصيل الطلبات وتتبع الموقع.

3- تطبيق الزبون (Customer App):
   - ملف APK الإصدار 1.3.0 الخاص بهواتف الزبائن لطلب الوجبات ومتابعة الحالة.
=======================================================
""")

    # Create zip files
    for target_zip in [desktop_zip, d_zip]:
        if os.path.exists(target_zip):
            try:
                os.remove(target_zip)
            except Exception as e:
                print(f"Could not remove {target_zip}: {e}")

        print(f"Compressing to {target_zip} ...")
        with zipfile.ZipFile(target_zip, 'w', zipfile.ZIP_DEFLATED) as zf:
            for root, dirs, files in os.walk(root_folder):
                for file in files:
                    full_path = os.path.join(root, file)
                    rel_path = os.path.relpath(full_path, temp_dir)
                    zf.write(full_path, rel_path)
        print(f"Finished: {target_zip} (Size: {os.path.getsize(target_zip)} bytes)")

    # Update extracted desktop folder as well
    desktop_extracted = r"C:\Users\kazaz\Desktop\ahlna"
    if os.path.exists(desktop_extracted):
        try:
            shutil.rmtree(desktop_extracted)
        except Exception as e:
            print(f"Could not remove {desktop_extracted}: {e}")
    try:
        shutil.copytree(root_folder, desktop_extracted)
        print(f"Copied extracted folder to {desktop_extracted}!")
    except Exception as e:
        print(f"Error copying to {desktop_extracted}: {e}")

    # Cleanup temp dir
    shutil.rmtree(temp_dir)
    print("Packaging completed successfully!")

if __name__ == "__main__":
    package()
