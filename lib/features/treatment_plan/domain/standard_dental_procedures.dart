import '../../../core/value/money.dart';
import 'treatment_plan_models.dart';

class StandardDentalProcedureTemplate {
  const StandardDentalProcedureTemplate({
    required this.nameEn,
    required this.nameAr,
    required this.nameRu,
    required this.categoryEn,
    required this.categoryAr,
    required this.categoryRu,
    required this.defaultPrice,
    required this.durationMinutes,
  });

  final String nameEn;
  final String nameAr;
  final String nameRu;
  final String categoryEn;
  final String categoryAr;
  final String categoryRu;
  final Money defaultPrice;
  final int durationMinutes;

  ProcedureDraft toDraft(String languageCode) {
    final isAr = languageCode.startsWith('ar');
    final isRu = languageCode.startsWith('ru');
    return ProcedureDraft(
      name: isAr ? nameAr : (isRu ? nameRu : nameEn),
      category: isAr ? categoryAr : (isRu ? categoryRu : categoryEn),
      defaultPrice: defaultPrice,
      durationMinutes: durationMinutes,
    );
  }
}

abstract final class StandardDentalProcedures {
  static const List<StandardDentalProcedureTemplate> defaults = [
    // Diagnostic & Preventive
    StandardDentalProcedureTemplate(
      nameEn: 'Comprehensive Dental Examination',
      nameAr: 'فحص واستشارة أسنان شاملة',
      nameRu: 'Первичный осмотр и консультация',
      categoryEn: 'Preventive',
      categoryAr: 'وقائية وفحص',
      categoryRu: 'Профилактика и диагностика',
      defaultPrice: Money.fromMinorUnits(3000),
      durationMinutes: 30,
    ),
    StandardDentalProcedureTemplate(
      nameEn: 'Scaling & Polishing',
      nameAr: 'تنظيف وتلميع الأسنان (إزالة الجير)',
      nameRu: 'Профессиональная гигиена и чистка',
      categoryEn: 'Preventive',
      categoryAr: 'وقائية وفحص',
      categoryRu: 'Профилактика и диагностика',
      defaultPrice: Money.fromMinorUnits(5000),
      durationMinutes: 45,
    ),
    StandardDentalProcedureTemplate(
      nameEn: 'Dental X-Ray (Periapical/Bitewing)',
      nameAr: 'أشعة سينية سنية تشخيصية',
      nameRu: 'Прицельный рентгеновский снимок',
      categoryEn: 'Preventive',
      categoryAr: 'وقائية وفحص',
      categoryRu: 'Профилактика и диагностика',
      defaultPrice: Money.fromMinorUnits(1500),
      durationMinutes: 15,
    ),
    StandardDentalProcedureTemplate(
      nameEn: 'Topical Fluoride Application',
      nameAr: 'تطبيق الفلورايد الموضعي الوقائي',
      nameRu: 'Фторирование зубов',
      categoryEn: 'Preventive',
      categoryAr: 'وقائية وفحص',
      categoryRu: 'Профилактика и диагностика',
      defaultPrice: Money.fromMinorUnits(2500),
      durationMinutes: 20,
    ),

    // Restorative
    StandardDentalProcedureTemplate(
      nameEn: 'Composite Filling (Anterior)',
      nameAr: 'حشوة تجميلية كمبوزيت (أسنان أمامية)',
      nameRu: 'Композитная реставрация (передние зубы)',
      categoryEn: 'Restorative',
      categoryAr: 'ترميم وحشوات',
      categoryRu: 'Терапия и реставрация',
      defaultPrice: Money.fromMinorUnits(6000),
      durationMinutes: 45,
    ),
    StandardDentalProcedureTemplate(
      nameEn: 'Composite Filling (Posterior)',
      nameAr: 'حشوة كمبوزيت ضوئية (أضراس خلفية)',
      nameRu: 'Композитная пломба (жевательные зубы)',
      categoryEn: 'Restorative',
      categoryAr: 'ترميم وحشوات',
      categoryRu: 'Терапия и реставрация',
      defaultPrice: Money.fromMinorUnits(7000),
      durationMinutes: 45,
    ),
    StandardDentalProcedureTemplate(
      nameEn: 'Temporary Filling / Sedative Dressing',
      nameAr: 'حشوة مؤقتة وتهدئة العصب',
      nameRu: 'Временная пломба',
      categoryEn: 'Restorative',
      categoryAr: 'ترميم وحشوات',
      categoryRu: 'Терапия и реставрация',
      defaultPrice: Money.fromMinorUnits(2000),
      durationMinutes: 20,
    ),

    // Endodontics
    StandardDentalProcedureTemplate(
      nameEn: 'Root Canal Treatment (Anterior)',
      nameAr: 'علاج عصب وجذور (سن أمامي)',
      nameRu: 'Эндодонтическое лечение (передний зуб)',
      categoryEn: 'Endodontics',
      categoryAr: 'علاج الجذور والأعصاب',
      categoryRu: 'Эндодонтия',
      defaultPrice: Money.fromMinorUnits(12000),
      durationMinutes: 60,
    ),
    StandardDentalProcedureTemplate(
      nameEn: 'Root Canal Treatment (Molar)',
      nameAr: 'علاج عصب وجذور (ضرس خلفي)',
      nameRu: 'Эндодонтическое лечение (моляр)',
      categoryEn: 'Endodontics',
      categoryAr: 'علاج الجذور والأعصاب',
      categoryRu: 'Эндодонтия',
      defaultPrice: Money.fromMinorUnits(18000),
      durationMinutes: 90,
    ),
    StandardDentalProcedureTemplate(
      nameEn: 'Pulpotomy / Emergency Pain Relief',
      nameAr: 'بتر اللب وتسكين الألم الإسعافي',
      nameRu: 'Неотложная помощь при пульпите',
      categoryEn: 'Endodontics',
      categoryAr: 'علاج الجذور والأعصاب',
      categoryRu: 'Эндодонтия',
      defaultPrice: Money.fromMinorUnits(4500),
      durationMinutes: 30,
    ),

    // Prosthodontics
    StandardDentalProcedureTemplate(
      nameEn: 'Zirconia / Porcelain Crown',
      nameAr: 'تاج زيركون أو بورسلين',
      nameRu: 'Коронка из диоксида циркония / керамики',
      categoryEn: 'Prosthodontics',
      categoryAr: 'تركيبات وتعويضات',
      categoryRu: 'Ортопедия и протезирование',
      defaultPrice: Money.fromMinorUnits(25000),
      durationMinutes: 60,
    ),
    StandardDentalProcedureTemplate(
      nameEn: 'Post & Core Build-Up',
      nameAr: 'بناء دعامة سنية (وتد وبناء)',
      nameRu: 'Культевая вкладка / штифт',
      categoryEn: 'Prosthodontics',
      categoryAr: 'تركيبات وتعويضات',
      categoryRu: 'Ортопедия и протезирование',
      defaultPrice: Money.fromMinorUnits(8000),
      durationMinutes: 45,
    ),

    // Oral Surgery
    StandardDentalProcedureTemplate(
      nameEn: 'Simple Tooth Extraction',
      nameAr: 'خلع سن بسيط',
      nameRu: 'Простое удаление зуба',
      categoryEn: 'Oral Surgery',
      categoryAr: 'جراحة الفم والخلع',
      categoryRu: 'Хирургия',
      defaultPrice: Money.fromMinorUnits(4000),
      durationMinutes: 30,
    ),
    StandardDentalProcedureTemplate(
      nameEn: 'Surgical / Impacted Tooth Extraction',
      nameAr: 'خلع جراحي لسن منطمر',
      nameRu: 'Сложное / хирургическое удаление зуба',
      categoryEn: 'Oral Surgery',
      categoryAr: 'جراحة الفم والخلع',
      categoryRu: 'Хирургия',
      defaultPrice: Money.fromMinorUnits(12000),
      durationMinutes: 60,
    ),
    StandardDentalProcedureTemplate(
      nameEn: 'Abscess Incision & Drainage',
      nameAr: 'شق وتصريف خراج سني',
      nameRu: 'Вскрытие и дренирование абсцесса',
      categoryEn: 'Oral Surgery',
      categoryAr: 'جراحة الفم والخلع',
      categoryRu: 'Хيрургия',
      defaultPrice: Money.fromMinorUnits(3500),
      durationMinutes: 30,
    ),

    // Periodontics
    StandardDentalProcedureTemplate(
      nameEn: 'Deep Scaling & Root Planing (per quadrant)',
      nameAr: 'تقليح عميق وتسوية الجذور (لكل ربع)',
      nameRu: 'Кюретаж пародонтальных карманов',
      categoryEn: 'Periodontics',
      categoryAr: 'علاج اللثة',
      categoryRu: 'Пародонтология',
      defaultPrice: Money.fromMinorUnits(6500),
      durationMinutes: 45,
    ),

    // Cosmetic
    StandardDentalProcedureTemplate(
      nameEn: 'In-Office Teeth Whitening',
      nameAr: 'تبييض الأسنان بالعيادة',
      nameRu: 'Кабинетное отбеливание зубов',
      categoryEn: 'Cosmetic',
      categoryAr: 'تجميل الأسنان',
      categoryRu: 'Эстетическая стоматология',
      defaultPrice: Money.fromMinorUnits(20000),
      durationMinutes: 60,
    ),
  ];

  static List<ProcedureDraft> draftsForLocale(String languageCode) =>
      defaults.map((t) => t.toDraft(languageCode)).toList(growable: false);
}
