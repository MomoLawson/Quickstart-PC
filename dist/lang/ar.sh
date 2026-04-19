# shellcheck shell=bash
# Quickstart-PC Language Pack: ar (العربية)

HELP_TITLE="Quickstart-PC - إعداد الكمبيوتر بنقرة واحدة"
HELP_USAGE="الاستخدام: quickstart.sh [خيارات]"
HELP_OPTIONS=""
read -r -d '' HELP_OPTIONS << 'OPTIONS_EOF'
الخيارات:
  --lang LANG        تعيين اللغة (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)
  --local-lang PATH  مجلد نصوص اللغة المحلي
  --cfg-path PATH    استخدام ملف profiles.json المحلي
  --cfg-url URL      استخدام عنوان profiles.json البعيد
  --dev              وضع المطور: عرض التحديدات بدون تثبيت
  --dry-run          وضع المعاينة: عرض عملية التثبيت بدون تثبيت فعلي
  --doctor          تشغيل تشخيص بيئة QC Doctor
  --yes, -y          تأكيد جميع المطالبات تلقائياً
  --verbose, -v      عرض معلومات التصحيح التفصيلية
  --log-file FILE    كتابة السجلات في ملف
  --export-plan FILE تصدير خطة التثبيت
  --custom           وضع اختيار البرامج المخصص
  --retry-failed     إعادة محاولة الحزم التي فشلت سابقاً
  --list-software    سرد جميع البرامج المتاحة
  --show-software ID عرض تفاصيل البرنامج
  --search KEYWORD   البحث عن برنامج
  --validate         التحقق من ملف الإعداد
  --report-json FILE تصدير تقرير التثبيت بصيغة JSON
  --report-txt FILE  تصدير تقرير التثبيت بصيغة TXT
  --list-profiles    سرد جميع الملفات المتاحة
  --show-profile KEY عرض تفاصيل الملف
  --skip SW          تخطي البرنامج المحدد (قابل للتكرار)
  --only SW          تثبيت البرنامج المحدد فقط (قابل للتكرار)
  --fail-fast        التوقف عند أول خطأ
  --profile NAME     اختيار الملف مباشرة (تخطي القائمة)
  --non-interactive  الوضع غير التفاعلي (بدون TUI/مطالبات)
  --help             عرض رسالة المساعدة هذه
OPTIONS_EOF

LANG_BANNER_TITLE="Quickstart-PC v__VERSION__"
LANG_BANNER_DESC="إعداد سريع لأجهزة الكمبيوتر الجديدة"
LANG_DETECTING_SYSTEM="جاري اكتشاف بيئة النظام..."
LANG_SYSTEM_INFO="النظام"
LANG_PACKAGE_MANAGER="مدير الحزم"
LANG_UNSUPPORTED_OS="نظام التشغيل غير مدعوم"
LANG_USING_REMOTE_CONFIG="استخدام الإعداد البعيد"
LANG_USING_CUSTOM_CONFIG="استخدام الإعداد المحلي"
LANG_USING_DEFAULT_CONFIG="استخدام الإعداد الافتراضي"
LANG_CONFIG_NOT_FOUND="ملف الإعداد غير موجود"
LANG_CONFIG_INVALID="تنسيق ملف الإعداد غير صالح"
LANG_SELECT_PROFILES="اختيار ملفات التثبيت"
LANG_SELECT_SOFTWARE="اختيار البرامج للتثبيت"
LANG_NAVIGATE="↑↓ تحريك | ENTER تأكيد"
LANG_NAVIGATE_MULTI="↑↓ تحريك | مسافة اختيار | ENTER تأكيد"
LANG_SELECTED="[✓] "
LANG_NOT_SELECTED="[  ] "
LANG_SELECT_ALL="تحديد الكل"
LANG_BACK_TO_PROFILES="العودة إلى اختيار الملفات"
LANG_NO_PROFILE_SELECTED="لم يتم اختيار أي ملف"
LANG_NO_SOFTWARE_SELECTED="لم يتم اختيار أي برنامج"
LANG_CONFIRM_INSTALL="تأكيد التثبيت؟ [Y/n]"
LANG_CANCELLED="تم الإلغاء"
LANG_START_INSTALLING="بدء تثبيت البرامج"
LANG_INSTALLING="جاري التثبيت"
LANG_INSTALL_SUCCESS="تم التثبيت بنجاح"
LANG_INSTALL_FAILED="فشل التثبيت"
LANG_PLATFORM_NOT_SUPPORTED="المنصة غير مدعومة"
LANG_INSTALLATION_COMPLETE="اكتمل التثبيت"
LANG_TOTAL_INSTALLED="إجمالي المثبت"
LANG_DEV_MODE="وضع المطور: عرض البرامج المحددة بدون تثبيت"
LANG_DRY_RUN_MODE="وضع المعاينة: عرض عملية التثبيت بدون تثبيت فعلي"
LANG_DRY_RUN_INSTALLING="جاري المحاكاة"
LANG_JQ_DETECTED="تم اكتشاف jq، استخدام jq"
LANG_JQ_NOT_FOUND="لم يتم العثور على jq، جاري التثبيت..."
LANG_JQ_INSTALLED="تم تثبيت jq بنجاح"
LANG_JQ_INSTALL_FAILED="فشل تثبيت jq، محاولة محلل بديل..."
LANG_USING_PYTHON3="استخدام python3 كمحلل بديل"
LANG_NO_JSON_PARSER="لا يوجد محلل JSON متاح (jq/python3)"
LANG_CHECKING_INSTALLATION="جاري التحقق من حالة التثبيت..."
LANG_SKIPPING_INSTALLED="مثبت بالفعل، تخطي"
LANG_ALL_INSTALLED="جميع البرامج مثبتة بالفعل، لا شيء للقيام به"
LANG_ASK_CONTINUE="اكتمل التثبيت. متابعة تثبيت ملفات أخرى؟"
LANG_CONTINUE="متابعة التثبيت"
LANG_EXIT="خروج"
LANG_TITLE_SELECT_PROFILE="اختيار الملف"
LANG_TITLE_SELECT_SOFTWARE="اختيار البرنامج"
LANG_TITLE_INSTALLING="جاري التثبيت"
LANG_TITLE_ASK_CONTINUE="متابعة التثبيت؟"
LANG_LANG_PROMPT="يرجى اختيار اللغة"
LANG_LANG_MENU_ENTER="تأكيد"
LANG_LANG_MENU_SPACE="اختيار"
LANG_NONINTERACTIVE_ERROR="الوضع غير التفاعلي يتطلب معلمة --profile"
LANG_PROFILE_NOT_FOUND="الملف '$PROFILE_KEY' غير موجود"
LANG_NPM_NOT_FOUND="لم يتم العثور على npm، جاري التثبيت..."
LANG_WINGET_NOT_FOUND="لم يتم العثور على winget، لا يمكن تثبيت npm تلقائياً"
LANG_NPM_AUTO="npm"
