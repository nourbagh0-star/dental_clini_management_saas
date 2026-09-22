// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get createStaffAccountLabel => 'إنشاء حساب موظف';

  @override
  String get createStaffAccountHelp =>
      'أدخل بريد الموظف وكلمة مرور مؤقتة من 15 إلى 128 حرفًا. شارك بيانات الدخول معه بشكل خاص. يجب تغيير كلمة المرور قبل الوصول إلى العيادة. لن يتم إرسال بريد إلكتروني.';

  @override
  String get temporaryPasswordLabel => 'كلمة مرور مؤقتة';

  @override
  String get staffAccountCreated =>
      'تم إنشاء حساب الموظف. شارك بيانات الدخول بشكل خاص. يجب تغيير كلمة المرور عند أول تسجيل دخول.';

  @override
  String get staffAccountUnavailable =>
      'تعذر إنشاء الحساب. قد يكون البريد مسجلًا مسبقًا أو إنشاء الحسابات غير متاح مؤقتًا. لم تتغير الحسابات الموجودة.';

  @override
  String get initialPasswordTitle => 'اختر كلمة المرور الخاصة بك';

  @override
  String get initialPasswordHelp =>
      'استبدل كلمة المرور المؤقتة بكلمة مرور مختلفة من 15 حرفًا على الأقل. يبقى الوصول إلى العيادة مقفلًا حتى تنتهي. ثم سجل الدخول مجددًا بكلمة المرور الجديدة.';

  @override
  String get emailConfirmed =>
      'تم تأكيد بريدك الإلكتروني. سجل الدخول للمتابعة.';

  @override
  String get invalidConfirmationLink =>
      'رابط التأكيد غير صالح أو منتهي الصلاحية. سجل الدخول لطلب رابط جديد.';

  @override
  String get confirmationLinkSent =>
      'تحقق من بريدك وافتح رابط التأكيد، ثم عد لتسجيل الدخول. انتظر 60 ثانية على الأقل قبل إعادة الإرسال.';

  @override
  String get resendLinkLabel => 'إعادة إرسال رابط التأكيد';

  @override
  String get appTitle => 'دينتافلو';

  @override
  String get demoLabel => 'مساحة تجريبية';

  @override
  String get welcomeTitle => 'عيادتك، منظمة.';

  @override
  String get welcomeBody => 'مساحة عمل مشتركة لعيادة الأسنان الخاصة بك.';

  @override
  String get demoNotice => 'استخدم بيانات خيالية فقط.';

  @override
  String get appearanceTitle => 'التفضيلات';

  @override
  String get themeLabel => 'المظهر';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get systemLabel => 'استخدام إعدادات الجهاز';

  @override
  String get lightLabel => 'فاتح';

  @override
  String get darkLabel => 'داكن';

  @override
  String get englishLabel => 'English';

  @override
  String get russianLabel => 'Русский';

  @override
  String get arabicLabel => 'العربية';

  @override
  String get storageWarning =>
      'تعذر حفظ تفضيلاتك أو استعادتها. لا يزال بإمكانك استخدام هذه النسخة.';

  @override
  String get notFoundTitle => 'الصفحة غير متاحة';

  @override
  String get notFoundBody => 'هذه الصفحة غير متاحة في النسخة الحالية.';

  @override
  String get backHome => 'العودة إلى مساحة العمل';

  @override
  String get startupTitle => 'تعذر فتح مساحة العمل';

  @override
  String get startupBody =>
      'تعذر تشغيل التطبيق. تحقق من إعدادات التطوير وحاول مرة أخرى.';

  @override
  String get configurationBody =>
      'إعدادات التطوير غير صالحة. تحقق من البيئة وإعدادات الواجهة الخلفية العامة. وضع الإنتاج غير مفعّل.';

  @override
  String get retryLabel => 'المحاولة مرة أخرى';

  @override
  String get networkFailure => 'الاتصال غير متاح. حاول مرة أخرى.';

  @override
  String get authenticationFailure => 'يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get authorizationFailure => 'ليس لديك صلاحية لهذا الإجراء.';

  @override
  String get validationFailure => 'تحقق من المعلومات وحاول مرة أخرى.';

  @override
  String get serverFailure => 'الخدمة غير متاحة مؤقتاً.';

  @override
  String get notFoundFailure => 'السجل المطلوب غير متاح.';

  @override
  String get unknownFailure => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get registerTitle => 'إنشاء حساب';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get signInLabel => 'تسجيل الدخول';

  @override
  String get registerLabel => 'إنشاء حساب';

  @override
  String get forgotLabel => 'هل نسيت كلمة المرور؟';

  @override
  String get verifyTitle => 'التحقق من بريدك الإلكتروني';

  @override
  String get codeLabel => 'رمز التحقق';

  @override
  String get verifyLabel => 'التحقق من الرمز';

  @override
  String get resendLabel => 'إعادة إرسال الرمز';

  @override
  String get changeEmailLabel => 'تغيير البريد الإلكتروني';

  @override
  String get forgotTitle => 'استعادة حسابك';

  @override
  String get sendCodeLabel => 'إرسال رمز الاستعادة';

  @override
  String get sendResetLinkLabel => 'إرسال رابط إعادة تعيين كلمة المرور';

  @override
  String get recoveryLinkSent =>
      'إذا كان الحساب موجودًا، افتح رابط إعادة تعيين كلمة المرور في بريدك الإلكتروني لاختيار كلمة مرور جديدة.';

  @override
  String get resetTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get resetLabel => 'حفظ كلمة المرور الجديدة';

  @override
  String get lockedTitle => 'مساحة العمل مقفلة';

  @override
  String get lockedBody => 'أدخل كلمة المرور لفتح حسابك.';

  @override
  String get unlockLabel => 'فتح';

  @override
  String get switchAccountLabel => 'تبديل الحساب';

  @override
  String get accountTitle => 'حسابك جاهز';

  @override
  String get accountBody =>
      'يمكنك الآن إعداد العيادة. لا يحتوي حسابك على دور في عيادة بعد.';

  @override
  String get lockLabel => 'قفل مساحة العمل';

  @override
  String get logoutLabel => 'تسجيل الخروج';

  @override
  String get backLoginLabel => 'العودة إلى تسجيل الدخول';

  @override
  String get passwordHelp =>
      'استخدم 15 حرفًا على الأقل. يمكنك استخدام المسافات ومدير كلمات المرور.';

  @override
  String get emailInvalid => 'أدخل عنوان بريد إلكتروني صالحًا.';

  @override
  String get requiredField => 'هذا الحقل مطلوب.';

  @override
  String get passwordShort => 'استخدم 15 حرفًا على الأقل.';

  @override
  String get passwordMismatch => 'يجب أن تتطابق كلمتا المرور.';

  @override
  String get invalidCodeInput =>
      'أدخل رمز البريد الإلكتروني المكون من ستة أرقام.';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get authCredentials => 'تعذر التحقق من بيانات الدخول. حاول مرة أخرى.';

  @override
  String get authUnconfirmed => 'أكد بريدك الإلكتروني قبل تسجيل الدخول.';

  @override
  String get authInvalidCode =>
      'هذا الرمز غير صالح أو منتهي الصلاحية. اطلب رمزًا جديدًا.';

  @override
  String get authWeakPassword => 'كلمة المرور لا تستوفي متطلبات الخادم.';

  @override
  String get authRateLimited =>
      'محاولات كثيرة جدًا. انتظر قبل المحاولة مرة أخرى.';

  @override
  String get authStorage =>
      'تخزين الجلسة غير متاح. يظل الوصول محظورًا؛ تحقق من إعدادات تخزين المتصفح أو الجهاز.';

  @override
  String get authUnavailable =>
      'المصادقة غير مهيأة. افتح نسخة التطوير المهيأة.';

  @override
  String get authRevocation =>
      'تم تسجيل الخروج على هذا الجهاز. تعذر تأكيد إنهاء جلسة الخادم.';

  @override
  String get authResetPartial =>
      'تم تغيير كلمة المرور، لكن تعذر تأكيد إنهاء كل الجلسات. سجّل الدخول مرة أخرى؛ قد تظل جلسات أخرى نشطة.';

  @override
  String get authResetDone => 'تم تغيير كلمة المرور. سجّل الدخول مرة أخرى.';

  @override
  String get authCodeSent =>
      'إذا كان هذا العنوان مؤهلاً، فقد أُرسل رمز إلى بريدك الإلكتروني. تحقق من صندوق الوارد. تنتهي صلاحية الرموز بعد ساعة؛ انتظر 60 ثانية على الأقل قبل إعادة الإرسال.';

  @override
  String get restoringTitle => 'جارٍ التحقق من جلستك';

  @override
  String get restoreFailedTitle => 'تعذرت استعادة الجلسة';

  @override
  String get privacyHidden => 'مساحة العمل مخفية';

  @override
  String get authSettings => 'المظهر واللغة';

  @override
  String get continueAuth => 'تسجيل الدخول أو إنشاء حساب';

  @override
  String get clinicSetupTitle => 'إعداد عيادتك';

  @override
  String get clinicSetupBody =>
      'أنشئ عيادتك الأولى لبدء استخدام DentaFlow. يمكنك إنشاء عيادات إضافية لاحقًا.';

  @override
  String get createClinicLabel => 'إنشاء عيادة';

  @override
  String get clinicNameLabel => 'اسم العيادة';

  @override
  String get clinicNameHelp => 'استخدم الاسم الذي يعرفه الموظفون والمرضى.';

  @override
  String get currencyLabel => 'العملة';

  @override
  String get timeZoneLabel => 'المنطقة الزمنية';

  @override
  String get timeZoneHelp =>
      'تم ملؤها من هذا الجهاز. غيّرها إذا كانت العيادة تعمل في مكان آخر.';

  @override
  String get selectClinicTitle => 'اختيار عيادة';

  @override
  String get selectClinicBody =>
      'اختر العيادة التي تريد العمل فيها. يمكنك تبديل العيادة لاحقًا.';

  @override
  String get currentClinicTitle => 'تم اختيار العيادة';

  @override
  String currentClinicBody(Object clinicName) {
    return 'العيادة النشطة: $clinicName. اختر إجراءً من أدناه أو انتقل مباشرة إلى لوحة التحكم.';
  }

  @override
  String get switchClinicLabel => 'تبديل العيادة';

  @override
  String get addClinicLabel => 'إضافة عيادة أخرى';

  @override
  String get clinicLoadTitle => 'جارٍ تحميل عياداتك';

  @override
  String get clinicLoadFailed => 'تعذر تحميل عياداتك. حاول مرة أخرى.';

  @override
  String get timeZoneUtc => 'التوقيت العالمي المنسق';

  @override
  String get visitsTitle => 'الزيارات';

  @override
  String get newSessionLabel => 'جلسة جديدة';

  @override
  String get noVisitsMessage => 'لا توجد زيارات سريرية بعد.';

  @override
  String get clinicalViewOnly => 'لديك صلاحية عرض الجلسات السريرية فقط.';

  @override
  String get linkedAppointmentLabel => 'موعد مرتبط';

  @override
  String get walkInLabel => 'زيارة دون موعد';

  @override
  String get draftStatus => 'مسودة';

  @override
  String get finalizedStatus => 'نهائية';

  @override
  String get enteredInErrorStatus => 'أُدخلت بالخطأ';

  @override
  String get clinicalNotesLabel => 'الملاحظات السريرية';

  @override
  String get recommendationsLabel => 'التوصيات';

  @override
  String get saveDraftLabel => 'حفظ المسودة';

  @override
  String get finalizeSessionLabel => 'إنهاء الجلسة';

  @override
  String get markInErrorLabel => 'وضع علامة أُدخلت بالخطأ';

  @override
  String get addAmendmentLabel => 'إضافة تعديل';

  @override
  String get amendmentsTitle => 'التعديلات';

  @override
  String get amendmentTextLabel => 'التصحيح';

  @override
  String get reasonLabel => 'السبب';

  @override
  String get selectVisitTypeTitle => 'إنشاء جلسة سريرية';

  @override
  String get chooseAppointmentLabel => 'اختر الموعد';

  @override
  String get chooseDentistLabel => 'اختر طبيب الأسنان';

  @override
  String get visitDateTimeLabel => 'تاريخ ووقت الزيارة';

  @override
  String get createDraftLabel => 'إنشاء مسودة';

  @override
  String get cancelLabel => 'إلغاء';

  @override
  String get loadMoreLabel => 'تحميل المزيد';

  @override
  String get reloadLatestLabel => 'إعادة تحميل أحدث مسودة';

  @override
  String get revisionConflictMessage =>
      'حفظ موظف آخر هذه المسودة. أعد تحميل أحدث نسخة قبل المتابعة.';

  @override
  String get sessionUnavailableMessage => 'هذه الجلسة السريرية غير متاحة.';

  @override
  String get clinicalActionFailedMessage =>
      'تعذر إكمال الإجراء السريري. تحقق من الجلسة وحاول مرة أخرى.';

  @override
  String get finalizeWarning =>
      'بعد الإنهاء لا يمكن تعديل السجل السريري الأصلي. تتطلب التصحيحات تعديلاً موقعاً.';

  @override
  String get originalRecordTitle => 'السجل السريري الأصلي';

  @override
  String get appointmentSessionLabel => 'زيارة بموعد';

  @override
  String get sessionDateLabel => 'تاريخ الجلسة';

  @override
  String get assignedDentistLabel => 'طبيب الأسنان المعيّن';

  @override
  String get lastSavedLabel => 'آخر حفظ';

  @override
  String get openClinicalSessionLabel => 'فتح الجلسة السريرية';

  @override
  String get patientFilesTitle => 'ملفات المريض';

  @override
  String get uploadFileLabel => 'رفع ملف';

  @override
  String get noPatientFilesMessage => 'لا توجد ملفات للمريض بعد.';

  @override
  String get patientFilesViewOnly => 'لديك صلاحية عرض ملفات المريض فقط.';

  @override
  String get includeArchivedFilesLabel => 'إظهار الملفات المؤرشفة';

  @override
  String get allFileCategoriesLabel => 'كل الفئات';

  @override
  String get fileCategoryLabel => 'الفئة';

  @override
  String get fileCategoryXray => 'أشعة سينية';

  @override
  String get fileCategoryClinicalPhoto => 'صورة سريرية';

  @override
  String get fileCategoryConsent => 'موافقة';

  @override
  String get fileCategoryReferral => 'إحالة';

  @override
  String get fileCategoryLaboratory => 'نتيجة مختبر';

  @override
  String get fileCategoryOther => 'أخرى';

  @override
  String get fileDescriptionLabel => 'الوصف (اختياري)';

  @override
  String get chooseFileLabel => 'اختر JPG أو PNG أو PDF';

  @override
  String get fileTypeHelp => 'الحد الأقصى 15 ميغابايت. ملفات تجريبية فقط.';

  @override
  String get fileSelectionInvalid =>
      'اختر ملف JPG أو PNG أو PDF صالحاً بحجم لا يتجاوز 15 ميغابايت.';

  @override
  String get uploadingFileLabel => 'جارٍ رفع الملف';

  @override
  String get validatingFileLabel => 'جارٍ التحقق الآمن من الملف…';

  @override
  String get cancelUploadLabel => 'إلغاء الرفع';

  @override
  String get openFileLabel => 'فتح الملف';

  @override
  String get openPdfLabel => 'فتح PDF';

  @override
  String get archiveFileLabel => 'أرشفة الملف';

  @override
  String get restoreFileLabel => 'استعادة الملف';

  @override
  String get uploadReplacementLabel => 'رفع ملف بديل';

  @override
  String get archiveFileWarning =>
      'سيبقى الملف محفوظاً وقابلاً للتدقيق. أدخل سبب الأرشفة.';

  @override
  String get archivedFileLabel => 'مؤرشف';

  @override
  String get fileUnavailableMessage => 'ملف المريض هذا غير متاح.';

  @override
  String get fileActionFailedMessage =>
      'تعذر إكمال إجراء الملف. تحقق من الملف وحاول مرة أخرى.';

  @override
  String get fileSizeLabel => 'الحجم';

  @override
  String get uploadedAtLabel => 'تاريخ الرفع';

  @override
  String get fileLinkedVisitLabel => 'الزيارة المرتبطة';

  @override
  String get patientFilesRestricted =>
      'ملفات المريض متاحة فقط للطاقم السريري المخول.';

  @override
  String get billingTitle => 'الفوترة والفواتير';

  @override
  String get newInvoiceLabel => 'فاتورة جديدة';

  @override
  String get noInvoicesMessage => 'لا توجد فواتير بعد.';

  @override
  String get billingRestricted =>
      'الفوترة متاحة للموظفين السريريين وموظفي الفوترة المخولين.';

  @override
  String get invoiceDraftLabel => 'مسودة فاتورة';

  @override
  String get invoiceItemsTitle => 'بنود الفاتورة';

  @override
  String get noInvoiceItemsMessage => 'لم تتم إضافة أي إجراءات.';

  @override
  String get addCatalogueItemLabel => 'إضافة من قائمة الإجراءات';

  @override
  String get addTreatmentItemLabel => 'إضافة من خطة العلاج';

  @override
  String get quantityLabel => 'الكمية';

  @override
  String get approveContentLabel => 'اعتماد المحتوى السريري';

  @override
  String get reopenContentLabel => 'إعادة فتح المحتوى السريري';

  @override
  String get financialDetailsTitle => 'التفاصيل المالية';

  @override
  String get unitPriceLabel => 'سعر الوحدة';

  @override
  String get discountTypeLabel => 'نوع الخصم';

  @override
  String get discountNoneLabel => 'بدون خصم';

  @override
  String get discountFixedLabel => 'مبلغ ثابت';

  @override
  String get discountPercentageLabel => 'نسبة مئوية';

  @override
  String get discountValueLabel => 'قيمة الخصم';

  @override
  String get taxRateLabel => 'نسبة الضريبة (%)';

  @override
  String get invoiceLanguageLabel => 'لغة الفاتورة';

  @override
  String get languageEnglishLabel => 'الإنجليزية';

  @override
  String get languageRussianLabel => 'الروسية';

  @override
  String get languageArabicLabel => 'العربية';

  @override
  String get saveFinancialsLabel => 'حفظ التفاصيل المالية';

  @override
  String get finalizeInvoiceLabel => 'إصدار الفاتورة نهائياً';

  @override
  String get finalizeInvoiceWarning =>
      'يمنح الإصدار النهائي رقماً دائماً للفاتورة، وبعده لا يمكن تعديل البنود أو الأسعار.';

  @override
  String get cancelInvoiceLabel => 'إلغاء الفاتورة';

  @override
  String get recordPaymentLabel => 'تسجيل دفعة';

  @override
  String get paymentAmountLabel => 'المبلغ المستلم';

  @override
  String get paymentMethodLabel => 'طريقة الدفع';

  @override
  String get paymentCashLabel => 'نقداً';

  @override
  String get paymentCardLabel => 'بطاقة';

  @override
  String get paymentBankLabel => 'تحويل بنكي';

  @override
  String get paymentOtherLabel => 'أخرى';

  @override
  String get referenceLabel => 'المرجع (اختياري)';

  @override
  String get patientCreditLabel => 'رصيد المريض';

  @override
  String get applyCreditLabel => 'استخدام الرصيد';

  @override
  String get paymentHistoryTitle => 'الدفعات والتصحيحات';

  @override
  String get refundLabel => 'استرداد';

  @override
  String get correctionLabel => 'تصحيح';

  @override
  String get exportInvoiceLabel => 'فتح ملف PDF للفاتورة';

  @override
  String get invoiceSubtotalLabel => 'المجموع الفرعي';

  @override
  String get invoiceDiscountLabel => 'الخصم';

  @override
  String get invoiceTaxLabel => 'الضريبة';

  @override
  String get invoiceTotalLabel => 'الإجمالي';

  @override
  String get invoicePaidLabel => 'المدفوع';

  @override
  String get invoiceDueLabel => 'المستحق';

  @override
  String get paymentUnpaidLabel => 'غير مدفوع';

  @override
  String get paymentPartialLabel => 'مدفوع جزئياً';

  @override
  String get paymentPaidLabel => 'مدفوع';

  @override
  String get invoiceCancelledLabel => 'ملغاة';

  @override
  String get billingActionFailedMessage =>
      'تعذر إكمال إجراء الفوترة. أعد تحميل الفاتورة وحاول مرة أخرى.';

  @override
  String get billingConflictMessage =>
      'تغيرت هذه الفاتورة أو لم تعد مؤهلة لهذا الإجراء. أعد تحميلها وحاول مرة أخرى.';

  @override
  String get invoicePdfUnavailableMessage =>
      'تعذر إعداد ملف PDF للفاتورة. حاول مرة أخرى.';

  @override
  String get dashboardTitle => 'لوحة المعلومات';

  @override
  String get dashboardActivePatients => 'المرضى النشطون';

  @override
  String get dashboardAppointmentsThisWeek => 'مواعيد هذا الأسبوع';

  @override
  String get dashboardCompletedThisMonth => 'العلاجات المكتملة هذا الشهر';

  @override
  String get dashboardOutstandingPayments => 'الدفعات المستحقة';

  @override
  String dashboardOutstandingInvoices(int count) {
    return 'الفواتير المستحقة: $count';
  }

  @override
  String get dashboardTodayAppointments => 'مواعيد اليوم';

  @override
  String get dashboardUpcomingAppointments => 'المواعيد القادمة';

  @override
  String get dashboardNextSevenDays => 'الأيام السبعة القادمة';

  @override
  String get dashboardNoTodayAppointments => 'لا توجد مواعيد مقررة اليوم.';

  @override
  String get dashboardNoUpcomingAppointments =>
      'لا توجد مواعيد قادمة خلال الأيام السبعة المقبلة.';

  @override
  String get dashboardViewAllAppointments => 'عرض كل المواعيد';

  @override
  String dashboardLastUpdated(String value) {
    return 'آخر تحديث $value';
  }

  @override
  String dashboardTimeZone(String value) {
    return 'وقت العيادة · $value';
  }

  @override
  String get dashboardRefresh => 'تحديث لوحة المعلومات';

  @override
  String get dashboardRefreshFailed =>
      'تعذر تحميل أحدث البيانات. يتم عرض النتيجة السابقة.';

  @override
  String get dashboardUnavailable => 'لوحة معلومات العيادة غير متاحة مؤقتاً.';

  @override
  String get dashboardNoActiveClinic => 'اختر عيادة نشطة لفتح لوحة معلوماتها.';

  @override
  String get dashboardOpenPatients => 'فتح المرضى';

  @override
  String get dashboardOpenTreatments => 'فتح العلاجات';

  @override
  String get dashboardOpenBilling => 'فتح الفوترة';

  @override
  String get appointmentStatusScheduled => 'مجدول';

  @override
  String get appointmentStatusConfirmed => 'مؤكد';

  @override
  String get appointmentStatusInProgress => 'قيد التنفيذ';

  @override
  String get appointmentStatusCompleted => 'مكتمل';

  @override
  String get appointmentStatusNoShow => 'لم يحضر';

  @override
  String get appointmentStatusCancelled => 'ملغى';

  @override
  String get auditTitle => 'سجل التدقيق';

  @override
  String get auditOpen => 'فتح سجل التدقيق';

  @override
  String get auditRefresh => 'تحديث سجل التدقيق';

  @override
  String get auditUnavailable => 'سجل التدقيق غير متاح مؤقتاً.';

  @override
  String get auditOwnerOnly => 'يمكن لمالك العيادة النشط فقط عرض سجل التدقيق.';

  @override
  String get auditNoEvents => 'لا يوجد نشاط مسجل في نطاق التاريخ هذا.';

  @override
  String get auditNoFilterResults => 'لا يوجد نشاط يطابق عوامل التصفية.';

  @override
  String get auditFilters => 'عوامل التصفية';

  @override
  String get auditClearFilters => 'مسح عوامل التصفية';

  @override
  String get auditDateRange => 'نطاق التاريخ';

  @override
  String get auditEmployee => 'الموظف';

  @override
  String get auditAllEmployees => 'كل الموظفين';

  @override
  String get auditCategory => 'الفئة';

  @override
  String get auditAllCategories => 'كل الفئات';

  @override
  String get auditEntityType => 'نوع السجل';

  @override
  String get auditAllEntities => 'كل السجلات';

  @override
  String get auditLoadMore => 'تحميل المزيد';

  @override
  String get auditDetails => 'تفاصيل الحدث';

  @override
  String get auditOccurredAt => 'الوقت';

  @override
  String get auditAction => 'الإجراء';

  @override
  String get auditEntity => 'السجل';

  @override
  String get auditReason => 'السبب';

  @override
  String get auditNoReason => 'لم يتم تسجيل سبب';

  @override
  String get auditActorRoles => 'الأدوار في ذلك الوقت';

  @override
  String get auditFormerActor => 'موظف سابق أو غير متاح';

  @override
  String get auditCategoryAccess => 'الوصول';

  @override
  String get auditCategoryPatient => 'إدارة المرضى';

  @override
  String get auditCategoryScheduling => 'الجدولة';

  @override
  String get auditCategoryClinical => 'سريري';

  @override
  String get auditCategoryFinancial => 'مالي';

  @override
  String get auditCategoryStaff => 'الموظفون والأمان';

  @override
  String get auditOtherAction => 'إجراء مسجل آخر';

  @override
  String get auditOpenRecord => 'فتح السجل المرتبط';

  @override
  String auditShowingRange(String from, String to, String timeZone) {
    return '$from – $to · $timeZone';
  }

  @override
  String get auditRefreshFailed =>
      'تعذر تحميل أحدث أحداث التدقيق. يتم عرض النتيجة السابقة.';

  @override
  String get auditActionAccess => 'تم تسجيل وصول إلى بيانات حساسة';

  @override
  String get auditActionPatient => 'تم تغيير بيانات إدارية للمريض';

  @override
  String get auditActionScheduling => 'تم تغيير الجدول أو الموعد';

  @override
  String get auditActionClinical => 'تم تغيير سجل سريري';

  @override
  String get auditActionFinancial => 'تم تغيير سجل مالي';

  @override
  String get auditActionStaff => 'تم تغيير الموظفين أو الأمان';

  @override
  String get roleOwner => 'المالك';

  @override
  String get roleDentist => 'طبيب الأسنان';

  @override
  String get roleAssistant => 'المساعد';

  @override
  String get roleReceptionist => 'موظف الاستقبال';

  @override
  String get auditResultCount => 'عدد النتائج';

  @override
  String get auditApplyFilters => 'تطبيق عوامل التصفية';

  @override
  String appointmentsWithTimeZone(String timeZone) {
    return 'المواعيد · $timeZone';
  }

  @override
  String get previousWeekLabel => 'الأسبوع السابق';

  @override
  String get nextWeekLabel => 'الأسبوع التالي';

  @override
  String get newAppointmentLabel => 'موعد جديد';

  @override
  String get noAppointmentsWeek => 'لا توجد مواعيد هذا الأسبوع.';

  @override
  String get chooseClinicFirst => 'اختر عيادة أولاً.';

  @override
  String clinicTimeZoneValue(String timeZone) {
    return 'المنطقة الزمنية للعيادة: $timeZone';
  }

  @override
  String get findPatientLabel =>
      'البحث عن مريض بالاسم أو الهاتف أو البريد أو الرقم';

  @override
  String patientSelectedValue(String patientId) {
    return 'المريض المحدد: $patientId';
  }

  @override
  String get dentistLabel => 'طبيب الأسنان';

  @override
  String get chooseDentistValidation => 'اختر طبيب أسنان';

  @override
  String get dateLabel => 'التاريخ';

  @override
  String get startTimeLabel => 'وقت البدء';

  @override
  String get durationLabel => 'المدة';

  @override
  String minutesValue(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get appointmentPurposeOptional => 'الغرض (اختياري، غير سريري)';

  @override
  String get ownerOverrideOptional => 'سبب تجاوز المالك (عند الحاجة فقط)';

  @override
  String get createAppointmentLabel => 'إنشاء الموعد';

  @override
  String get rescheduleLabel => 'إعادة الجدولة';

  @override
  String get confirmLabel => 'تأكيد';

  @override
  String get startLabel => 'بدء';

  @override
  String get completeLabel => 'إكمال';

  @override
  String get markNoShowLabel => 'تسجيل عدم الحضور';

  @override
  String get preparationNoteLabel => 'ملاحظة التحضير';

  @override
  String get ownerOverrideReasonTitle => 'سبب تجاوز المالك';

  @override
  String get overrideConflictHelp => 'مطلوب فقط إذا تعارض الوقت الجديد';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get useReasonLabel => 'استخدام السبب';

  @override
  String get operationalPreparationNoteTitle => 'ملاحظة التحضير التشغيلية';

  @override
  String get saveLabel => 'حفظ';

  @override
  String get cancellationReasonTitle => 'سبب الإلغاء';

  @override
  String get appointmentUnavailableIssue => 'المريض أو الموعد غير متاح.';

  @override
  String get appointmentForbiddenIssue =>
      'دورك لا يسمح بتنفيذ هذا الإجراء على الموعد.';

  @override
  String get appointmentPatientOverlapIssue => 'لدى المريض موعد آخر متداخل.';

  @override
  String get appointmentDentistOverlapIssue =>
      'لدى طبيب الأسنان موعد آخر متداخل.';

  @override
  String get appointmentWorkingHoursIssue =>
      'هذا الوقت خارج ساعات عمل طبيب الأسنان.';

  @override
  String get appointmentLeaveIssue => 'طبيب الأسنان في إجازة في هذا الوقت.';

  @override
  String get appointmentUnavailablePeriodIssue =>
      'طبيب الأسنان غير متاح في هذا الوقت.';

  @override
  String get appointmentOverrideRequiredIssue =>
      'يجب على المالك إضافة سبب لتجاوز هذا التعارض.';

  @override
  String get appointmentInvalidTransitionIssue =>
      'لا يمكن تغيير حالة الموعد بهذه الطريقة.';

  @override
  String get patientsTitle => 'المرضى';

  @override
  String get newPatientLabel => 'مريض جديد';

  @override
  String get searchPatientLabel => 'البحث بالاسم أو الهاتف أو البريد أو الرقم';

  @override
  String get archivedLabel => 'مؤرشف';

  @override
  String get patientActionUnavailable => 'هذا الإجراء على المريض غير متاح.';

  @override
  String get noPatientsFound => 'لم يتم العثور على مرضى.';

  @override
  String get noContactLabel => 'لا توجد معلومات اتصال';

  @override
  String get firstNameLabel => 'الاسم الأول';

  @override
  String get lastNameLabel => 'اسم العائلة';

  @override
  String get phoneLabel => 'الهاتف';

  @override
  String get birthDateInformationLabel => 'معلومات تاريخ الميلاد';

  @override
  String get birthPrecisionUnknown => 'غير معروف';

  @override
  String get birthPrecisionExact => 'دقيق';

  @override
  String get birthPrecisionApproximate => 'تقريبي';

  @override
  String get birthDateFormatLabel => 'تاريخ الميلاد (YYYY-MM-DD)';

  @override
  String get approximateAgeLabel => 'العمر التقريبي بالسنوات';

  @override
  String get ageAssessedOnLabel => 'تاريخ تقدير العمر (YYYY-MM-DD)';

  @override
  String get knownMinorLabel => 'من المعروف أن المريض دون 18 عامًا';

  @override
  String get guardianNameLabel => 'اسم ولي الأمر';

  @override
  String get guardianPhoneLabel => 'هاتف ولي الأمر';

  @override
  String get guardianEmailLabel => 'بريد ولي الأمر';

  @override
  String get createPatientLabel => 'إنشاء المريض';

  @override
  String get patientProfileTitle => 'ملف المريض';

  @override
  String get patientProfileUnavailable =>
      'ملف المريض غير متاح. ارجع إلى البحث واختر المريض مرة أخرى.';

  @override
  String get contactTitle => 'معلومات الاتصال';

  @override
  String get medicalProfileTitle => 'الملف الطبي';

  @override
  String get appointmentsTitle => 'المواعيد';

  @override
  String get dentalChartTitle => 'مخطط الأسنان';

  @override
  String get treatmentPlansTitle => 'خطط العلاج';

  @override
  String get restorePatientLabel => 'استعادة المريض';

  @override
  String get archivePatientLabel => 'أرشفة المريض';

  @override
  String get birthInformationTitle => 'معلومات الميلاد';

  @override
  String approximatelyYearsValue(int years) {
    return 'حوالي $years سنة';
  }

  @override
  String get archivePatientQuestion => 'أرشفة المريض؟';

  @override
  String get restorePatientQuestion => 'استعادة المريض؟';

  @override
  String get archivePatientExplanation =>
      'يبقى المرضى المؤرشفون في سجل العيادة ويمكن للمالك استعادتهم.';

  @override
  String get restorePatientExplanation => 'سيعود المريض إلى سجل العيادة النشط.';

  @override
  String get archiveLabel => 'أرشفة';

  @override
  String get restoreLabel => 'استعادة';

  @override
  String get medicalRoleRestricted => 'المعلومات الطبية غير متاحة لدورك.';

  @override
  String get allergiesLabel => 'الحساسية';

  @override
  String get currentMedicationsLabel => 'الأدوية الحالية';

  @override
  String get chronicConditionsLabel => 'الحالات المزمنة';

  @override
  String get importantMedicalNotesLabel => 'ملاحظات طبية مهمة';

  @override
  String get saveMedicalProfileLabel => 'حفظ الملف الطبي';

  @override
  String get staffTitle => 'الموظفون';

  @override
  String get backLabel => 'رجوع';

  @override
  String get inviteStaffLabel => 'دعوة موظف';

  @override
  String get staffOwnerOnly => 'يمكن لمالكي العيادة فقط إدارة الموظفين.';

  @override
  String get manageStaffDescription => 'إدارة الأدوار والوصول لهذه العيادة.';

  @override
  String get webInvitationOnly => 'أرسل الدعوات من مساحة عمل الويب.';

  @override
  String get verifiedEmailLabel => 'البريد الإلكتروني المؤكد';

  @override
  String get sendInvitationLabel => 'إرسال الدعوة';

  @override
  String get saveRolesLabel => 'حفظ الأدوار';

  @override
  String get reactivateStaffQuestion => 'إعادة تنشيط الموظف؟';

  @override
  String get deactivateStaffQuestion => 'إلغاء تنشيط الموظف؟';

  @override
  String get reactivateLabel => 'إعادة التنشيط';

  @override
  String get deactivateLabel => 'إلغاء التنشيط';

  @override
  String get confirmPasswordTitle => 'تأكيد كلمة المرور';

  @override
  String get invalidInvitationLink => 'رابط الدعوة غير صالح أو غير متاح.';

  @override
  String get joinClinicTitle => 'الانضمام إلى العيادة';

  @override
  String get acceptInvitationHelp =>
      'اقبل هذه الدعوة فقط إذا سجلت الدخول بالبريد الإلكتروني الذي أُرسلت إليه.';

  @override
  String get acceptInvitationLabel => 'قبول الدعوة';

  @override
  String staffCountTitle(int count) {
    return 'الموظفون ($count)';
  }

  @override
  String get inactiveLabel => 'غير نشط';

  @override
  String get editRolesLabel => 'تعديل الأدوار';

  @override
  String invitationCountTitle(int count) {
    return 'الدعوات ($count)';
  }

  @override
  String get resendInvitationLabel => 'إعادة الإرسال';

  @override
  String get revokeInvitationLabel => 'إلغاء الدعوة';

  @override
  String get invitationPending => 'قيد الانتظار';

  @override
  String get invitationAccepted => 'مقبولة';

  @override
  String get invitationRevoked => 'ملغاة';

  @override
  String get invitationExpired => 'منتهية';

  @override
  String get staffInvalidInputIssue => 'تحقق من المعلومات وحاول مرة أخرى.';

  @override
  String get ownerPasswordRequiredIssue => 'أكد كلمة المرور للمتابعة.';

  @override
  String get invitationUnavailableIssue => 'هذه الدعوة غير متاحة.';

  @override
  String get staffMemberUnavailableIssue => 'هذا الموظف غير متاح.';

  @override
  String get doctorScheduleTitle => 'جدول الأطباء';

  @override
  String get scheduleChooseClinic => 'اختر عيادة قبل عرض الجداول.';

  @override
  String clinicTimeZoneExplanation(String timeZone) {
    return 'تستخدم جميع الأوقات المنطقة الزمنية للعيادة: $timeZone.';
  }

  @override
  String get setWeeklyHoursLabel => 'تعيين ساعات العمل الأسبوعية';

  @override
  String get addUnavailableTimeLabel => 'إضافة إجازة أو وقت غير متاح';

  @override
  String get weeklyHoursTitle => 'ساعات العمل الأسبوعية';

  @override
  String get noWeeklyHours => 'لم يتم تعيين ساعات عمل أسبوعية لهذا الطبيب.';

  @override
  String get unavailablePeriodsTitle => 'الإجازات وفترات عدم التوفر';

  @override
  String get noUnavailablePeriods => 'لا توجد إجازات أو فترات عدم توفر مسجلة.';

  @override
  String get leaveLabel => 'إجازة';

  @override
  String get unavailableLabel => 'غير متاح';

  @override
  String get removeLabel => 'إزالة';

  @override
  String scheduleConflictOwnerReview(int count) {
    return 'يتعارض هذا التغيير مع $count موعد مستقبلي. يجب أن يراجعه المالك.';
  }

  @override
  String get weekdayNumberHelp => 'استخدم 1 ليوم الاثنين حتى 7 ليوم الأحد.';

  @override
  String get workingDaysLabel => 'أيام العمل';

  @override
  String get startTimeFormatLabel => 'وقت البدء (HH:MM)';

  @override
  String get endTimeFormatLabel => 'وقت الانتهاء (HH:MM)';

  @override
  String get breakStartOptional => 'بداية الاستراحة (اختياري)';

  @override
  String get breakEndOptional => 'نهاية الاستراحة (اختياري)';

  @override
  String get effectiveFromFormatLabel => 'ساري من (YYYY-MM-DD)';

  @override
  String get addUnavailableTimeTitle => 'إضافة وقت غير متاح';

  @override
  String get typeLabel => 'النوع';

  @override
  String get startsLabel => 'يبدأ';

  @override
  String get endsLabel => 'ينتهي';

  @override
  String get reasonOptionalLabel => 'السبب (اختياري)';

  @override
  String effectiveFromValue(String date) {
    return 'ساري من $date';
  }

  @override
  String get noWorkingHours => 'لا توجد ساعات عمل';

  @override
  String get breakLabel => 'استراحة';

  @override
  String get reviewAffectedAppointmentsTitle => 'مراجعة المواعيد المتأثرة';

  @override
  String affectedAppointmentsExplanation(int count) {
    return 'يتعارض هذا التغيير مع $count موعد مستقبلي. ستبقى محجوزة وتُعلَّم للحل اليدوي.';
  }

  @override
  String get ownerConfirmationReasonLabel => 'سبب تأكيد المالك';

  @override
  String get cancelChangeLabel => 'إلغاء التغيير';

  @override
  String get confirmAndFlagLabel => 'تأكيد ووضع علامة';

  @override
  String get weekdayMon => 'الاثنين';

  @override
  String get weekdayTue => 'الثلاثاء';

  @override
  String get weekdayWed => 'الأربعاء';

  @override
  String get weekdayThu => 'الخميس';

  @override
  String get weekdayFri => 'الجمعة';

  @override
  String get weekdaySat => 'السبت';

  @override
  String get weekdaySun => 'الأحد';

  @override
  String get scheduleEditForbiddenIssue =>
      'لا يمكنك تغيير جدول طبيب الأسنان هذا.';

  @override
  String get activeDentistRequiredIssue => 'هذا الموظف ليس طبيب أسنان نشطًا.';

  @override
  String get effectiveDateInvalidIssue => 'اختر تاريخًا مستقبليًا للعيادة.';

  @override
  String get exceptionUnavailableIssue => 'فترة عدم التوفر هذه لم تعد متاحة.';

  @override
  String get affectedAppointmentsIssue =>
      'يؤثر تغيير الجدول على مواعيد مستقبلية ويتطلب مراجعة المالك.';

  @override
  String get scheduleSavedMessage => 'تم حفظ ساعات العمل الأسبوعية.';

  @override
  String get scheduleInvalidInputMessage =>
      'تحقق من أيام العمل والأوقات والاستراحة وتاريخ بدء السريان.';

  @override
  String get scheduleForLabel => 'الجدول للطبيب';

  @override
  String get scheduleActiveLabel => 'الجدول النشط';

  @override
  String get scheduleUpcomingLabel => 'الجدول القادم';

  @override
  String get scheduleHistoryLabel => 'سجل الجداول';

  @override
  String get scheduleHistoryHelp => 'إصدارات ساعات العمل السابقة والمستبدلة';

  @override
  String get editWeeklyHoursLabel => 'تعديل الجدول الأسبوعي';

  @override
  String get selectWorkingDaysHelp =>
      'اختر الأيام التي يعمل فيها طبيب الأسنان.';

  @override
  String get includeBreakLabel => 'إضافة استراحة';

  @override
  String get effectiveDateLabel => 'تاريخ بدء السريان';

  @override
  String get closedLabel => 'مغلق';

  @override
  String get scheduleSummaryLabel => 'ملخص الجدول';

  @override
  String get procedureCatalogueTitle => 'دليل الإجراءات';

  @override
  String get backToClinicLabel => 'العودة إلى العيادة';

  @override
  String get newProcedureLabel => 'إجراء جديد';

  @override
  String get editProcedureLabel => 'تعديل الإجراء';

  @override
  String get procedureCatalogueOwnerHelp =>
      'أنشئ الخدمات التي يمكن للأطباء إضافتها إلى خطط العلاج.';

  @override
  String get procedureCatalogueViewerHelp =>
      'إجراءات العيادة المتاحة وأسعارها القياسية.';

  @override
  String get noProceduresCatalogue =>
      'لا توجد إجراءات بعد. يمكن للمالك إضافة الإجراء الأول.';

  @override
  String get editLabel => 'تعديل';

  @override
  String get activateLabel => 'تنشيط';

  @override
  String get activeLabel => 'نشط';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get categoryLabel => 'الفئة';

  @override
  String get standardPriceLabel => 'السعر القياسي';

  @override
  String get durationMinutesLabel => 'المدة بالدقائق';

  @override
  String get validPriceValidation => 'أدخل سعرًا صالحًا.';

  @override
  String get durationRangeValidation => 'استخدم مدة من 5 إلى 720 دقيقة.';

  @override
  String get treatmentPlansUnavailable =>
      'خطط العلاج غير متاحة. ارجع إلى قائمة المرضى واختر المريض مرة أخرى.';

  @override
  String get noActiveDentist => 'لا يوجد طبيب أسنان نشط متاح.';

  @override
  String get newPlanLabel => 'خطة جديدة';

  @override
  String get treatmentViewOnly => 'دورك يتيح عرض خطط العلاج فقط.';

  @override
  String get noTreatmentPlan =>
      'لا توجد خطة علاج بعد. يمكن لطبيب الأسنان إعداد مسودة.';

  @override
  String get newTreatmentPlanTitle => 'خطة علاج جديدة';

  @override
  String get leadDentistLabel => 'طبيب الأسنان المسؤول';

  @override
  String get planNotesOptional => 'ملاحظات الخطة (اختياري)';

  @override
  String get editPlanNotesTitle => 'تعديل ملاحظات الخطة';

  @override
  String get notesLabel => 'الملاحظات';

  @override
  String get ownerAddProcedureFirst =>
      'يجب على مالك العيادة إضافة إجراء نشط أولاً.';

  @override
  String get addProcedureLabel => 'إضافة إجراء';

  @override
  String get procedureLabel => 'الإجراء';

  @override
  String get fdiToothOptional => 'رقم السن وفق FDI (اختياري)';

  @override
  String get validFdiValidation => 'أدخل رقم سن صالحًا وفق FDI.';

  @override
  String get estimatedPriceLabel => 'السعر التقديري';

  @override
  String get assignedDentistOptional => 'طبيب الأسنان المعيّن (اختياري)';

  @override
  String get notAssignedLabel => 'غير معيّن';

  @override
  String get clinicalDescriptionOptional => 'الوصف السريري (اختياري)';

  @override
  String get saveProcedureLabel => 'حفظ الإجراء';

  @override
  String planTransitionQuestion(String status) {
    return 'تغيير خطة العلاج إلى «$status»؟';
  }

  @override
  String get activatePlanExplanation =>
      'يجعل هذا الخطة هي خطة العلاج النشطة للمريض.';

  @override
  String get finalPlanTransitionExplanation =>
      'يُسجّل تغيير الحالة ولا يمكن التراجع عنه.';

  @override
  String get plansTitle => 'الخطط';

  @override
  String procedureCountValue(int count) {
    return '$count إجراء';
  }

  @override
  String get editNotesLabel => 'تعديل الملاحظات';

  @override
  String get activatePlanLabel => 'تنشيط الخطة';

  @override
  String get cancelPlanLabel => 'إلغاء الخطة';

  @override
  String get completePlanLabel => 'إكمال الخطة';

  @override
  String get planHasNoProcedures => 'لا تحتوي هذه الخطة على إجراءات بعد.';

  @override
  String get unavailableProcedure => 'إجراء غير متاح';

  @override
  String toothNumberValue(int number) {
    return 'السن $number';
  }

  @override
  String dentistValue(String email) {
    return 'طبيب الأسنان: $email';
  }

  @override
  String get changeStatusLabel => 'تغيير الحالة';

  @override
  String get planStatusDraft => 'مسودة';

  @override
  String get planStatusActive => 'نشطة';

  @override
  String get planStatusCompleted => 'مكتملة';

  @override
  String get planStatusCancelled => 'ملغاة';

  @override
  String get itemStatusPlanned => 'مخطط';

  @override
  String get itemStatusApproved => 'معتمد';

  @override
  String get itemStatusInProgress => 'قيد التنفيذ';

  @override
  String get itemStatusCompleted => 'مكتمل';

  @override
  String get itemStatusCancelled => 'ملغى';

  @override
  String get treatmentForbiddenIssue => 'دورك في العيادة لا يسمح بهذا التغيير.';

  @override
  String get treatmentUnavailableIssue => 'هذا السجل لم يعد متاحًا.';

  @override
  String get treatmentInvalidInputIssue =>
      'تحقق من المعلومات المدخلة وحاول مرة أخرى.';

  @override
  String get treatmentDraftOnlyIssue => 'يمكن تعديل مسودة خطة العلاج فقط.';

  @override
  String get treatmentActiveRequiredIssue =>
      'يجب أن تكون خطة العلاج نشطة لهذا التغيير.';

  @override
  String get treatmentItemsRequiredIssue =>
      'أضف إجراءً واحدًا على الأقل قبل تنشيط الخطة.';

  @override
  String get activePlanExistsIssue => 'لدى هذا المريض خطة علاج نشطة بالفعل.';

  @override
  String get treatmentInvalidTransitionIssue => 'تغيير الحالة هذا غير مسموح.';

  @override
  String get dentalChartUnavailable =>
      'مخطط الأسنان غير متاح. ارجع إلى قائمة المرضى واختر المريض مرة أخرى.';

  @override
  String get backToPatientProfile => 'العودة إلى ملف المريض';

  @override
  String get permanentTeethLabel => 'الأسنان الدائمة';

  @override
  String get primaryTeethLabel => 'الأسنان اللبنية';

  @override
  String get selectToothToAdd => 'اختر سنًا لإضافة حالة';

  @override
  String addConditionToTooth(int number) {
    return 'إضافة حالة إلى السن $number';
  }

  @override
  String get selectToothFirst => 'اختر سنًا أولاً.';

  @override
  String addConditionTitle(int number) {
    return 'إضافة حالة — السن $number';
  }

  @override
  String get conditionLabel => 'الحالة';

  @override
  String get surfaceLabel => 'السطح';

  @override
  String get clinicalNoteOptional => 'ملاحظة سريرية (اختياري)';

  @override
  String get saveConditionLabel => 'حفظ الحالة';

  @override
  String get resolveConditionQuestion => 'حل الحالة؟';

  @override
  String resolveConditionExplanation(String condition, int number) {
    return 'ستبقى حالة $condition على السن $number في سجل المريض.';
  }

  @override
  String get resolveLabel => 'حل';

  @override
  String get markEntryErrorTitle => 'وضع علامة خطأ على السجل';

  @override
  String get entryErrorReasonLabel => 'لماذا هذا السجل غير صحيح؟';

  @override
  String get preserveAsErrorLabel => 'حفظ كسجل خاطئ';

  @override
  String get selectToothReview => 'اختر سنًا لمراجعة حالاته النشطة.';

  @override
  String healthyToothMessage(int number) {
    return 'السن $number سليم. لا توجد حالة نشطة مسجلة.';
  }

  @override
  String toothHealthySemantics(int number) {
    return 'السن $number، سليم';
  }

  @override
  String toothConditionsSemantics(int number, int count) {
    return 'السن $number، $count حالات نشطة';
  }

  @override
  String get markAsErrorLabel => 'وضع علامة خطأ';

  @override
  String get conditionHistoryTitle => 'سجل الحالات';

  @override
  String recordedItemsValue(int count) {
    return '$count عناصر مسجلة';
  }

  @override
  String get noDentalHistory => 'لم يتم تسجيل سجل لمخطط الأسنان بعد.';

  @override
  String get loadMoreHistoryLabel => 'تحميل المزيد من السجل';

  @override
  String get dentalRoleRestricted =>
      'التفاصيل السريرية لمخطط الأسنان غير متاحة لدورك.';

  @override
  String get surfaceWhole => 'السن بالكامل';

  @override
  String get surfaceMesial => 'أنسي';

  @override
  String get surfaceDistal => 'بعيد';

  @override
  String get surfaceOcclusal => 'إطباقي';

  @override
  String get surfaceBuccal => 'شدقي';

  @override
  String get surfaceLingual => 'لساني';

  @override
  String get conditionCaries => 'تسوس';

  @override
  String get conditionFilling => 'حشوة';

  @override
  String get conditionCrown => 'تاج';

  @override
  String get conditionRootCanal => 'علاج الجذر';

  @override
  String get conditionFracture => 'كسر';

  @override
  String get conditionMissing => 'مفقود';

  @override
  String get conditionExtraction => 'يتطلب الخلع';

  @override
  String get conditionImplant => 'زرعة';

  @override
  String get conditionStatusActive => 'نشطة';

  @override
  String get conditionStatusResolved => 'محلولة';

  @override
  String get conditionStatusError => 'أُدخلت بالخطأ';

  @override
  String get odontogramForbiddenIssue =>
      'دورك لا يسمح بتغيير حالات مخطط الأسنان.';

  @override
  String get odontogramUnavailableIssue =>
      'هذا المريض أو الحالة لم يعد متاحًا.';

  @override
  String get odontogramInvalidInputIssue =>
      'تحقق من السن والسطح وتفاصيل الحالة.';

  @override
  String get missingToothConflictIssue =>
      'حل أو صحح حالة السن الطبيعي الحالية قبل تسجيل السن كمفقود.';

  @override
  String get duplicateConditionIssue =>
      'هذه الحالة النشطة مسجلة بالفعل لسطح السن المحدد.';

  @override
  String get conditionNotActiveIssue =>
      'هذه الحالة مغلقة بالفعل وتبقى في السجل.';

  @override
  String get validAmountValidation => 'أدخل مبلغًا صالحًا.';

  @override
  String get quantityRangeValidation => 'أدخل كمية من 0.01 إلى 999.99.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get moreLabel => 'المزيد';

  @override
  String get workspaceNavigationLabel => 'التنقل في مساحة العمل';

  @override
  String get themeSystemLabel => 'سمة النظام';

  @override
  String get languageSystemLabel => 'لغة النظام';

  @override
  String get clinicSectionTitle => 'العيادة';

  @override
  String get privacySectionTitle => 'الخصوصية';

  @override
  String get accountSectionTitle => 'الحساب';

  @override
  String get applicationSectionTitle => 'التطبيق';

  @override
  String get developmentMvpLabel => 'نسخة تطوير أولية · بيانات خيالية فقط';

  @override
  String get currentRoleLabel => 'دورك';

  @override
  String get patientNumberLabel => 'رقم المريض';

  @override
  String get patientNameLabel => 'المريض';

  @override
  String get statusLabel => 'الحالة';

  @override
  String get todayLabel => 'اليوم';

  @override
  String get noAppointmentsDay => 'لا توجد مواعيد مجدولة لهذا اليوم.';

  @override
  String get dentitionLabel => 'مجموعة الأسنان';

  @override
  String get quadrantUpperRight => 'العلوي الأيمن (UR)';

  @override
  String get quadrantUpperLeft => 'العلوي الأيسر (UL)';

  @override
  String get quadrantLowerRight => 'السفلي الأيمن (LR)';

  @override
  String get quadrantLowerLeft => 'السفلي الأيسر (LL)';

  @override
  String get dentalMidline => 'خط الوسط';

  @override
  String get maxillaUpperJaw => 'الفك العلوي';

  @override
  String get mandibleLowerJaw => 'الفك السفلي';

  @override
  String get visitReasonLabel => 'سبب الزيارة';

  @override
  String get quickReasonCheckup => 'فحص روتيني';

  @override
  String get quickReasonCleaning => 'تنظيف أسنان';

  @override
  String get quickReasonToothache => 'ألم أسنان / طارئ';

  @override
  String get quickReasonConsultation => 'استشارة';

  @override
  String get quickReasonFollowUp => 'متابعة';

  @override
  String doctorWorkingHours(String hours) {
    return 'ساعات العمل: $hours';
  }

  @override
  String get doctorOffDuty => 'الطبيب ليس لديه ساعات عمل مجدولة في هذا اليوم';

  @override
  String get doctorOnLeave => 'الطبيب في إجازة في هذا التاريخ';

  @override
  String get changePatientLabel => 'تغيير المريض';

  @override
  String get overrideScheduleQuestion => 'تجاوز تعارض جدول الطبيب (للمالك فقط)';

  @override
  String get selectedPatientCardTitle => 'المريض المحدد';

  @override
  String get doctorNoScheduleConfigured =>
      'لم يتم ضبط جدول دوام لهذا الطبيب في العيادة بعد';

  @override
  String timeOutsideWorkingHours(String time, String hours) {
    return 'الوقت المحدد ($time) خارج أوقات دوام الطبيب ($hours)';
  }

  @override
  String get appointmentConflictExplanation =>
      'يتعارض هذا الموعد مع جدول الطبيب (عطلة، إجازة، أو خارج أوقات الدوام). بصفتك مالك العيادة، يرجى كتابة سبب التجاوز أعلاه لإتمام الحجز.';

  @override
  String get middleNameLabel => 'الاسم الأوسط / اسم الأب';

  @override
  String get administrativeNotesLabel => 'ملاحظات إدارية / خاصة';

  @override
  String get personalInformationSection => 'البيانات الشخصية';

  @override
  String get contactInformationSection => 'بيانات الاتصال';

  @override
  String get birthAndAgeSection => 'تاريخ الميلاد والعمر';

  @override
  String get selectBirthDateLabel => 'اختر تاريخ الميلاد';

  @override
  String get guardianInformationSection =>
      'بيانات ولي الأمر / المرافق (للقاصر)';

  @override
  String get newPatientShortcut => '+ تسجيل مريض جديد';

  @override
  String yearsOldValue(int age) {
    return '$age سنة';
  }

  @override
  String get ageInYearsLabel => 'العمر بالسنوات';

  @override
  String get clinicalHubTitle => 'السجلات والمعالجة السريرية';

  @override
  String get administrativeHubTitle => 'الإدارة والمواعيد';

  @override
  String get bookAppointmentLabel => 'حجز موعد';

  @override
  String get minorBadge => 'قاصر';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get copyLabel => 'نسخ';

  @override
  String durationMinutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String appointmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count موعد',
      many: '$count موعداً',
      few: '$count مواعيد',
      two: 'موعدان',
      one: 'موعد واحد',
      zero: 'لا توجد مواعيد',
    );
    return '$_temp0';
  }

  @override
  String get viewProfileLabel => 'الملف';

  @override
  String get preparationNoteBadge => 'ملاحظة تجهيز';

  @override
  String get overrideBadge => 'تجاوز';

  @override
  String get emptyCalendarTitle => 'لا توجد مواعيد مجدولة';

  @override
  String get emptyCalendarHelp =>
      'استخدم الزر أدناه أو غيّر التاريخ لعرض المواعيد أو حجز موعد جديد.';

  @override
  String get medicalAlertsTitle => 'تنبيهات طبية وحساسية';

  @override
  String get noKnownAllergies =>
      'لا توجد أي حساسية دوائية أو تحذيرات طبية مسجلة';

  @override
  String get unscreenedMedicalHelp =>
      'لم يتم تسجيل التاريخ الطبي بعد. يُنصح بإجراء الفحص الطبي قبل الإجراءات السريرية.';

  @override
  String get screenMedicalLabel => 'فحص التاريخ الطبي';

  @override
  String get whatsAppLabel => 'واتساب';

  @override
  String get callLabel => 'اتصال';

  @override
  String get emailActionLabel => 'إرسال بريد';

  @override
  String get sendWhatsAppReminder => 'تذكير عبر واتساب';

  @override
  String reminderMessageTemplate(
    String patientName,
    String clinicName,
    String dentistName,
    String date,
    String time,
  ) {
    return 'مرحباً $patientName، نود تذكيركم بموعدكم لدى $clinicName مع د. $dentistName يوم $date في تمام الساعة $time. يُرجى الرد على هذه الرسالة لتأكيد الحضور. شكراً لكم!';
  }

  @override
  String get noPhoneForPatient => 'لا يوجد رقم هاتف مسجل لهذا المريض.';

  @override
  String get communicationLaunchFailed => 'تعذر فتح التطبيق.';

  @override
  String get loadStandardProcedures => 'تحميل الخدمات القياسية';

  @override
  String get loadStandardProceduresHelp =>
      'إضافة قائمة الخدمات السنية القياسية الشائعة بسرعة إلى قائمة العيادة.';

  @override
  String loadStandardProceduresConfirm(int count) {
    return 'سيتم إضافة $count خدمة سنية قياسية إلى قائمة العيادة. يمكنك تعديل الأسعار والمدد في أي وقت. هل ترغب في المتابعة؟';
  }

  @override
  String get searchProceduresPlaceholder => 'البحث عن خدمة أو تصنيف...';

  @override
  String get allCategoriesLabel => 'جميع التصنيفات';

  @override
  String get activeOnlyFilter => 'النشطة فقط';

  @override
  String totalProceduresCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إجراء',
      many: '$count إجراءً',
      few: '$count إجراءات',
      two: 'إجراءان',
      one: 'إجراء واحد',
      zero: 'لا توجد إجراءات',
    );
    return '$_temp0';
  }

  @override
  String activeProceduresCount(int count) {
    return '$count نشطة';
  }

  @override
  String categoriesCount(int count) {
    return '$count تصنيفات';
  }

  @override
  String standardProceduresImported(int count) {
    return 'تم استيراد $count إجراء قياسي بنجاح.';
  }

  @override
  String get noMatchingProcedures =>
      'لا توجد خدمات تطابق البحث أو التصفية الحالية.';

  @override
  String get clearFiltersLabel => 'إعادة ضبط التصفية';

  @override
  String get pressBackAgainToExit => 'اضغط رجوع مرة أخرى للخروج من التطبيق';

  @override
  String toothTreatmentsTitle(int toothNumber) {
    return 'العلاجات للسن $toothNumber';
  }

  @override
  String get noTreatmentsPlannedForTooth =>
      'لا توجد علاجات مجدولة لهذا السن حالياً.';

  @override
  String get suggestedTreatmentsTitle => 'الإجراءات المقترحة';

  @override
  String get addTreatmentForTooth => 'إضافة علاج مخطط لهذا السن';

  @override
  String get scheduleAppointmentForTooth => 'حجز موعد';

  @override
  String get scheduleThisProcedure => 'حجز موعد للإجراء';

  @override
  String get procedureAddedToPlan => 'تمت إضافة الإجراء إلى خطة العلاج بنجاح.';

  @override
  String get selectProcedureToAdd => 'اختر إجراء من قائمة العيادة';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get quickNewAppointment => 'حجز موعد سريع';

  @override
  String get quickNewPatient => 'إضافة مريض جديد';

  @override
  String get inChairPatient => 'المريض في الكرسي الآن';

  @override
  String get nextPatient => 'المريض القادم اليوم';

  @override
  String get openClinicalSession => 'فتح الجلسة السريرية';

  @override
  String get jawViewAll => 'كلا الفكين';

  @override
  String get jawViewUpper => 'الفك العلوي';

  @override
  String get jawViewLower => 'الفك السفلي';

  @override
  String get callPatient => 'الاتصال بالمريض';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterScheduled => 'مجدول';

  @override
  String get filterConfirmed => 'مؤكد';

  @override
  String get filterInProgress => 'قيد العلاج';

  @override
  String get filterCompleted => 'مكتمل';

  @override
  String get quickToothActions => 'إجراءات السن السريعة';

  @override
  String get beforeAfterGalleryTitle => 'معرض الصور قبل وبعد العلاج';

  @override
  String get beforeLabel => 'قبل';

  @override
  String get afterLabel => 'بعد';

  @override
  String get selectBeforePhoto => 'اختر صورة قبل';

  @override
  String get selectAfterPhoto => 'اختر صورة بعد';

  @override
  String get selectPhotosToCompare => 'اختر صورتين لمقارنة نتائج العلاج.';

  @override
  String get analyticsAndReportsTitle => 'التحليلات والتقارير';

  @override
  String get exportDataLabel => 'تصدير البيانات (CSV)';

  @override
  String get exportPatientsLabel => 'تصدير المرضى';

  @override
  String get exportAppointmentsLabel => 'تصدير المواعيد';

  @override
  String get exportInvoicesLabel => 'تصدير الفواتير';

  @override
  String get copyToClipboard => 'نسخ CSV';

  @override
  String get csvCopiedSuccess => 'تم نسخ بيانات CSV إلى الحافظة بنجاح.';

  @override
  String get attendanceRate => 'معدل حضور المواعيد';

  @override
  String get financialSummaryTitle => 'الملخص المالي';

  @override
  String get topProceduresTitle => 'أكثر الإجراءات الطبية طلباً';

  @override
  String get exportCenterTitle => 'مركز تصدير البيانات';

  @override
  String get patientAppointmentsTimelineTitle => 'جدول مواعيد المريض';

  @override
  String get treatmentProceduresTab => 'إجراءات العلاج';

  @override
  String patientAppointmentsTab(int count) {
    return 'المواعيد ($count)';
  }

  @override
  String get upcomingAppointmentsSection => 'المواعيد القادمة';

  @override
  String get pastAppointmentsSection => 'المواعيد السابقة';

  @override
  String get noAppointmentsForPatient =>
      'لا توجد أي مواعيد مسجلة لهذا المريض حتى الآن.';

  @override
  String get viewTreatmentPlanLabel => 'عرض خطة العلاج';
}
