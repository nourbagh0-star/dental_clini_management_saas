// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get createStaffAccountLabel => 'Создать аккаунт сотрудника';

  @override
  String get createStaffAccountHelp =>
      'Введите почту сотрудника и временный пароль (15–128 символов). Передайте данные лично. До доступа к клинике сотрудник должен сменить пароль. Письмо не отправляется.';

  @override
  String get temporaryPasswordLabel => 'Временный пароль';

  @override
  String get staffAccountCreated =>
      'Аккаунт сотрудника создан. Передайте данные лично. При первом входе нужно сменить пароль.';

  @override
  String get staffAccountUnavailable =>
      'Не удалось создать аккаунт. Почта может быть уже зарегистрирована или создание временно недоступно. Существующие аккаунты не изменены.';

  @override
  String get initialPasswordTitle => 'Установите свой пароль';

  @override
  String get initialPasswordHelp =>
      'Замените временный пароль другим паролем длиной не менее 15 символов. Доступ к клинике заблокирован до завершения. Затем войдите с новым паролем.';

  @override
  String get emailConfirmed => 'Почта подтверждена. Войдите, чтобы продолжить.';

  @override
  String get invalidConfirmationLink =>
      'Ссылка недействительна или устарела. Войдите, чтобы запросить новую ссылку.';

  @override
  String get confirmationLinkSent =>
      'Откройте ссылку подтверждения в письме, затем вернитесь для входа. Повторная отправка — не раньше чем через 60 секунд.';

  @override
  String get resendLinkLabel => 'Отправить ссылку повторно';

  @override
  String get appTitle => 'DentaFlow';

  @override
  String get demoLabel => 'ДЕМОНСТРАЦИОННАЯ ВЕРСИЯ';

  @override
  String get welcomeTitle => 'Ваша клиника — в порядке.';

  @override
  String get welcomeBody =>
      'Общее рабочее пространство стоматологической клиники. Запись на приём и работа с пациентами появятся на следующих этапах разработки.';

  @override
  String get demoNotice =>
      'Только вымышленные данные. Эта версия не предназначена для реальных медицинских записей.';

  @override
  String get appearanceTitle => 'Настройте под себя';

  @override
  String get themeLabel => 'Оформление';

  @override
  String get languageLabel => 'Язык';

  @override
  String get systemLabel => 'Как на устройстве';

  @override
  String get lightLabel => 'Светлое';

  @override
  String get darkLabel => 'Тёмное';

  @override
  String get englishLabel => 'English';

  @override
  String get russianLabel => 'Русский';

  @override
  String get arabicLabel => 'العربية';

  @override
  String get storageWarning =>
      'Не удалось сохранить или восстановить настройки. Вы можете продолжить работу с демоверсией.';

  @override
  String get notFoundTitle => 'Страница недоступна';

  @override
  String get notFoundBody => 'Эта страница недоступна в текущей демоверсии.';

  @override
  String get backHome => 'Вернуться на главную';

  @override
  String get startupTitle => 'Не удалось открыть приложение';

  @override
  String get startupBody =>
      'Не удалось запустить приложение. Проверьте настройки среды разработки и повторите попытку.';

  @override
  String get configurationBody =>
      'Настройки среды разработки некорректны. Проверьте среду и публичные параметры подключения. Рабочая среда ещё не включена.';

  @override
  String get retryLabel => 'Повторить';

  @override
  String get networkFailure => 'Нет соединения. Повторите попытку.';

  @override
  String get authenticationFailure => 'Войдите снова, чтобы продолжить.';

  @override
  String get authorizationFailure => 'У вас нет прав на это действие.';

  @override
  String get validationFailure => 'Проверьте данные и повторите попытку.';

  @override
  String get serverFailure => 'Сервис временно недоступен. Повторите попытку.';

  @override
  String get notFoundFailure => 'Запрошенная запись недоступна.';

  @override
  String get unknownFailure => 'Произошла ошибка. Повторите попытку.';

  @override
  String get loginTitle => 'Вход';

  @override
  String get registerTitle => 'Создание аккаунта';

  @override
  String get emailLabel => 'Электронная почта';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get confirmPasswordLabel => 'Повторите пароль';

  @override
  String get signInLabel => 'Войти';

  @override
  String get registerLabel => 'Создать аккаунт';

  @override
  String get forgotLabel => 'Забыли пароль?';

  @override
  String get verifyTitle => 'Подтвердите почту';

  @override
  String get codeLabel => 'Код подтверждения';

  @override
  String get verifyLabel => 'Подтвердить код';

  @override
  String get resendLabel => 'Отправить код повторно';

  @override
  String get changeEmailLabel => 'Изменить почту';

  @override
  String get forgotTitle => 'Восстановление доступа';

  @override
  String get sendCodeLabel => 'Отправить код восстановления';

  @override
  String get sendResetLinkLabel => 'Отправить ссылку для сброса';

  @override
  String get recoveryLinkSent =>
      'Если аккаунт существует, откройте ссылку из письма, чтобы установить новый пароль.';

  @override
  String get resetTitle => 'Сброс пароля';

  @override
  String get resetLabel => 'Сохранить новый пароль';

  @override
  String get lockedTitle => 'Рабочее пространство заблокировано';

  @override
  String get lockedBody => 'Введите пароль, чтобы разблокировать аккаунт.';

  @override
  String get unlockLabel => 'Разблокировать';

  @override
  String get switchAccountLabel => 'Сменить аккаунт';

  @override
  String get accountTitle => 'Ваш аккаунт готов';

  @override
  String get accountBody =>
      'Настройка клиники появится на следующем этапе. У вашего аккаунта пока нет роли в клинике.';

  @override
  String get lockLabel => 'Заблокировать';

  @override
  String get logoutLabel => 'Выйти';

  @override
  String get backLoginLabel => 'Вернуться ко входу';

  @override
  String get passwordHelp =>
      'Используйте не менее 15 символов. Можно использовать пробелы и менеджер паролей.';

  @override
  String get emailInvalid => 'Введите корректный адрес почты.';

  @override
  String get requiredField => 'Обязательное поле.';

  @override
  String get passwordShort => 'Используйте не менее 15 символов.';

  @override
  String get passwordMismatch => 'Пароли должны совпадать.';

  @override
  String get invalidCodeInput => 'Введите шестизначный код из письма.';

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get hidePassword => 'Скрыть пароль';

  @override
  String get authCredentials =>
      'Не удалось проверить данные для входа. Попробуйте ещё раз.';

  @override
  String get authUnconfirmed => 'Подтвердите почту перед входом.';

  @override
  String get authInvalidCode => 'Код неверен или истёк. Запросите новый.';

  @override
  String get authWeakPassword => 'Пароль не соответствует требованиям сервера.';

  @override
  String get authRateLimited => 'Слишком много попыток. Подождите и повторите.';

  @override
  String get authStorage =>
      'Хранилище сессии недоступно. Доступ заблокирован; проверьте настройки браузера или устройства.';

  @override
  String get authUnavailable =>
      'Вход не настроен. Откройте настроенную сборку для разработки.';

  @override
  String get authRevocation =>
      'Вы вышли на этом устройстве. Отзыв сессии на сервере не подтверждён.';

  @override
  String get authResetPartial =>
      'Пароль изменён, но отзыв всех сессий не подтверждён. Войдите снова; другие сессии могут оставаться активными.';

  @override
  String get authResetDone => 'Пароль изменён. Войдите снова.';

  @override
  String get authCodeSent =>
      'Если адрес подходит, код отправлен. Проверьте почту. Код действует один час; повторная отправка — не раньше чем через 60 секунд.';

  @override
  String get restoringTitle => 'Проверка сессии';

  @override
  String get restoreFailedTitle => 'Не удалось восстановить сессию';

  @override
  String get privacyHidden => 'Рабочее пространство скрыто';

  @override
  String get authSettings => 'Оформление и язык';

  @override
  String get continueAuth => 'Войти или создать аккаунт';

  @override
  String get clinicSetupTitle => 'Настройте клинику';

  @override
  String get clinicSetupBody =>
      'Создайте первую клинику, чтобы начать работу в DentaFlow. Позже можно добавить ещё клиники.';

  @override
  String get createClinicLabel => 'Создать клинику';

  @override
  String get clinicNameLabel => 'Название клиники';

  @override
  String get clinicNameHelp =>
      'Укажите название, которое знают сотрудники и пациенты.';

  @override
  String get currencyLabel => 'Валюта';

  @override
  String get timeZoneLabel => 'Часовой пояс';

  @override
  String get timeZoneHelp =>
      'Подставлен с этого устройства. Измените, если клиника работает в другом часовом поясе.';

  @override
  String get selectClinicTitle => 'Выберите клинику';

  @override
  String get selectClinicBody =>
      'Выберите клинику, в которой хотите работать. Позже можно переключаться между клиниками.';

  @override
  String get currentClinicTitle => 'Клиника выбрана';

  @override
  String currentClinicBody(Object clinicName) {
    return 'Активная клиника: $clinicName. Выберите раздел ниже или перейдите на панель управления.';
  }

  @override
  String get switchClinicLabel => 'Сменить клинику';

  @override
  String get addClinicLabel => 'Добавить клинику';

  @override
  String get clinicLoadTitle => 'Загружаем ваши клиники';

  @override
  String get clinicLoadFailed =>
      'Не удалось загрузить клиники. Попробуйте ещё раз.';

  @override
  String get timeZoneUtc => 'UTC';

  @override
  String get visitsTitle => 'Визиты';

  @override
  String get newSessionLabel => 'Новая сессия';

  @override
  String get noVisitsMessage => 'Клинических визитов пока нет.';

  @override
  String get clinicalViewOnly =>
      'Клинические сессии доступны только для просмотра.';

  @override
  String get linkedAppointmentLabel => 'Связанный приём';

  @override
  String get walkInLabel => 'Визит без записи';

  @override
  String get draftStatus => 'Черновик';

  @override
  String get finalizedStatus => 'Завершено';

  @override
  String get enteredInErrorStatus => 'Ошибочная запись';

  @override
  String get clinicalNotesLabel => 'Клинические заметки';

  @override
  String get recommendationsLabel => 'Рекомендации';

  @override
  String get saveDraftLabel => 'Сохранить черновик';

  @override
  String get finalizeSessionLabel => 'Завершить сессию';

  @override
  String get markInErrorLabel => 'Отметить как ошибочную';

  @override
  String get addAmendmentLabel => 'Добавить исправление';

  @override
  String get amendmentsTitle => 'Исправления';

  @override
  String get amendmentTextLabel => 'Исправление';

  @override
  String get reasonLabel => 'Причина';

  @override
  String get selectVisitTypeTitle => 'Создать клиническую сессию';

  @override
  String get chooseAppointmentLabel => 'Выберите приём';

  @override
  String get chooseDentistLabel => 'Выберите стоматолога';

  @override
  String get visitDateTimeLabel => 'Дата и время визита';

  @override
  String get createDraftLabel => 'Создать черновик';

  @override
  String get cancelLabel => 'Отмена';

  @override
  String get loadMoreLabel => 'Загрузить ещё';

  @override
  String get reloadLatestLabel => 'Загрузить последнюю версию';

  @override
  String get revisionConflictMessage =>
      'Другой сотрудник сохранил этот черновик. Загрузите последнюю версию перед продолжением.';

  @override
  String get sessionUnavailableMessage => 'Эта клиническая сессия недоступна.';

  @override
  String get clinicalActionFailedMessage =>
      'Не удалось выполнить клиническое действие. Проверьте сессию и повторите попытку.';

  @override
  String get finalizeWarning =>
      'После завершения исходную клиническую запись нельзя редактировать. Исправления добавляются как подписанные дополнения.';

  @override
  String get originalRecordTitle => 'Исходная клиническая запись';

  @override
  String get appointmentSessionLabel => 'Визит по записи';

  @override
  String get sessionDateLabel => 'Дата сессии';

  @override
  String get assignedDentistLabel => 'Назначенный стоматолог';

  @override
  String get lastSavedLabel => 'Последнее сохранение';

  @override
  String get openClinicalSessionLabel => 'Открыть клиническую сессию';

  @override
  String get patientFilesTitle => 'Файлы пациента';

  @override
  String get uploadFileLabel => 'Загрузить файл';

  @override
  String get noPatientFilesMessage => 'У пациента пока нет файлов.';

  @override
  String get patientFilesViewOnly =>
      'Файлы пациента доступны только для просмотра.';

  @override
  String get includeArchivedFilesLabel => 'Показать архивные файлы';

  @override
  String get allFileCategoriesLabel => 'Все категории';

  @override
  String get fileCategoryLabel => 'Категория';

  @override
  String get fileCategoryXray => 'Рентген';

  @override
  String get fileCategoryClinicalPhoto => 'Клиническое фото';

  @override
  String get fileCategoryConsent => 'Согласие';

  @override
  String get fileCategoryReferral => 'Направление';

  @override
  String get fileCategoryLaboratory => 'Результат анализа';

  @override
  String get fileCategoryOther => 'Другое';

  @override
  String get fileDescriptionLabel => 'Описание (необязательно)';

  @override
  String get chooseFileLabel => 'Выбрать JPG, PNG или PDF';

  @override
  String get fileTypeHelp => 'Не более 15 МБ. Только демонстрационные файлы.';

  @override
  String get fileSelectionInvalid =>
      'Выберите корректный файл JPG, PNG или PDF размером до 15 МБ.';

  @override
  String get uploadingFileLabel => 'Загрузка файла';

  @override
  String get validatingFileLabel => 'Безопасная проверка файла…';

  @override
  String get cancelUploadLabel => 'Отменить загрузку';

  @override
  String get openFileLabel => 'Открыть файл';

  @override
  String get openPdfLabel => 'Открыть PDF';

  @override
  String get archiveFileLabel => 'Архивировать файл';

  @override
  String get restoreFileLabel => 'Восстановить файл';

  @override
  String get uploadReplacementLabel => 'Загрузить замену';

  @override
  String get archiveFileWarning =>
      'Файл останется в хранилище и журнале. Укажите причину архивации.';

  @override
  String get archivedFileLabel => 'В архиве';

  @override
  String get fileUnavailableMessage => 'Этот файл пациента недоступен.';

  @override
  String get fileActionFailedMessage =>
      'Не удалось выполнить действие с файлом. Проверьте файл и повторите попытку.';

  @override
  String get fileSizeLabel => 'Размер';

  @override
  String get uploadedAtLabel => 'Загружен';

  @override
  String get fileLinkedVisitLabel => 'Связанный визит';

  @override
  String get patientFilesRestricted =>
      'Файлы пациента доступны только уполномоченному клиническому персоналу.';

  @override
  String get billingTitle => 'Счета и платежи';

  @override
  String get newInvoiceLabel => 'Новый счёт';

  @override
  String get noInvoicesMessage => 'Счетов пока нет.';

  @override
  String get billingRestricted =>
      'Раздел доступен уполномоченному клиническому и финансовому персоналу.';

  @override
  String get invoiceDraftLabel => 'Черновик счёта';

  @override
  String get invoiceItemsTitle => 'Позиции счёта';

  @override
  String get noInvoiceItemsMessage => 'Процедуры ещё не добавлены.';

  @override
  String get addCatalogueItemLabel => 'Добавить из каталога';

  @override
  String get addTreatmentItemLabel => 'Добавить из плана лечения';

  @override
  String get quantityLabel => 'Количество';

  @override
  String get approveContentLabel => 'Утвердить клинический состав';

  @override
  String get reopenContentLabel => 'Открыть клинический состав';

  @override
  String get financialDetailsTitle => 'Финансовые данные';

  @override
  String get unitPriceLabel => 'Цена за единицу';

  @override
  String get discountTypeLabel => 'Тип скидки';

  @override
  String get discountNoneLabel => 'Без скидки';

  @override
  String get discountFixedLabel => 'Фиксированная сумма';

  @override
  String get discountPercentageLabel => 'Процент';

  @override
  String get discountValueLabel => 'Размер скидки';

  @override
  String get taxRateLabel => 'Ставка налога (%)';

  @override
  String get invoiceLanguageLabel => 'Язык счёта';

  @override
  String get languageEnglishLabel => 'Английский';

  @override
  String get languageRussianLabel => 'Русский';

  @override
  String get languageArabicLabel => 'Арабский';

  @override
  String get saveFinancialsLabel => 'Сохранить финансовые данные';

  @override
  String get finalizeInvoiceLabel => 'Провести счёт';

  @override
  String get finalizeInvoiceWarning =>
      'После проведения счёт получит постоянный номер. Позиции и цены больше нельзя будет изменить.';

  @override
  String get cancelInvoiceLabel => 'Отменить счёт';

  @override
  String get recordPaymentLabel => 'Принять платёж';

  @override
  String get paymentAmountLabel => 'Полученная сумма';

  @override
  String get paymentMethodLabel => 'Способ оплаты';

  @override
  String get paymentCashLabel => 'Наличные';

  @override
  String get paymentCardLabel => 'Карта';

  @override
  String get paymentBankLabel => 'Банковский перевод';

  @override
  String get paymentOtherLabel => 'Другое';

  @override
  String get referenceLabel => 'Примечание (необязательно)';

  @override
  String get patientCreditLabel => 'Кредит пациента';

  @override
  String get applyCreditLabel => 'Использовать кредит';

  @override
  String get paymentHistoryTitle => 'Платежи и исправления';

  @override
  String get refundLabel => 'Возврат';

  @override
  String get correctionLabel => 'Исправление';

  @override
  String get exportInvoiceLabel => 'Открыть PDF счёта';

  @override
  String get invoiceSubtotalLabel => 'Подытог';

  @override
  String get invoiceDiscountLabel => 'Скидка';

  @override
  String get invoiceTaxLabel => 'Налог';

  @override
  String get invoiceTotalLabel => 'Итого';

  @override
  String get invoicePaidLabel => 'Оплачено';

  @override
  String get invoiceDueLabel => 'К оплате';

  @override
  String get paymentUnpaidLabel => 'Не оплачен';

  @override
  String get paymentPartialLabel => 'Частично оплачен';

  @override
  String get paymentPaidLabel => 'Оплачен';

  @override
  String get invoiceCancelledLabel => 'Отменён';

  @override
  String get billingActionFailedMessage =>
      'Не удалось выполнить операцию. Обновите счёт и повторите попытку.';

  @override
  String get billingConflictMessage =>
      'Счёт изменился или операция больше недоступна. Обновите данные и повторите попытку.';

  @override
  String get invoicePdfUnavailableMessage =>
      'Не удалось подготовить PDF счёта. Повторите попытку.';

  @override
  String get dashboardTitle => 'Панель клиники';

  @override
  String get dashboardActivePatients => 'Активные пациенты';

  @override
  String get dashboardAppointmentsThisWeek => 'Приёмы на этой неделе';

  @override
  String get dashboardCompletedThisMonth => 'Лечения завершены в этом месяце';

  @override
  String get dashboardOutstandingPayments => 'Неоплаченные суммы';

  @override
  String dashboardOutstandingInvoices(int count) {
    return 'Неоплаченных счетов: $count';
  }

  @override
  String get dashboardTodayAppointments => 'Приёмы сегодня';

  @override
  String get dashboardUpcomingAppointments => 'Ближайшие приёмы';

  @override
  String get dashboardNextSevenDays => 'Следующие семь дней';

  @override
  String get dashboardNoTodayAppointments => 'На сегодня приёмов нет.';

  @override
  String get dashboardNoUpcomingAppointments =>
      'На ближайшие семь дней приёмов нет.';

  @override
  String get dashboardViewAllAppointments => 'Все приёмы';

  @override
  String dashboardLastUpdated(String value) {
    return 'Обновлено: $value';
  }

  @override
  String dashboardTimeZone(String value) {
    return 'Время клиники · $value';
  }

  @override
  String get dashboardRefresh => 'Обновить панель';

  @override
  String get dashboardRefreshFailed =>
      'Не удалось получить свежие данные. Показан предыдущий результат.';

  @override
  String get dashboardUnavailable => 'Панель клиники временно недоступна.';

  @override
  String get dashboardNoActiveClinic =>
      'Выберите активную клинику, чтобы открыть её панель.';

  @override
  String get dashboardOpenPatients => 'Открыть пациентов';

  @override
  String get dashboardOpenTreatments => 'Открыть лечения';

  @override
  String get dashboardOpenBilling => 'Открыть счета';

  @override
  String get appointmentStatusScheduled => 'Запланирован';

  @override
  String get appointmentStatusConfirmed => 'Подтверждён';

  @override
  String get appointmentStatusInProgress => 'Идёт';

  @override
  String get appointmentStatusCompleted => 'Завершён';

  @override
  String get appointmentStatusNoShow => 'Неявка';

  @override
  String get appointmentStatusCancelled => 'Отменён';

  @override
  String get auditTitle => 'Журнал аудита';

  @override
  String get auditOpen => 'Открыть журнал аудита';

  @override
  String get auditRefresh => 'Обновить журнал';

  @override
  String get auditUnavailable => 'Журнал аудита временно недоступен.';

  @override
  String get auditOwnerOnly =>
      'Журнал аудита доступен только активному владельцу клиники.';

  @override
  String get auditNoEvents => 'В этом диапазоне нет записанных действий.';

  @override
  String get auditNoFilterResults => 'Нет действий, соответствующих фильтрам.';

  @override
  String get auditFilters => 'Фильтры';

  @override
  String get auditClearFilters => 'Сбросить фильтры';

  @override
  String get auditDateRange => 'Диапазон дат';

  @override
  String get auditEmployee => 'Сотрудник';

  @override
  String get auditAllEmployees => 'Все сотрудники';

  @override
  String get auditCategory => 'Категория';

  @override
  String get auditAllCategories => 'Все категории';

  @override
  String get auditEntityType => 'Тип объекта';

  @override
  String get auditAllEntities => 'Все объекты';

  @override
  String get auditLoadMore => 'Загрузить ещё';

  @override
  String get auditDetails => 'Сведения о событии';

  @override
  String get auditOccurredAt => 'Время';

  @override
  String get auditAction => 'Действие';

  @override
  String get auditEntity => 'Объект';

  @override
  String get auditReason => 'Причина';

  @override
  String get auditNoReason => 'Причина не указана';

  @override
  String get auditActorRoles => 'Роли на тот момент';

  @override
  String get auditFormerActor => 'Бывший или недоступный сотрудник';

  @override
  String get auditCategoryAccess => 'Доступ';

  @override
  String get auditCategoryPatient => 'Управление пациентами';

  @override
  String get auditCategoryScheduling => 'Расписание';

  @override
  String get auditCategoryClinical => 'Клинические действия';

  @override
  String get auditCategoryFinancial => 'Финансы';

  @override
  String get auditCategoryStaff => 'Персонал и безопасность';

  @override
  String get auditOtherAction => 'Другое записанное действие';

  @override
  String get auditOpenRecord => 'Открыть связанную запись';

  @override
  String auditShowingRange(String from, String to, String timeZone) {
    return '$from – $to · $timeZone';
  }

  @override
  String get auditRefreshFailed =>
      'Не удалось загрузить свежие события. Показан предыдущий результат.';

  @override
  String get auditActionAccess => 'Зафиксирован доступ к данным';

  @override
  String get auditActionPatient => 'Изменены административные данные пациента';

  @override
  String get auditActionScheduling => 'Изменено расписание или приём';

  @override
  String get auditActionClinical => 'Изменена клиническая запись';

  @override
  String get auditActionFinancial => 'Изменена финансовая запись';

  @override
  String get auditActionStaff => 'Изменены сотрудники или безопасность';

  @override
  String get roleOwner => 'Владелец';

  @override
  String get roleDentist => 'Стоматолог';

  @override
  String get roleAssistant => 'Ассистент';

  @override
  String get roleReceptionist => 'Администратор';

  @override
  String get auditResultCount => 'Количество результатов';

  @override
  String get auditApplyFilters => 'Применить фильтры';

  @override
  String appointmentsWithTimeZone(String timeZone) {
    return 'Приёмы · $timeZone';
  }

  @override
  String get previousWeekLabel => 'Предыдущая неделя';

  @override
  String get nextWeekLabel => 'Следующая неделя';

  @override
  String get newAppointmentLabel => 'Новый приём';

  @override
  String get noAppointmentsWeek => 'На этой неделе приёмов нет.';

  @override
  String get chooseClinicFirst => 'Сначала выберите клинику.';

  @override
  String clinicTimeZoneValue(String timeZone) {
    return 'Часовой пояс клиники: $timeZone';
  }

  @override
  String get findPatientLabel =>
      'Найти пациента по имени, телефону, почте или номеру';

  @override
  String patientSelectedValue(String patientId) {
    return 'Выбран пациент: $patientId';
  }

  @override
  String get dentistLabel => 'Стоматолог';

  @override
  String get chooseDentistValidation => 'Выберите стоматолога';

  @override
  String get dateLabel => 'Дата';

  @override
  String get startTimeLabel => 'Время начала';

  @override
  String get durationLabel => 'Длительность';

  @override
  String minutesValue(int minutes) {
    return '$minutes мин.';
  }

  @override
  String get appointmentPurposeOptional =>
      'Цель (необязательно, без клинических данных)';

  @override
  String get ownerOverrideOptional =>
      'Причина исключения владельца (только при необходимости)';

  @override
  String get createAppointmentLabel => 'Создать приём';

  @override
  String get rescheduleLabel => 'Перенести';

  @override
  String get confirmLabel => 'Подтвердить';

  @override
  String get startLabel => 'Начать';

  @override
  String get completeLabel => 'Завершить';

  @override
  String get markNoShowLabel => 'Отметить неявку';

  @override
  String get preparationNoteLabel => 'Подготовительная заметка';

  @override
  String get ownerOverrideReasonTitle => 'Причина исключения владельца';

  @override
  String get overrideConflictHelp =>
      'Нужно только при конфликте нового времени';

  @override
  String get continueLabel => 'Продолжить';

  @override
  String get useReasonLabel => 'Использовать причину';

  @override
  String get operationalPreparationNoteTitle =>
      'Операционная подготовительная заметка';

  @override
  String get saveLabel => 'Сохранить';

  @override
  String get cancellationReasonTitle => 'Причина отмены';

  @override
  String get appointmentUnavailableIssue => 'Пациент или приём недоступен.';

  @override
  String get appointmentForbiddenIssue =>
      'Ваша роль не позволяет выполнить это действие с приёмом.';

  @override
  String get appointmentPatientOverlapIssue =>
      'У пациента уже есть пересекающийся приём.';

  @override
  String get appointmentDentistOverlapIssue =>
      'У стоматолога уже есть пересекающийся приём.';

  @override
  String get appointmentWorkingHoursIssue =>
      'Это время находится вне рабочего графика стоматолога.';

  @override
  String get appointmentLeaveIssue => 'В это время стоматолог в отпуске.';

  @override
  String get appointmentUnavailablePeriodIssue =>
      'В это время стоматолог недоступен.';

  @override
  String get appointmentOverrideRequiredIssue =>
      'Владелец должен указать причину обхода конфликта.';

  @override
  String get appointmentInvalidTransitionIssue =>
      'Статус приёма нельзя изменить таким образом.';

  @override
  String get patientsTitle => 'Пациенты';

  @override
  String get newPatientLabel => 'Новый пациент';

  @override
  String get searchPatientLabel => 'Поиск по имени, телефону, почте или номеру';

  @override
  String get archivedLabel => 'В архиве';

  @override
  String get patientActionUnavailable => 'Это действие с пациентом недоступно.';

  @override
  String get noPatientsFound => 'Пациенты не найдены.';

  @override
  String get noContactLabel => 'Нет контактов';

  @override
  String get firstNameLabel => 'Имя';

  @override
  String get lastNameLabel => 'Фамилия';

  @override
  String get phoneLabel => 'Телефон';

  @override
  String get birthDateInformationLabel => 'Сведения о дате рождения';

  @override
  String get birthPrecisionUnknown => 'Неизвестно';

  @override
  String get birthPrecisionExact => 'Точная';

  @override
  String get birthPrecisionApproximate => 'Приблизительная';

  @override
  String get birthDateFormatLabel => 'Дата рождения (ГГГГ-ММ-ДД)';

  @override
  String get approximateAgeLabel => 'Приблизительный возраст в годах';

  @override
  String get ageAssessedOnLabel => 'Дата оценки возраста (ГГГГ-ММ-ДД)';

  @override
  String get knownMinorLabel => 'Известно, что пациент младше 18 лет';

  @override
  String get guardianNameLabel => 'Имя опекуна';

  @override
  String get guardianPhoneLabel => 'Телефон опекуна';

  @override
  String get guardianEmailLabel => 'Почта опекуна';

  @override
  String get createPatientLabel => 'Создать пациента';

  @override
  String get patientProfileTitle => 'Профиль пациента';

  @override
  String get patientProfileUnavailable =>
      'Профиль пациента недоступен. Вернитесь к поиску и выберите пациента снова.';

  @override
  String get contactTitle => 'Контакты';

  @override
  String get medicalProfileTitle => 'Медицинский профиль';

  @override
  String get appointmentsTitle => 'Приёмы';

  @override
  String get dentalChartTitle => 'Зубная карта';

  @override
  String get treatmentPlansTitle => 'Планы лечения';

  @override
  String get restorePatientLabel => 'Восстановить пациента';

  @override
  String get archivePatientLabel => 'Архивировать пациента';

  @override
  String get birthInformationTitle => 'Сведения о рождении';

  @override
  String approximatelyYearsValue(int years) {
    return 'Приблизительно $years лет';
  }

  @override
  String get archivePatientQuestion => 'Архивировать пациента?';

  @override
  String get restorePatientQuestion => 'Восстановить пациента?';

  @override
  String get archivePatientExplanation =>
      'Пациент останется в истории клиники, и владелец сможет его восстановить.';

  @override
  String get restorePatientExplanation =>
      'Пациент вернётся в активные записи клиники.';

  @override
  String get archiveLabel => 'Архивировать';

  @override
  String get restoreLabel => 'Восстановить';

  @override
  String get medicalRoleRestricted =>
      'Медицинская информация недоступна для вашей роли.';

  @override
  String get allergiesLabel => 'Аллергии';

  @override
  String get currentMedicationsLabel => 'Текущие лекарства';

  @override
  String get chronicConditionsLabel => 'Хронические заболевания';

  @override
  String get importantMedicalNotesLabel => 'Важные медицинские заметки';

  @override
  String get saveMedicalProfileLabel => 'Сохранить медицинский профиль';

  @override
  String get staffTitle => 'Сотрудники';

  @override
  String get backLabel => 'Назад';

  @override
  String get inviteStaffLabel => 'Пригласить сотрудника';

  @override
  String get staffOwnerOnly =>
      'Управлять сотрудниками могут только владельцы клиники.';

  @override
  String get manageStaffDescription =>
      'Управляйте ролями и доступом в этой клинике.';

  @override
  String get webInvitationOnly => 'Отправляйте приглашения из веб-версии.';

  @override
  String get verifiedEmailLabel => 'Подтверждённая почта';

  @override
  String get sendInvitationLabel => 'Отправить приглашение';

  @override
  String get saveRolesLabel => 'Сохранить роли';

  @override
  String get reactivateStaffQuestion => 'Снова активировать сотрудника?';

  @override
  String get deactivateStaffQuestion => 'Деактивировать сотрудника?';

  @override
  String get reactivateLabel => 'Активировать';

  @override
  String get deactivateLabel => 'Деактивировать';

  @override
  String get confirmPasswordTitle => 'Подтвердите пароль';

  @override
  String get invalidInvitationLink =>
      'Ссылка приглашения недействительна или недоступна.';

  @override
  String get joinClinicTitle => 'Присоединиться к клинике';

  @override
  String get acceptInvitationHelp =>
      'Принимайте приглашение только после входа с адресом, на который оно было отправлено.';

  @override
  String get acceptInvitationLabel => 'Принять приглашение';

  @override
  String staffCountTitle(int count) {
    return 'Сотрудники ($count)';
  }

  @override
  String get inactiveLabel => 'Неактивен';

  @override
  String get editRolesLabel => 'Изменить роли';

  @override
  String invitationCountTitle(int count) {
    return 'Приглашения ($count)';
  }

  @override
  String get resendInvitationLabel => 'Отправить снова';

  @override
  String get revokeInvitationLabel => 'Отозвать';

  @override
  String get invitationPending => 'Ожидает';

  @override
  String get invitationAccepted => 'Принято';

  @override
  String get invitationRevoked => 'Отозвано';

  @override
  String get invitationExpired => 'Истекло';

  @override
  String get staffInvalidInputIssue => 'Проверьте данные и попробуйте снова.';

  @override
  String get ownerPasswordRequiredIssue =>
      'Подтвердите пароль, чтобы продолжить.';

  @override
  String get invitationUnavailableIssue => 'Это приглашение недоступно.';

  @override
  String get staffMemberUnavailableIssue => 'Этот сотрудник недоступен.';

  @override
  String get doctorScheduleTitle => 'Расписание врачей';

  @override
  String get scheduleChooseClinic =>
      'Выберите клинику перед просмотром расписания.';

  @override
  String clinicTimeZoneExplanation(String timeZone) {
    return 'Всё время указано в часовом поясе клиники: $timeZone.';
  }

  @override
  String get setWeeklyHoursLabel => 'Настроить часы работы';

  @override
  String get addUnavailableTimeLabel => 'Добавить отпуск или недоступное время';

  @override
  String get weeklyHoursTitle => 'Часы работы по неделям';

  @override
  String get noWeeklyHours => 'Для этого стоматолога часы работы не настроены.';

  @override
  String get unavailablePeriodsTitle => 'Отпуск и периоды недоступности';

  @override
  String get noUnavailablePeriods =>
      'Периоды отпуска или недоступности не записаны.';

  @override
  String get leaveLabel => 'Отпуск';

  @override
  String get unavailableLabel => 'Недоступен';

  @override
  String get removeLabel => 'Удалить';

  @override
  String scheduleConflictOwnerReview(int count) {
    return 'Изменение конфликтует с будущими приёмами: $count. Требуется проверка владельца.';
  }

  @override
  String get weekdayNumberHelp =>
      'Используйте 1 для понедельника и 7 для воскресенья.';

  @override
  String get workingDaysLabel => 'Рабочие дни';

  @override
  String get startTimeFormatLabel => 'Время начала (ЧЧ:ММ)';

  @override
  String get endTimeFormatLabel => 'Время окончания (ЧЧ:ММ)';

  @override
  String get breakStartOptional => 'Начало перерыва (необязательно)';

  @override
  String get breakEndOptional => 'Конец перерыва (необязательно)';

  @override
  String get effectiveFromFormatLabel => 'Действует с (ГГГГ-ММ-ДД)';

  @override
  String get addUnavailableTimeTitle => 'Добавить недоступное время';

  @override
  String get typeLabel => 'Тип';

  @override
  String get startsLabel => 'Начало';

  @override
  String get endsLabel => 'Окончание';

  @override
  String get reasonOptionalLabel => 'Причина (необязательно)';

  @override
  String effectiveFromValue(String date) {
    return 'Действует с $date';
  }

  @override
  String get noWorkingHours => 'Нет рабочих часов';

  @override
  String get breakLabel => 'перерыв';

  @override
  String get reviewAffectedAppointmentsTitle => 'Проверка затронутых приёмов';

  @override
  String affectedAppointmentsExplanation(int count) {
    return 'Изменение конфликтует с будущими приёмами: $count. Они останутся записанными и будут отмечены для ручного решения.';
  }

  @override
  String get ownerConfirmationReasonLabel => 'Причина подтверждения владельцем';

  @override
  String get cancelChangeLabel => 'Отменить изменение';

  @override
  String get confirmAndFlagLabel => 'Подтвердить и отметить';

  @override
  String get weekdayMon => 'Пн';

  @override
  String get weekdayTue => 'Вт';

  @override
  String get weekdayWed => 'Ср';

  @override
  String get weekdayThu => 'Чт';

  @override
  String get weekdayFri => 'Пт';

  @override
  String get weekdaySat => 'Сб';

  @override
  String get weekdaySun => 'Вс';

  @override
  String get scheduleEditForbiddenIssue =>
      'Вы не можете менять расписание этого стоматолога.';

  @override
  String get activeDentistRequiredIssue =>
      'Этот сотрудник не является активным стоматологом.';

  @override
  String get effectiveDateInvalidIssue => 'Выберите будущую дату клиники.';

  @override
  String get exceptionUnavailableIssue =>
      'Этот период недоступности больше не доступен.';

  @override
  String get affectedAppointmentsIssue =>
      'Изменение расписания влияет на будущие приёмы и требует проверки владельца.';

  @override
  String get scheduleSavedMessage => 'Еженедельные часы работы сохранены.';

  @override
  String get scheduleInvalidInputMessage =>
      'Проверьте рабочие дни, время, перерыв и дату начала действия.';

  @override
  String get scheduleForLabel => 'Расписание врача';

  @override
  String get scheduleActiveLabel => 'Действующее расписание';

  @override
  String get scheduleUpcomingLabel => 'Будущее расписание';

  @override
  String get scheduleHistoryLabel => 'История расписания';

  @override
  String get scheduleHistoryHelp =>
      'Предыдущие и заменённые версии рабочих часов';

  @override
  String get editWeeklyHoursLabel => 'Изменить недельное расписание';

  @override
  String get selectWorkingDaysHelp => 'Выберите дни работы стоматолога.';

  @override
  String get includeBreakLabel => 'Добавить перерыв';

  @override
  String get effectiveDateLabel => 'Дата начала действия';

  @override
  String get closedLabel => 'Выходной';

  @override
  String get scheduleSummaryLabel => 'Сводка расписания';

  @override
  String get procedureCatalogueTitle => 'Каталог процедур';

  @override
  String get backToClinicLabel => 'Назад в клинику';

  @override
  String get newProcedureLabel => 'Новая процедура';

  @override
  String get editProcedureLabel => 'Изменить процедуру';

  @override
  String get procedureCatalogueOwnerHelp =>
      'Создавайте услуги, которые стоматологи добавляют в планы лечения.';

  @override
  String get procedureCatalogueViewerHelp =>
      'Доступные процедуры клиники и стандартные цены.';

  @override
  String get noProceduresCatalogue =>
      'Процедур пока нет. Владелец может добавить первую.';

  @override
  String get editLabel => 'Изменить';

  @override
  String get activateLabel => 'Активировать';

  @override
  String get activeLabel => 'Активен';

  @override
  String get nameLabel => 'Название';

  @override
  String get categoryLabel => 'Категория';

  @override
  String get standardPriceLabel => 'Стандартная цена';

  @override
  String get durationMinutesLabel => 'Длительность в минутах';

  @override
  String get validPriceValidation => 'Введите корректную цену.';

  @override
  String get durationRangeValidation => 'Укажите от 5 до 720 минут.';

  @override
  String get treatmentPlansUnavailable =>
      'Планы лечения недоступны. Вернитесь к списку пациентов и выберите пациента снова.';

  @override
  String get noActiveDentist => 'Нет доступного активного стоматолога.';

  @override
  String get newPlanLabel => 'Новый план';

  @override
  String get treatmentViewOnly =>
      'У вашей роли доступ к планам лечения только для просмотра.';

  @override
  String get noTreatmentPlan =>
      'Плана лечения пока нет. Стоматолог может подготовить черновик.';

  @override
  String get newTreatmentPlanTitle => 'Новый план лечения';

  @override
  String get leadDentistLabel => 'Ведущий стоматолог';

  @override
  String get planNotesOptional => 'Заметки плана (необязательно)';

  @override
  String get editPlanNotesTitle => 'Изменить заметки плана';

  @override
  String get notesLabel => 'Заметки';

  @override
  String get ownerAddProcedureFirst =>
      'Сначала владелец клиники должен добавить активную процедуру.';

  @override
  String get addProcedureLabel => 'Добавить процедуру';

  @override
  String get procedureLabel => 'Процедура';

  @override
  String get fdiToothOptional => 'Номер зуба FDI (необязательно)';

  @override
  String get validFdiValidation => 'Введите корректный номер зуба FDI.';

  @override
  String get estimatedPriceLabel => 'Ориентировочная цена';

  @override
  String get assignedDentistOptional =>
      'Назначенный стоматолог (необязательно)';

  @override
  String get notAssignedLabel => 'Не назначен';

  @override
  String get clinicalDescriptionOptional =>
      'Клиническое описание (необязательно)';

  @override
  String get saveProcedureLabel => 'Сохранить процедуру';

  @override
  String planTransitionQuestion(String status) {
    return 'Перевести план лечения в статус «$status»?';
  }

  @override
  String get activatePlanExplanation =>
      'План станет активным планом лечения пациента.';

  @override
  String get finalPlanTransitionExplanation =>
      'Изменение статуса записывается и не может быть отменено.';

  @override
  String get plansTitle => 'Планы';

  @override
  String procedureCountValue(int count) {
    return 'Процедур: $count';
  }

  @override
  String get editNotesLabel => 'Изменить заметки';

  @override
  String get activatePlanLabel => 'Активировать план';

  @override
  String get cancelPlanLabel => 'Отменить план';

  @override
  String get completePlanLabel => 'Завершить план';

  @override
  String get planHasNoProcedures => 'В этом плане пока нет процедур.';

  @override
  String get unavailableProcedure => 'Недоступная процедура';

  @override
  String toothNumberValue(int number) {
    return 'Зуб $number';
  }

  @override
  String dentistValue(String email) {
    return 'Стоматолог: $email';
  }

  @override
  String get changeStatusLabel => 'Изменить статус';

  @override
  String get planStatusDraft => 'Черновик';

  @override
  String get planStatusActive => 'Активен';

  @override
  String get planStatusCompleted => 'Завершён';

  @override
  String get planStatusCancelled => 'Отменён';

  @override
  String get itemStatusPlanned => 'Запланировано';

  @override
  String get itemStatusApproved => 'Одобрено';

  @override
  String get itemStatusInProgress => 'Выполняется';

  @override
  String get itemStatusCompleted => 'Завершено';

  @override
  String get itemStatusCancelled => 'Отменено';

  @override
  String get treatmentForbiddenIssue =>
      'Ваша роль в клинике не позволяет это изменение.';

  @override
  String get treatmentUnavailableIssue => 'Эта запись больше недоступна.';

  @override
  String get treatmentInvalidInputIssue =>
      'Проверьте введённые данные и попробуйте снова.';

  @override
  String get treatmentDraftOnlyIssue =>
      'Изменять можно только черновик плана лечения.';

  @override
  String get treatmentActiveRequiredIssue =>
      'Для этого изменения план лечения должен быть активным.';

  @override
  String get treatmentItemsRequiredIssue =>
      'Перед активацией добавьте хотя бы одну процедуру.';

  @override
  String get activePlanExistsIssue =>
      'У пациента уже есть активный план лечения.';

  @override
  String get treatmentInvalidTransitionIssue =>
      'Такое изменение статуса недоступно.';

  @override
  String get dentalChartUnavailable =>
      'Зубная карта недоступна. Вернитесь к списку пациентов и выберите пациента снова.';

  @override
  String get backToPatientProfile => 'Назад к профилю пациента';

  @override
  String get permanentTeethLabel => 'Постоянные зубы';

  @override
  String get primaryTeethLabel => 'Молочные зубы';

  @override
  String get selectToothToAdd => 'Выберите зуб, чтобы добавить состояние';

  @override
  String addConditionToTooth(int number) {
    return 'Добавить состояние зуба $number';
  }

  @override
  String get selectToothFirst => 'Сначала выберите зуб.';

  @override
  String addConditionTitle(int number) {
    return 'Добавить состояние — зуб $number';
  }

  @override
  String get conditionLabel => 'Состояние';

  @override
  String get surfaceLabel => 'Поверхность';

  @override
  String get clinicalNoteOptional => 'Клиническая заметка (необязательно)';

  @override
  String get saveConditionLabel => 'Сохранить состояние';

  @override
  String get resolveConditionQuestion => 'Закрыть состояние?';

  @override
  String resolveConditionExplanation(String condition, int number) {
    return 'Состояние «$condition» зуба $number останется в истории пациента.';
  }

  @override
  String get resolveLabel => 'Закрыть';

  @override
  String get markEntryErrorTitle => 'Отметить запись как ошибочную';

  @override
  String get entryErrorReasonLabel => 'Почему эта запись неверна?';

  @override
  String get preserveAsErrorLabel => 'Сохранить как ошибочную';

  @override
  String get selectToothReview =>
      'Выберите зуб для просмотра активных состояний.';

  @override
  String healthyToothMessage(int number) {
    return 'Зуб $number здоров. Активных состояний нет.';
  }

  @override
  String toothHealthySemantics(int number) {
    return 'Зуб $number, здоров';
  }

  @override
  String toothConditionsSemantics(int number, int count) {
    return 'Зуб $number, активных состояний: $count';
  }

  @override
  String get markAsErrorLabel => 'Отметить как ошибку';

  @override
  String get conditionHistoryTitle => 'История состояний';

  @override
  String recordedItemsValue(int count) {
    return 'Записей: $count';
  }

  @override
  String get noDentalHistory => 'История зубной карты пока пуста.';

  @override
  String get loadMoreHistoryLabel => 'Загрузить ещё историю';

  @override
  String get dentalRoleRestricted =>
      'Клинические сведения зубной карты недоступны для вашей роли.';

  @override
  String get surfaceWhole => 'Весь зуб';

  @override
  String get surfaceMesial => 'Мезиальная';

  @override
  String get surfaceDistal => 'Дистальная';

  @override
  String get surfaceOcclusal => 'Окклюзионная';

  @override
  String get surfaceBuccal => 'Щёчная';

  @override
  String get surfaceLingual => 'Язычная';

  @override
  String get conditionCaries => 'Кариес';

  @override
  String get conditionFilling => 'Пломба';

  @override
  String get conditionCrown => 'Коронка';

  @override
  String get conditionRootCanal => 'Корневой канал';

  @override
  String get conditionFracture => 'Перелом';

  @override
  String get conditionMissing => 'Отсутствует';

  @override
  String get conditionExtraction => 'Требуется удаление';

  @override
  String get conditionImplant => 'Имплант';

  @override
  String get conditionStatusActive => 'Активно';

  @override
  String get conditionStatusResolved => 'Закрыто';

  @override
  String get conditionStatusError => 'Внесено ошибочно';

  @override
  String get odontogramForbiddenIssue =>
      'Ваша роль не позволяет менять состояния зубной карты.';

  @override
  String get odontogramUnavailableIssue =>
      'Этот пациент или состояние больше недоступны.';

  @override
  String get odontogramInvalidInputIssue =>
      'Проверьте зуб, поверхность и сведения о состоянии.';

  @override
  String get missingToothConflictIssue =>
      'Закройте или исправьте существующее состояние естественного зуба перед отметкой об отсутствии.';

  @override
  String get duplicateConditionIssue =>
      'Это активное состояние уже записано для выбранной поверхности зуба.';

  @override
  String get conditionNotActiveIssue =>
      'Это состояние уже закрыто и остаётся в истории.';

  @override
  String get validAmountValidation => 'Введите корректную сумму.';

  @override
  String get quantityRangeValidation => 'Введите количество от 0,01 до 999,99.';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get moreLabel => 'Ещё';

  @override
  String get workspaceNavigationLabel => 'Навигация рабочего пространства';

  @override
  String get themeSystemLabel => 'Системная тема';

  @override
  String get languageSystemLabel => 'Системный язык';

  @override
  String get clinicSectionTitle => 'Клиника';

  @override
  String get privacySectionTitle => 'Конфиденциальность';

  @override
  String get accountSectionTitle => 'Учётная запись';

  @override
  String get applicationSectionTitle => 'Приложение';

  @override
  String get developmentMvpLabel =>
      'MVP для разработки · только вымышленные данные';

  @override
  String get currentRoleLabel => 'Ваша роль';

  @override
  String get patientNumberLabel => 'Номер пациента';

  @override
  String get patientNameLabel => 'Пациент';

  @override
  String get statusLabel => 'Статус';

  @override
  String get todayLabel => 'Сегодня';

  @override
  String get noAppointmentsDay => 'На этот день приёмов нет.';

  @override
  String get dentitionLabel => 'Зубной ряд';

  @override
  String get quadrantUpperRight => 'Верхний правый (UR)';

  @override
  String get quadrantUpperLeft => 'Верхний левый (UL)';

  @override
  String get quadrantLowerRight => 'Нижний правый (LR)';

  @override
  String get quadrantLowerLeft => 'Нижний левый (LL)';

  @override
  String get dentalMidline => 'Средняя линия';

  @override
  String get maxillaUpperJaw => 'Верхняя челюсть';

  @override
  String get mandibleLowerJaw => 'Нижняя челюсть';

  @override
  String get visitReasonLabel => 'Причина визита';

  @override
  String get quickReasonCheckup => 'Осмотр';

  @override
  String get quickReasonCleaning => 'Чистка';

  @override
  String get quickReasonToothache => 'Зубная боль / острая';

  @override
  String get quickReasonConsultation => 'Консультация';

  @override
  String get quickReasonFollowUp => 'Повторный приём';

  @override
  String doctorWorkingHours(String hours) {
    return 'Часы работы: $hours';
  }

  @override
  String get doctorOffDuty => 'У врача нет приёмных часов в этот день';

  @override
  String get doctorOnLeave => 'Врач в отпуске в этот день';

  @override
  String get changePatientLabel => 'Сменить пациента';

  @override
  String get overrideScheduleQuestion =>
      'Преодолеть конфликт расписания (только владелец)';

  @override
  String get selectedPatientCardTitle => 'Выбранный пациент';

  @override
  String get doctorNoScheduleConfigured =>
      'График работы врача еще не настроен в этой клинике';

  @override
  String timeOutsideWorkingHours(String time, String hours) {
    return 'Выбранное время ($time) вне рабочих часов врача ($hours)';
  }

  @override
  String get appointmentConflictExplanation =>
      'Этот прием конфликтует с расписанием врача (выходной, отпуск или вне рабочего времени). Как владелец клиники, укажите причину выше для подтверждения.';

  @override
  String get middleNameLabel => 'Отчество';

  @override
  String get administrativeNotesLabel => 'Административные заметки';

  @override
  String get personalInformationSection => 'Личные данные';

  @override
  String get contactInformationSection => 'Контактные данные';

  @override
  String get birthAndAgeSection => 'Дата рождения и возраст';

  @override
  String get selectBirthDateLabel => 'Выберите дату рождения';

  @override
  String get guardianInformationSection =>
      'Данные опекуна (для несовершеннолетних)';

  @override
  String get newPatientShortcut => '+ Зарегистрировать нового пациента';

  @override
  String yearsOldValue(int age) {
    return '$age лет';
  }

  @override
  String get ageInYearsLabel => 'Возраст в годах';

  @override
  String get clinicalHubTitle => 'Клинические записи и лечение';

  @override
  String get administrativeHubTitle => 'Администрация и приёмы';

  @override
  String get bookAppointmentLabel => 'Записаться на приём';

  @override
  String get minorBadge => 'Несовершеннолетний';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get copyLabel => 'Копировать';

  @override
  String durationMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String appointmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count приема',
      many: '$count приемов',
      few: '$count приема',
      one: '1 прием',
      zero: 'Нет приемов',
    );
    return '$_temp0';
  }

  @override
  String get viewProfileLabel => 'Профиль';

  @override
  String get preparationNoteBadge => 'Подготовка';

  @override
  String get overrideBadge => 'Переопределение';

  @override
  String get emptyCalendarTitle => 'Нет запланированных приёмов';

  @override
  String get emptyCalendarHelp =>
      'Используйте кнопку ниже или измените дату для просмотра или записи.';

  @override
  String get medicalAlertsTitle => 'Медицинские аллергии и оповещения';

  @override
  String get noKnownAllergies =>
      'Нет известных аллергий и медицинских предупреждений';

  @override
  String get unscreenedMedicalHelp =>
      'Медицинская карта еще не заполнена. Проведите скрининг перед началом лечения.';

  @override
  String get screenMedicalLabel => 'Заполнить медицинскую карту';

  @override
  String get whatsAppLabel => 'WhatsApp';

  @override
  String get callLabel => 'Позвонить';

  @override
  String get emailActionLabel => 'Отправить письмо';

  @override
  String get sendWhatsAppReminder => 'Напоминание в WhatsApp';

  @override
  String reminderMessageTemplate(
    String patientName,
    String clinicName,
    String dentistName,
    String date,
    String time,
  ) {
    return 'Здравствуйте, $patientName! Напоминаем о вашем приёме в $clinicName у доктора $dentistName $date в $time. Пожалуйста, ответьте на это сообщение для подтверждения записи. Спасибо!';
  }

  @override
  String get noPhoneForPatient => 'У этого пациента не указан номер телефона.';

  @override
  String get communicationLaunchFailed => 'Не удалось открыть приложение.';

  @override
  String get loadStandardProcedures => 'Загрузить стандартные услуги';

  @override
  String get loadStandardProceduresHelp =>
      'Быстро добавить стандартный набор стоматологических процедур в справочник клиники.';

  @override
  String loadStandardProceduresConfirm(int count) {
    return 'Будет добавлено $count стандартных стоматологических услуг. Вы сможете изменить цены и длительность в любое время. Продолжить?';
  }

  @override
  String get searchProceduresPlaceholder => 'Поиск процедур или категорий...';

  @override
  String get allCategoriesLabel => 'Все категории';

  @override
  String get activeOnlyFilter => 'Только активные';

  @override
  String totalProceduresCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count процедур',
      many: '$count процедур',
      few: '$count процедуры',
      one: '$count процедура',
    );
    return '$_temp0';
  }

  @override
  String activeProceduresCount(int count) {
    return '$count активных';
  }

  @override
  String categoriesCount(int count) {
    return '$count категорий';
  }

  @override
  String standardProceduresImported(int count) {
    return 'Успешно импортировано процедур: $count.';
  }

  @override
  String get noMatchingProcedures =>
      'Нет процедур, соответствующих поиску или фильтрам.';

  @override
  String get clearFiltersLabel => 'Сбросить фильтры';

  @override
  String get pressBackAgainToExit => 'Нажмите назад еще раз для выхода';

  @override
  String toothTreatmentsTitle(int toothNumber) {
    return 'Лечение зуба $toothNumber';
  }

  @override
  String get noTreatmentsPlannedForTooth =>
      'Для этого зуба пока нет запланированного лечения.';

  @override
  String get suggestedTreatmentsTitle => 'Рекомендуемые процедуры';

  @override
  String get addTreatmentForTooth => 'Добавить запланированное лечение';

  @override
  String get scheduleAppointmentForTooth => 'Записаться на прием';

  @override
  String get scheduleThisProcedure => 'Записать на эту процедуру';

  @override
  String get procedureAddedToPlan => 'Процедура добавлена в план лечения.';

  @override
  String get selectProcedureToAdd => 'Выберите процедуру из справочника';

  @override
  String get quickActions => 'Быстрые действия';

  @override
  String get quickNewAppointment => 'Новая запись';

  @override
  String get quickNewPatient => 'Новый пациент';

  @override
  String get inChairPatient => 'Пациент в кресле';

  @override
  String get nextPatient => 'Следующий пациент сегодня';

  @override
  String get openClinicalSession => 'Открыть прием';

  @override
  String get jawViewAll => 'Обе челюсти';

  @override
  String get jawViewUpper => 'Верхняя челюсть';

  @override
  String get jawViewLower => 'Нижняя челюсть';

  @override
  String get callPatient => 'Позвонить пациенту';

  @override
  String get filterAll => 'Все';

  @override
  String get filterScheduled => 'Запланировано';

  @override
  String get filterConfirmed => 'Подтверждено';

  @override
  String get filterInProgress => 'На приеме';

  @override
  String get filterCompleted => 'Завершено';

  @override
  String get quickToothActions => 'Быстрые действия с зубом';
}
