// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get createStaffAccountLabel => 'Create staff account';

  @override
  String get createStaffAccountHelp =>
      'Enter the staff member\'s email and a temporary password (15–128 characters). Share the login details privately. They must change the password before accessing the clinic. No email will be sent.';

  @override
  String get temporaryPasswordLabel => 'Temporary password';

  @override
  String get staffAccountCreated =>
      'Staff account created. Share the login details privately. A password change is required at first sign-in.';

  @override
  String get staffAccountUnavailable =>
      'Account could not be created. The email may already be registered, or account creation is temporarily unavailable. Existing accounts were not changed.';

  @override
  String get initialPasswordTitle => 'Choose your own password';

  @override
  String get initialPasswordHelp =>
      'Replace the temporary password with a different password of at least 15 characters. Clinic access stays locked until you finish. Then sign in again with your new password.';

  @override
  String get emailConfirmed => 'Your email is verified. Sign in to continue.';

  @override
  String get invalidConfirmationLink =>
      'This verification link is invalid or expired. Sign in to request a new link.';

  @override
  String get confirmationLinkSent =>
      'Check your inbox and open the verification link, then return to sign in. Wait at least 60 seconds before resending.';

  @override
  String get resendLinkLabel => 'Resend verification link';

  @override
  String get appTitle => 'DentaFlow';

  @override
  String get demoLabel => 'DEMO WORKSPACE';

  @override
  String get welcomeTitle => 'Your clinic, organized.';

  @override
  String get welcomeBody =>
      'A shared workspace for your dental clinic. Appointment and patient workflows are coming in the next development phases.';

  @override
  String get demoNotice =>
      'Fictional data only. This preview is not ready for real patient records.';

  @override
  String get appearanceTitle => 'Make yourself comfortable';

  @override
  String get themeLabel => 'Appearance';

  @override
  String get languageLabel => 'Language';

  @override
  String get systemLabel => 'Use device settings';

  @override
  String get lightLabel => 'Light';

  @override
  String get darkLabel => 'Dark';

  @override
  String get englishLabel => 'English';

  @override
  String get russianLabel => 'Русский';

  @override
  String get arabicLabel => 'العربية';

  @override
  String get storageWarning =>
      'Your preferences could not be saved or restored. You can still use this preview.';

  @override
  String get notFoundTitle => 'Page unavailable';

  @override
  String get notFoundBody =>
      'This page is not available in the current preview.';

  @override
  String get backHome => 'Back to workspace';

  @override
  String get startupTitle => 'Unable to open the workspace';

  @override
  String get startupBody =>
      'The application could not start. Check the development configuration and try again.';

  @override
  String get configurationBody =>
      'The development configuration is invalid. Check the environment and public backend settings. Production is not enabled.';

  @override
  String get retryLabel => 'Try again';

  @override
  String get networkFailure => 'Connection unavailable. Please try again.';

  @override
  String get authenticationFailure => 'Please sign in again to continue.';

  @override
  String get authorizationFailure =>
      'You do not have permission for this action.';

  @override
  String get validationFailure => 'Please check the information and try again.';

  @override
  String get serverFailure =>
      'The service is temporarily unavailable. Please try again.';

  @override
  String get notFoundFailure => 'The requested record is unavailable.';

  @override
  String get unknownFailure => 'Something went wrong. Please try again.';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get signInLabel => 'Sign in';

  @override
  String get registerLabel => 'Create account';

  @override
  String get forgotLabel => 'Forgot password?';

  @override
  String get verifyTitle => 'Verify your email';

  @override
  String get codeLabel => 'Verification code';

  @override
  String get verifyLabel => 'Verify code';

  @override
  String get resendLabel => 'Resend code';

  @override
  String get changeEmailLabel => 'Change email';

  @override
  String get forgotTitle => 'Recover your account';

  @override
  String get sendCodeLabel => 'Send recovery code';

  @override
  String get sendResetLinkLabel => 'Send reset link';

  @override
  String get recoveryLinkSent =>
      'If this account exists, open the password-reset link in your email to choose a new password.';

  @override
  String get resetTitle => 'Reset your password';

  @override
  String get resetLabel => 'Save new password';

  @override
  String get lockedTitle => 'Workspace locked';

  @override
  String get lockedBody => 'Enter your password to unlock your account.';

  @override
  String get unlockLabel => 'Unlock';

  @override
  String get switchAccountLabel => 'Switch account';

  @override
  String get accountTitle => 'Your account is ready';

  @override
  String get accountBody =>
      'Clinic setup will be available in the next phase. Your account has no clinic role yet.';

  @override
  String get lockLabel => 'Lock workspace';

  @override
  String get logoutLabel => 'Sign out';

  @override
  String get backLoginLabel => 'Back to sign in';

  @override
  String get passwordHelp =>
      'Use at least 15 characters. Spaces and password managers are welcome.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get passwordShort => 'Use at least 15 characters.';

  @override
  String get passwordMismatch => 'Passwords must match.';

  @override
  String get invalidCodeInput => 'Enter the six-digit email code.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get authCredentials =>
      'The credentials could not be verified. Please try again.';

  @override
  String get authUnconfirmed => 'Confirm your email before signing in.';

  @override
  String get authInvalidCode =>
      'This code is invalid or expired. Request a new one.';

  @override
  String get authWeakPassword =>
      'This password does not meet the server requirements.';

  @override
  String get authRateLimited =>
      'Too many attempts. Please wait before trying again.';

  @override
  String get authStorage =>
      'Session storage is unavailable. Access remains blocked; check browser or device storage settings.';

  @override
  String get authUnavailable =>
      'Authentication is not configured. Open the configured development build.';

  @override
  String get authRevocation =>
      'Signed out on this device. Server session revocation could not be confirmed.';

  @override
  String get authResetPartial =>
      'Password changed, but revoking all sessions could not be confirmed. Sign in again; other sessions may still be active.';

  @override
  String get authResetDone => 'Password changed. Please sign in again.';

  @override
  String get authCodeSent =>
      'If this address is eligible, an email code has been sent. Check your inbox. Codes expire after one hour; wait at least 60 seconds before resending.';

  @override
  String get restoringTitle => 'Checking your session';

  @override
  String get restoreFailedTitle => 'Session could not be restored';

  @override
  String get privacyHidden => 'Workspace hidden';

  @override
  String get authSettings => 'Appearance and language';

  @override
  String get continueAuth => 'Sign in or create an account';

  @override
  String get clinicSetupTitle => 'Set up your clinic';

  @override
  String get clinicSetupBody =>
      'Create your first clinic to begin using DentaFlow. You can create more clinics later.';

  @override
  String get createClinicLabel => 'Create clinic';

  @override
  String get clinicNameLabel => 'Clinic name';

  @override
  String get clinicNameHelp => 'Use the name staff and patients recognize.';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get timeZoneLabel => 'Time zone';

  @override
  String get timeZoneHelp =>
      'Prefilled from this device. Change it if the clinic operates elsewhere.';

  @override
  String get selectClinicTitle => 'Choose a clinic';

  @override
  String get selectClinicBody =>
      'Choose the clinic you want to work in. You can switch clinics later.';

  @override
  String get currentClinicTitle => 'Clinic selected';

  @override
  String currentClinicBody(Object clinicName) {
    return 'Active workspace: $clinicName. Select an action below or proceed directly to your dashboard.';
  }

  @override
  String get switchClinicLabel => 'Switch clinic';

  @override
  String get addClinicLabel => 'Add another clinic';

  @override
  String get clinicLoadTitle => 'Loading your clinics';

  @override
  String get clinicLoadFailed => 'We could not load your clinics. Try again.';

  @override
  String get timeZoneUtc => 'UTC';

  @override
  String get visitsTitle => 'Visits';

  @override
  String get newSessionLabel => 'New session';

  @override
  String get noVisitsMessage => 'No clinical visits yet.';

  @override
  String get clinicalViewOnly =>
      'You have view-only access to clinical sessions.';

  @override
  String get linkedAppointmentLabel => 'Linked appointment';

  @override
  String get walkInLabel => 'Walk-in visit';

  @override
  String get draftStatus => 'Draft';

  @override
  String get finalizedStatus => 'Finalized';

  @override
  String get enteredInErrorStatus => 'Entered in error';

  @override
  String get clinicalNotesLabel => 'Clinical notes';

  @override
  String get recommendationsLabel => 'Recommendations';

  @override
  String get saveDraftLabel => 'Save draft';

  @override
  String get finalizeSessionLabel => 'Finalize session';

  @override
  String get markInErrorLabel => 'Mark entered in error';

  @override
  String get addAmendmentLabel => 'Add amendment';

  @override
  String get amendmentsTitle => 'Amendments';

  @override
  String get amendmentTextLabel => 'Correction';

  @override
  String get reasonLabel => 'Reason';

  @override
  String get selectVisitTypeTitle => 'Create clinical session';

  @override
  String get chooseAppointmentLabel => 'Choose appointment';

  @override
  String get chooseDentistLabel => 'Choose dentist';

  @override
  String get visitDateTimeLabel => 'Visit date and time';

  @override
  String get createDraftLabel => 'Create draft';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get loadMoreLabel => 'Load more';

  @override
  String get reloadLatestLabel => 'Reload latest draft';

  @override
  String get revisionConflictMessage =>
      'Another staff member saved this draft. Reload the latest version before continuing.';

  @override
  String get sessionUnavailableMessage =>
      'This clinical session is unavailable.';

  @override
  String get clinicalActionFailedMessage =>
      'The clinical action could not be completed. Check the session and try again.';

  @override
  String get finalizeWarning =>
      'After finalization, the original clinical record cannot be edited. Corrections require a signed amendment.';

  @override
  String get originalRecordTitle => 'Original clinical record';

  @override
  String get appointmentSessionLabel => 'Appointment visit';

  @override
  String get sessionDateLabel => 'Session date';

  @override
  String get assignedDentistLabel => 'Assigned dentist';

  @override
  String get lastSavedLabel => 'Last saved';

  @override
  String get openClinicalSessionLabel => 'Open clinical session';

  @override
  String get patientFilesTitle => 'Patient files';

  @override
  String get uploadFileLabel => 'Upload file';

  @override
  String get noPatientFilesMessage => 'No patient files yet.';

  @override
  String get patientFilesViewOnly =>
      'You have view-only access to patient files.';

  @override
  String get includeArchivedFilesLabel => 'Show archived files';

  @override
  String get allFileCategoriesLabel => 'All categories';

  @override
  String get fileCategoryLabel => 'Category';

  @override
  String get fileCategoryXray => 'X-ray';

  @override
  String get fileCategoryClinicalPhoto => 'Clinical photo';

  @override
  String get fileCategoryConsent => 'Consent';

  @override
  String get fileCategoryReferral => 'Referral';

  @override
  String get fileCategoryLaboratory => 'Laboratory result';

  @override
  String get fileCategoryOther => 'Other';

  @override
  String get fileDescriptionLabel => 'Description (optional)';

  @override
  String get chooseFileLabel => 'Choose JPG, PNG, or PDF';

  @override
  String get fileTypeHelp => 'Maximum 15 MB. Demo files only.';

  @override
  String get fileSelectionInvalid =>
      'Choose a valid JPG, PNG, or PDF file up to 15 MB.';

  @override
  String get uploadingFileLabel => 'Uploading file';

  @override
  String get validatingFileLabel => 'Validating file securely…';

  @override
  String get cancelUploadLabel => 'Cancel upload';

  @override
  String get openFileLabel => 'Open file';

  @override
  String get openPdfLabel => 'Open PDF';

  @override
  String get archiveFileLabel => 'Archive file';

  @override
  String get restoreFileLabel => 'Restore file';

  @override
  String get uploadReplacementLabel => 'Upload replacement';

  @override
  String get archiveFileWarning =>
      'The file will remain stored and auditable. Enter a reason to archive it.';

  @override
  String get archivedFileLabel => 'Archived';

  @override
  String get fileUnavailableMessage => 'This patient file is unavailable.';

  @override
  String get fileActionFailedMessage =>
      'The file action could not be completed. Check the file and try again.';

  @override
  String get fileSizeLabel => 'Size';

  @override
  String get uploadedAtLabel => 'Uploaded';

  @override
  String get fileLinkedVisitLabel => 'Linked visit';

  @override
  String get patientFilesRestricted =>
      'Patient files are restricted to authorized clinical staff.';

  @override
  String get billingTitle => 'Billing & invoices';

  @override
  String get newInvoiceLabel => 'New invoice';

  @override
  String get noInvoicesMessage => 'No invoices yet.';

  @override
  String get billingRestricted =>
      'Billing is available to authorized billing and clinical staff.';

  @override
  String get invoiceDraftLabel => 'Draft invoice';

  @override
  String get invoiceItemsTitle => 'Invoice items';

  @override
  String get noInvoiceItemsMessage => 'No procedures have been added.';

  @override
  String get addCatalogueItemLabel => 'Add from catalogue';

  @override
  String get addTreatmentItemLabel => 'Add from treatment plan';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get approveContentLabel => 'Approve clinical content';

  @override
  String get reopenContentLabel => 'Reopen clinical content';

  @override
  String get financialDetailsTitle => 'Financial details';

  @override
  String get unitPriceLabel => 'Unit price';

  @override
  String get discountTypeLabel => 'Discount type';

  @override
  String get discountNoneLabel => 'No discount';

  @override
  String get discountFixedLabel => 'Fixed amount';

  @override
  String get discountPercentageLabel => 'Percentage';

  @override
  String get discountValueLabel => 'Discount value';

  @override
  String get taxRateLabel => 'Tax rate (%)';

  @override
  String get invoiceLanguageLabel => 'Invoice language';

  @override
  String get languageEnglishLabel => 'English';

  @override
  String get languageRussianLabel => 'Russian';

  @override
  String get languageArabicLabel => 'Arabic';

  @override
  String get saveFinancialsLabel => 'Save financial details';

  @override
  String get finalizeInvoiceLabel => 'Finalize invoice';

  @override
  String get finalizeInvoiceWarning =>
      'Finalization assigns a permanent invoice number. The invoice items and prices cannot be edited afterward.';

  @override
  String get cancelInvoiceLabel => 'Cancel invoice';

  @override
  String get recordPaymentLabel => 'Record payment';

  @override
  String get paymentAmountLabel => 'Amount received';

  @override
  String get paymentMethodLabel => 'Payment method';

  @override
  String get paymentCashLabel => 'Cash';

  @override
  String get paymentCardLabel => 'Card';

  @override
  String get paymentBankLabel => 'Bank transfer';

  @override
  String get paymentOtherLabel => 'Other';

  @override
  String get referenceLabel => 'Reference (optional)';

  @override
  String get patientCreditLabel => 'Patient credit';

  @override
  String get applyCreditLabel => 'Apply credit';

  @override
  String get paymentHistoryTitle => 'Payments & corrections';

  @override
  String get refundLabel => 'Refund';

  @override
  String get correctionLabel => 'Correction';

  @override
  String get exportInvoiceLabel => 'Open invoice PDF';

  @override
  String get invoiceSubtotalLabel => 'Subtotal';

  @override
  String get invoiceDiscountLabel => 'Discount';

  @override
  String get invoiceTaxLabel => 'Tax';

  @override
  String get invoiceTotalLabel => 'Total';

  @override
  String get invoicePaidLabel => 'Paid';

  @override
  String get invoiceDueLabel => 'Due';

  @override
  String get paymentUnpaidLabel => 'Unpaid';

  @override
  String get paymentPartialLabel => 'Partially paid';

  @override
  String get paymentPaidLabel => 'Paid';

  @override
  String get invoiceCancelledLabel => 'Cancelled';

  @override
  String get billingActionFailedMessage =>
      'The billing action could not be completed. Reload the invoice and try again.';

  @override
  String get billingConflictMessage =>
      'This invoice changed or is no longer eligible for that action. Reload it and try again.';

  @override
  String get invoicePdfUnavailableMessage =>
      'The invoice PDF could not be prepared. Try again.';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardActivePatients => 'Active patients';

  @override
  String get dashboardAppointmentsThisWeek => 'Appointments this week';

  @override
  String get dashboardCompletedThisMonth => 'Treatments completed this month';

  @override
  String get dashboardOutstandingPayments => 'Outstanding payments';

  @override
  String dashboardOutstandingInvoices(int count) {
    return '$count outstanding invoices';
  }

  @override
  String get dashboardTodayAppointments => 'Today\'s appointments';

  @override
  String get dashboardUpcomingAppointments => 'Upcoming appointments';

  @override
  String get dashboardNextSevenDays => 'Next seven days';

  @override
  String get dashboardNoTodayAppointments =>
      'No appointments scheduled for today.';

  @override
  String get dashboardNoUpcomingAppointments =>
      'No upcoming appointments in the next seven days.';

  @override
  String get dashboardViewAllAppointments => 'View all appointments';

  @override
  String dashboardLastUpdated(String value) {
    return 'Updated $value';
  }

  @override
  String dashboardTimeZone(String value) {
    return 'Clinic time · $value';
  }

  @override
  String get dashboardRefresh => 'Refresh dashboard';

  @override
  String get dashboardRefreshFailed =>
      'The latest dashboard data could not be loaded. Showing the previous result.';

  @override
  String get dashboardUnavailable =>
      'The dashboard is temporarily unavailable.';

  @override
  String get dashboardNoActiveClinic =>
      'Choose an active clinic to open its dashboard.';

  @override
  String get dashboardOpenPatients => 'Open patients';

  @override
  String get dashboardOpenTreatments => 'Open treatments';

  @override
  String get dashboardOpenBilling => 'Open billing';

  @override
  String get appointmentStatusScheduled => 'Scheduled';

  @override
  String get appointmentStatusConfirmed => 'Confirmed';

  @override
  String get appointmentStatusInProgress => 'In progress';

  @override
  String get appointmentStatusCompleted => 'Completed';

  @override
  String get appointmentStatusNoShow => 'No-show';

  @override
  String get appointmentStatusCancelled => 'Cancelled';

  @override
  String get auditTitle => 'Audit log';

  @override
  String get auditOpen => 'Open audit log';

  @override
  String get auditRefresh => 'Refresh audit log';

  @override
  String get auditUnavailable => 'The audit log is temporarily unavailable.';

  @override
  String get auditOwnerOnly =>
      'Only an active clinic owner can view the audit log.';

  @override
  String get auditNoEvents => 'No recorded activity in this date range.';

  @override
  String get auditNoFilterResults => 'No activity matches these filters.';

  @override
  String get auditFilters => 'Filters';

  @override
  String get auditClearFilters => 'Clear filters';

  @override
  String get auditDateRange => 'Date range';

  @override
  String get auditEmployee => 'Employee';

  @override
  String get auditAllEmployees => 'All employees';

  @override
  String get auditCategory => 'Category';

  @override
  String get auditAllCategories => 'All categories';

  @override
  String get auditEntityType => 'Entity type';

  @override
  String get auditAllEntities => 'All entities';

  @override
  String get auditLoadMore => 'Load more';

  @override
  String get auditDetails => 'Event details';

  @override
  String get auditOccurredAt => 'Time';

  @override
  String get auditAction => 'Action';

  @override
  String get auditEntity => 'Entity';

  @override
  String get auditReason => 'Reason';

  @override
  String get auditNoReason => 'No reason recorded';

  @override
  String get auditActorRoles => 'Roles at the time';

  @override
  String get auditFormerActor => 'Former or unavailable staff member';

  @override
  String get auditCategoryAccess => 'Access';

  @override
  String get auditCategoryPatient => 'Patient administration';

  @override
  String get auditCategoryScheduling => 'Scheduling';

  @override
  String get auditCategoryClinical => 'Clinical';

  @override
  String get auditCategoryFinancial => 'Financial';

  @override
  String get auditCategoryStaff => 'Staff and security';

  @override
  String get auditOtherAction => 'Other recorded action';

  @override
  String get auditOpenRecord => 'Open related record';

  @override
  String auditShowingRange(String from, String to, String timeZone) {
    return '$from – $to · $timeZone';
  }

  @override
  String get auditRefreshFailed =>
      'The latest audit activity could not be loaded. Showing the previous result.';

  @override
  String get auditActionAccess => 'Sensitive access recorded';

  @override
  String get auditActionPatient => 'Patient administration changed';

  @override
  String get auditActionScheduling => 'Schedule or appointment changed';

  @override
  String get auditActionClinical => 'Clinical record changed';

  @override
  String get auditActionFinancial => 'Financial record changed';

  @override
  String get auditActionStaff => 'Staff or security changed';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleDentist => 'Dentist';

  @override
  String get roleAssistant => 'Assistant';

  @override
  String get roleReceptionist => 'Receptionist';

  @override
  String get auditResultCount => 'Result count';

  @override
  String get auditApplyFilters => 'Apply filters';

  @override
  String appointmentsWithTimeZone(String timeZone) {
    return 'Appointments · $timeZone';
  }

  @override
  String get previousWeekLabel => 'Previous week';

  @override
  String get nextWeekLabel => 'Next week';

  @override
  String get newAppointmentLabel => 'New appointment';

  @override
  String get noAppointmentsWeek => 'No appointments in this week.';

  @override
  String get chooseClinicFirst => 'Choose a clinic first.';

  @override
  String clinicTimeZoneValue(String timeZone) {
    return 'Clinic time zone: $timeZone';
  }

  @override
  String get findPatientLabel =>
      'Find patient by name, phone, email, or number';

  @override
  String patientSelectedValue(String patientId) {
    return 'Patient selected: $patientId';
  }

  @override
  String get dentistLabel => 'Dentist';

  @override
  String get chooseDentistValidation => 'Choose a dentist';

  @override
  String get dateLabel => 'Date';

  @override
  String get startTimeLabel => 'Start time';

  @override
  String get durationLabel => 'Duration';

  @override
  String minutesValue(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get appointmentPurposeOptional => 'Purpose (optional, non-clinical)';

  @override
  String get ownerOverrideOptional =>
      'Owner override reason (only when needed)';

  @override
  String get createAppointmentLabel => 'Create appointment';

  @override
  String get rescheduleLabel => 'Reschedule';

  @override
  String get confirmLabel => 'Confirm';

  @override
  String get startLabel => 'Start';

  @override
  String get completeLabel => 'Complete';

  @override
  String get markNoShowLabel => 'Mark no-show';

  @override
  String get preparationNoteLabel => 'Preparation note';

  @override
  String get ownerOverrideReasonTitle => 'Owner override reason';

  @override
  String get overrideConflictHelp => 'Only needed if the new time conflicts';

  @override
  String get continueLabel => 'Continue';

  @override
  String get useReasonLabel => 'Use reason';

  @override
  String get operationalPreparationNoteTitle => 'Operational preparation note';

  @override
  String get saveLabel => 'Save';

  @override
  String get cancellationReasonTitle => 'Cancellation reason';

  @override
  String get appointmentUnavailableIssue =>
      'The patient or appointment is unavailable.';

  @override
  String get appointmentForbiddenIssue =>
      'Your role cannot perform this appointment action.';

  @override
  String get appointmentPatientOverlapIssue =>
      'This patient already has an overlapping appointment.';

  @override
  String get appointmentDentistOverlapIssue =>
      'The dentist already has an overlapping appointment.';

  @override
  String get appointmentWorkingHoursIssue =>
      'This time is outside the dentist working hours.';

  @override
  String get appointmentLeaveIssue => 'The dentist is on leave at this time.';

  @override
  String get appointmentUnavailablePeriodIssue =>
      'The dentist is unavailable at this time.';

  @override
  String get appointmentOverrideRequiredIssue =>
      'An Owner must add a reason to override this conflict.';

  @override
  String get appointmentInvalidTransitionIssue =>
      'This appointment status cannot be changed that way.';

  @override
  String get patientsTitle => 'Patients';

  @override
  String get newPatientLabel => 'New patient';

  @override
  String get searchPatientLabel => 'Search name, phone, email, or number';

  @override
  String get archivedLabel => 'Archived';

  @override
  String get patientActionUnavailable =>
      'This patient action is not available.';

  @override
  String get noPatientsFound => 'No patients found.';

  @override
  String get noContactLabel => 'No contact';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get birthDateInformationLabel => 'Birth date information';

  @override
  String get birthPrecisionUnknown => 'Unknown';

  @override
  String get birthPrecisionExact => 'Exact';

  @override
  String get birthPrecisionApproximate => 'Approximate';

  @override
  String get birthDateFormatLabel => 'Birth date (YYYY-MM-DD)';

  @override
  String get approximateAgeLabel => 'Approximate age in years';

  @override
  String get ageAssessedOnLabel => 'Age assessed on (YYYY-MM-DD)';

  @override
  String get knownMinorLabel => 'Patient is known to be under 18';

  @override
  String get guardianNameLabel => 'Guardian name';

  @override
  String get guardianPhoneLabel => 'Guardian phone';

  @override
  String get guardianEmailLabel => 'Guardian email';

  @override
  String get createPatientLabel => 'Create patient';

  @override
  String get patientProfileTitle => 'Patient profile';

  @override
  String get patientProfileUnavailable =>
      'Patient profile is unavailable. Return to search and select the patient again.';

  @override
  String get contactTitle => 'Contact';

  @override
  String get medicalProfileTitle => 'Medical profile';

  @override
  String get appointmentsTitle => 'Appointments';

  @override
  String get dentalChartTitle => 'Dental Chart';

  @override
  String get treatmentPlansTitle => 'Treatment plans';

  @override
  String get restorePatientLabel => 'Restore patient';

  @override
  String get archivePatientLabel => 'Archive patient';

  @override
  String get birthInformationTitle => 'Birth information';

  @override
  String approximatelyYearsValue(int years) {
    return 'Approximately $years years';
  }

  @override
  String get archivePatientQuestion => 'Archive patient?';

  @override
  String get restorePatientQuestion => 'Restore patient?';

  @override
  String get archivePatientExplanation =>
      'Archived patients remain in the clinic record and can be restored by an owner.';

  @override
  String get restorePatientExplanation =>
      'This returns the patient to the active clinic record.';

  @override
  String get archiveLabel => 'Archive';

  @override
  String get restoreLabel => 'Restore';

  @override
  String get medicalRoleRestricted =>
      'Medical information is not available for your role.';

  @override
  String get allergiesLabel => 'Allergies';

  @override
  String get currentMedicationsLabel => 'Current medications';

  @override
  String get chronicConditionsLabel => 'Chronic conditions';

  @override
  String get importantMedicalNotesLabel => 'Important medical notes';

  @override
  String get saveMedicalProfileLabel => 'Save medical profile';

  @override
  String get staffTitle => 'Staff';

  @override
  String get backLabel => 'Back';

  @override
  String get inviteStaffLabel => 'Invite staff';

  @override
  String get staffOwnerOnly => 'Only clinic owners can manage staff.';

  @override
  String get manageStaffDescription =>
      'Manage roles and access for this clinic.';

  @override
  String get webInvitationOnly => 'Send invitations from the Web workspace.';

  @override
  String get verifiedEmailLabel => 'Verified email';

  @override
  String get sendInvitationLabel => 'Send invitation';

  @override
  String get saveRolesLabel => 'Save roles';

  @override
  String get reactivateStaffQuestion => 'Reactivate staff member?';

  @override
  String get deactivateStaffQuestion => 'Deactivate staff member?';

  @override
  String get reactivateLabel => 'Reactivate';

  @override
  String get deactivateLabel => 'Deactivate';

  @override
  String get confirmPasswordTitle => 'Confirm your password';

  @override
  String get invalidInvitationLink =>
      'This invitation link is invalid or unavailable.';

  @override
  String get joinClinicTitle => 'Join clinic';

  @override
  String get acceptInvitationHelp =>
      'Accept this invitation only if you signed in with the email address it was sent to.';

  @override
  String get acceptInvitationLabel => 'Accept invitation';

  @override
  String staffCountTitle(int count) {
    return 'Staff ($count)';
  }

  @override
  String get inactiveLabel => 'Inactive';

  @override
  String get editRolesLabel => 'Edit roles';

  @override
  String invitationCountTitle(int count) {
    return 'Invitations ($count)';
  }

  @override
  String get resendInvitationLabel => 'Resend';

  @override
  String get revokeInvitationLabel => 'Revoke';

  @override
  String get invitationPending => 'Pending';

  @override
  String get invitationAccepted => 'Accepted';

  @override
  String get invitationRevoked => 'Revoked';

  @override
  String get invitationExpired => 'Expired';

  @override
  String get staffInvalidInputIssue => 'Check the information and try again.';

  @override
  String get ownerPasswordRequiredIssue => 'Confirm your password to continue.';

  @override
  String get invitationUnavailableIssue => 'This invitation is unavailable.';

  @override
  String get staffMemberUnavailableIssue => 'This staff member is unavailable.';

  @override
  String get doctorScheduleTitle => 'Doctor schedule';

  @override
  String get scheduleChooseClinic =>
      'Choose a clinic before viewing schedules.';

  @override
  String clinicTimeZoneExplanation(String timeZone) {
    return 'All times use the clinic time zone: $timeZone.';
  }

  @override
  String get setWeeklyHoursLabel => 'Set weekly hours';

  @override
  String get addUnavailableTimeLabel => 'Add leave or unavailable time';

  @override
  String get weeklyHoursTitle => 'Weekly hours';

  @override
  String get noWeeklyHours => 'No weekly hours have been set for this dentist.';

  @override
  String get unavailablePeriodsTitle => 'Leave and unavailable periods';

  @override
  String get noUnavailablePeriods =>
      'No leave or unavailable periods are recorded.';

  @override
  String get leaveLabel => 'Leave';

  @override
  String get unavailableLabel => 'Unavailable';

  @override
  String get removeLabel => 'Remove';

  @override
  String scheduleConflictOwnerReview(int count) {
    return 'This change conflicts with $count future appointment(s). An Owner must review it.';
  }

  @override
  String get weekdayNumberHelp => 'Use 1 for Monday through 7 for Sunday.';

  @override
  String get workingDaysLabel => 'Working days';

  @override
  String get startTimeFormatLabel => 'Start time (HH:MM)';

  @override
  String get endTimeFormatLabel => 'End time (HH:MM)';

  @override
  String get breakStartOptional => 'Break start (optional)';

  @override
  String get breakEndOptional => 'Break end (optional)';

  @override
  String get effectiveFromFormatLabel => 'Effective from (YYYY-MM-DD)';

  @override
  String get addUnavailableTimeTitle => 'Add unavailable time';

  @override
  String get typeLabel => 'Type';

  @override
  String get startsLabel => 'Starts';

  @override
  String get endsLabel => 'Ends';

  @override
  String get reasonOptionalLabel => 'Reason (optional)';

  @override
  String effectiveFromValue(String date) {
    return 'Effective from $date';
  }

  @override
  String get noWorkingHours => 'No working hours';

  @override
  String get breakLabel => 'break';

  @override
  String get reviewAffectedAppointmentsTitle => 'Review affected appointments';

  @override
  String affectedAppointmentsExplanation(int count) {
    return 'This change conflicts with $count future appointment(s). They will remain booked and be flagged for manual resolution.';
  }

  @override
  String get ownerConfirmationReasonLabel => 'Owner confirmation reason';

  @override
  String get cancelChangeLabel => 'Cancel change';

  @override
  String get confirmAndFlagLabel => 'Confirm and flag';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get scheduleEditForbiddenIssue =>
      'You cannot change this dentist schedule.';

  @override
  String get activeDentistRequiredIssue =>
      'This staff member is not an active dentist.';

  @override
  String get effectiveDateInvalidIssue => 'Choose a future clinic date.';

  @override
  String get exceptionUnavailableIssue =>
      'This unavailable period is no longer available.';

  @override
  String get affectedAppointmentsIssue =>
      'This schedule change affects future appointments and requires Owner review.';

  @override
  String get scheduleSavedMessage => 'Weekly hours saved.';

  @override
  String get scheduleInvalidInputMessage =>
      'Check the working days, times, break, and effective date.';

  @override
  String get scheduleForLabel => 'Schedule for';

  @override
  String get scheduleActiveLabel => 'Active schedule';

  @override
  String get scheduleUpcomingLabel => 'Upcoming schedule';

  @override
  String get scheduleHistoryLabel => 'Schedule history';

  @override
  String get scheduleHistoryHelp =>
      'Previous and superseded working-hour versions';

  @override
  String get editWeeklyHoursLabel => 'Edit weekly schedule';

  @override
  String get selectWorkingDaysHelp => 'Select the days this dentist works.';

  @override
  String get includeBreakLabel => 'Include a break';

  @override
  String get effectiveDateLabel => 'Effective date';

  @override
  String get closedLabel => 'Closed';

  @override
  String get scheduleSummaryLabel => 'Schedule summary';

  @override
  String get procedureCatalogueTitle => 'Procedure catalogue';

  @override
  String get backToClinicLabel => 'Back to clinic';

  @override
  String get newProcedureLabel => 'New procedure';

  @override
  String get editProcedureLabel => 'Edit procedure';

  @override
  String get procedureCatalogueOwnerHelp =>
      'Create the services dentists can add to treatment plans.';

  @override
  String get procedureCatalogueViewerHelp =>
      'Available clinic procedures and standard prices.';

  @override
  String get noProceduresCatalogue =>
      'No procedures yet. An owner can add the first procedure.';

  @override
  String get editLabel => 'Edit';

  @override
  String get activateLabel => 'Activate';

  @override
  String get activeLabel => 'Active';

  @override
  String get nameLabel => 'Name';

  @override
  String get categoryLabel => 'Category';

  @override
  String get standardPriceLabel => 'Standard price';

  @override
  String get durationMinutesLabel => 'Duration in minutes';

  @override
  String get validPriceValidation => 'Enter a valid price.';

  @override
  String get durationRangeValidation => 'Use 5 to 720 minutes.';

  @override
  String get treatmentPlansUnavailable =>
      'Treatment plans are unavailable. Return to the patient list and select the patient again.';

  @override
  String get noActiveDentist => 'No active dentist membership is available.';

  @override
  String get newPlanLabel => 'New plan';

  @override
  String get treatmentViewOnly =>
      'Your role has view-only access to treatment plans.';

  @override
  String get noTreatmentPlan =>
      'No treatment plan yet. A dentist can prepare a draft plan.';

  @override
  String get newTreatmentPlanTitle => 'New treatment plan';

  @override
  String get leadDentistLabel => 'Lead dentist';

  @override
  String get planNotesOptional => 'Plan notes (optional)';

  @override
  String get editPlanNotesTitle => 'Edit plan notes';

  @override
  String get notesLabel => 'Notes';

  @override
  String get ownerAddProcedureFirst =>
      'The clinic owner must add an active procedure first.';

  @override
  String get addProcedureLabel => 'Add procedure';

  @override
  String get procedureLabel => 'Procedure';

  @override
  String get fdiToothOptional => 'FDI tooth number (optional)';

  @override
  String get validFdiValidation => 'Enter a valid FDI tooth number.';

  @override
  String get estimatedPriceLabel => 'Estimated price';

  @override
  String get assignedDentistOptional => 'Assigned dentist (optional)';

  @override
  String get notAssignedLabel => 'Not assigned';

  @override
  String get clinicalDescriptionOptional => 'Clinical description (optional)';

  @override
  String get saveProcedureLabel => 'Save procedure';

  @override
  String planTransitionQuestion(String status) {
    return '$status treatment plan?';
  }

  @override
  String get activatePlanExplanation =>
      'This makes the plan the patient’s active treatment plan.';

  @override
  String get finalPlanTransitionExplanation =>
      'This status change is recorded and cannot be reversed.';

  @override
  String get plansTitle => 'Plans';

  @override
  String procedureCountValue(int count) {
    return '$count procedures';
  }

  @override
  String get editNotesLabel => 'Edit notes';

  @override
  String get activatePlanLabel => 'Activate plan';

  @override
  String get cancelPlanLabel => 'Cancel plan';

  @override
  String get completePlanLabel => 'Complete plan';

  @override
  String get planHasNoProcedures => 'This plan has no procedures yet.';

  @override
  String get unavailableProcedure => 'Unavailable procedure';

  @override
  String toothNumberValue(int number) {
    return 'Tooth $number';
  }

  @override
  String dentistValue(String email) {
    return 'Dentist: $email';
  }

  @override
  String get changeStatusLabel => 'Change status';

  @override
  String get planStatusDraft => 'Draft';

  @override
  String get planStatusActive => 'Active';

  @override
  String get planStatusCompleted => 'Completed';

  @override
  String get planStatusCancelled => 'Cancelled';

  @override
  String get itemStatusPlanned => 'Planned';

  @override
  String get itemStatusApproved => 'Approved';

  @override
  String get itemStatusInProgress => 'In progress';

  @override
  String get itemStatusCompleted => 'Completed';

  @override
  String get itemStatusCancelled => 'Cancelled';

  @override
  String get treatmentForbiddenIssue =>
      'Your clinic role cannot make this change.';

  @override
  String get treatmentUnavailableIssue => 'This record is no longer available.';

  @override
  String get treatmentInvalidInputIssue =>
      'Check the entered information and try again.';

  @override
  String get treatmentDraftOnlyIssue =>
      'Only a draft treatment plan can be edited.';

  @override
  String get treatmentActiveRequiredIssue =>
      'The treatment plan must be active for this change.';

  @override
  String get treatmentItemsRequiredIssue =>
      'Add at least one procedure before activating the plan.';

  @override
  String get activePlanExistsIssue =>
      'This patient already has an active treatment plan.';

  @override
  String get treatmentInvalidTransitionIssue =>
      'That status change is not allowed.';

  @override
  String get dentalChartUnavailable =>
      'Dental Chart is unavailable. Return to the patient list and select the patient again.';

  @override
  String get backToPatientProfile => 'Back to patient profile';

  @override
  String get permanentTeethLabel => 'Permanent teeth';

  @override
  String get primaryTeethLabel => 'Primary teeth';

  @override
  String get selectToothToAdd => 'Select a tooth to add a condition';

  @override
  String addConditionToTooth(int number) {
    return 'Add condition to tooth $number';
  }

  @override
  String get selectToothFirst => 'Select a tooth first.';

  @override
  String addConditionTitle(int number) {
    return 'Add condition — tooth $number';
  }

  @override
  String get conditionLabel => 'Condition';

  @override
  String get surfaceLabel => 'Surface';

  @override
  String get clinicalNoteOptional => 'Clinical note (optional)';

  @override
  String get saveConditionLabel => 'Save condition';

  @override
  String get resolveConditionQuestion => 'Resolve condition?';

  @override
  String resolveConditionExplanation(String condition, int number) {
    return '$condition on tooth $number will remain in the patient history.';
  }

  @override
  String get resolveLabel => 'Resolve';

  @override
  String get markEntryErrorTitle => 'Mark entry as error';

  @override
  String get entryErrorReasonLabel => 'Why is this entry incorrect?';

  @override
  String get preserveAsErrorLabel => 'Preserve as error';

  @override
  String get selectToothReview =>
      'Select a tooth to review its active conditions.';

  @override
  String healthyToothMessage(int number) {
    return 'Tooth $number is healthy. No active condition is recorded.';
  }

  @override
  String toothHealthySemantics(int number) {
    return 'Tooth $number, healthy';
  }

  @override
  String toothConditionsSemantics(int number, int count) {
    return 'Tooth $number, $count active conditions';
  }

  @override
  String get markAsErrorLabel => 'Mark as error';

  @override
  String get conditionHistoryTitle => 'Condition history';

  @override
  String recordedItemsValue(int count) {
    return '$count recorded items';
  }

  @override
  String get noDentalHistory => 'No Dental Chart history has been recorded.';

  @override
  String get loadMoreHistoryLabel => 'Load more history';

  @override
  String get dentalRoleRestricted =>
      'Dental Chart clinical details are not available for your role.';

  @override
  String get surfaceWhole => 'Whole tooth';

  @override
  String get surfaceMesial => 'Mesial';

  @override
  String get surfaceDistal => 'Distal';

  @override
  String get surfaceOcclusal => 'Occlusal';

  @override
  String get surfaceBuccal => 'Buccal';

  @override
  String get surfaceLingual => 'Lingual';

  @override
  String get conditionCaries => 'Caries';

  @override
  String get conditionFilling => 'Filling';

  @override
  String get conditionCrown => 'Crown';

  @override
  String get conditionRootCanal => 'Root canal';

  @override
  String get conditionFracture => 'Fracture';

  @override
  String get conditionMissing => 'Missing';

  @override
  String get conditionExtraction => 'Extraction required';

  @override
  String get conditionImplant => 'Implant';

  @override
  String get conditionStatusActive => 'Active';

  @override
  String get conditionStatusResolved => 'Resolved';

  @override
  String get conditionStatusError => 'Entered in error';

  @override
  String get odontogramForbiddenIssue =>
      'Your role cannot change Dental Chart conditions.';

  @override
  String get odontogramUnavailableIssue =>
      'This patient or condition is no longer available.';

  @override
  String get odontogramInvalidInputIssue =>
      'Check the tooth, surface, and condition details.';

  @override
  String get missingToothConflictIssue =>
      'Resolve or correct the existing natural-tooth condition before recording this tooth as missing.';

  @override
  String get duplicateConditionIssue =>
      'This active condition is already recorded for the selected tooth surface.';

  @override
  String get conditionNotActiveIssue =>
      'This condition is already closed and remains in history.';

  @override
  String get validAmountValidation => 'Enter a valid amount.';

  @override
  String get quantityRangeValidation => 'Enter a quantity from 0.01 to 999.99.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get moreLabel => 'More';

  @override
  String get workspaceNavigationLabel => 'Workspace navigation';

  @override
  String get themeSystemLabel => 'System theme';

  @override
  String get languageSystemLabel => 'System language';

  @override
  String get clinicSectionTitle => 'Clinic';

  @override
  String get privacySectionTitle => 'Privacy';

  @override
  String get accountSectionTitle => 'Account';

  @override
  String get applicationSectionTitle => 'Application';

  @override
  String get developmentMvpLabel => 'Development MVP · fictional data only';

  @override
  String get currentRoleLabel => 'Your role';

  @override
  String get patientNumberLabel => 'Patient number';

  @override
  String get patientNameLabel => 'Patient';

  @override
  String get statusLabel => 'Status';

  @override
  String get todayLabel => 'Today';

  @override
  String get noAppointmentsDay => 'No appointments scheduled for this day.';

  @override
  String get dentitionLabel => 'Dentition';

  @override
  String get quadrantUpperRight => 'Upper Right (UR)';

  @override
  String get quadrantUpperLeft => 'Upper Left (UL)';

  @override
  String get quadrantLowerRight => 'Lower Right (LR)';

  @override
  String get quadrantLowerLeft => 'Lower Left (LL)';

  @override
  String get dentalMidline => 'Midline';

  @override
  String get maxillaUpperJaw => 'Upper Jaw (Maxilla)';

  @override
  String get mandibleLowerJaw => 'Lower Jaw (Mandible)';

  @override
  String get visitReasonLabel => 'Reason for visit';

  @override
  String get quickReasonCheckup => 'Routine Checkup';

  @override
  String get quickReasonCleaning => 'Cleaning / Scaling';

  @override
  String get quickReasonToothache => 'Toothache / Emergency';

  @override
  String get quickReasonConsultation => 'Consultation';

  @override
  String get quickReasonFollowUp => 'Follow-up';

  @override
  String doctorWorkingHours(String hours) {
    return 'Working hours: $hours';
  }

  @override
  String get doctorOffDuty => 'Doctor has no scheduled hours on this day';

  @override
  String get doctorOnLeave => 'Doctor is on leave on this date';

  @override
  String get changePatientLabel => 'Change patient';

  @override
  String get overrideScheduleQuestion =>
      'Override doctor schedule conflict (Owner only)';

  @override
  String get selectedPatientCardTitle => 'Selected patient';

  @override
  String get doctorNoScheduleConfigured =>
      'Doctor has no working schedule configured in this clinic';

  @override
  String timeOutsideWorkingHours(String time, String hours) {
    return 'Selected time ($time) is outside doctor\'s working hours ($hours)';
  }

  @override
  String get appointmentConflictExplanation =>
      'This appointment conflicts with the doctor\'s schedule (off-duty, on leave, or outside working hours). As clinic owner, please enter an override reason above to confirm.';

  @override
  String get middleNameLabel => 'Middle / Father\'s name';

  @override
  String get administrativeNotesLabel => 'Administrative / Clinic notes';

  @override
  String get personalInformationSection => 'Personal Information';

  @override
  String get contactInformationSection => 'Contact Information';

  @override
  String get birthAndAgeSection => 'Birth Date & Age';

  @override
  String get selectBirthDateLabel => 'Select birth date';

  @override
  String get guardianInformationSection => 'Parent / Guardian Contact (Minor)';

  @override
  String get newPatientShortcut => '+ Register New Patient';

  @override
  String yearsOldValue(int age) {
    return '$age years old';
  }

  @override
  String get ageInYearsLabel => 'Age in years';

  @override
  String get clinicalHubTitle => 'Clinical Records & Treatment';

  @override
  String get administrativeHubTitle => 'Administration & Appointments';

  @override
  String get bookAppointmentLabel => 'Book Appointment';

  @override
  String get minorBadge => 'Minor';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get copyLabel => 'Copy';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String appointmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appointments',
      one: '1 appointment',
      zero: 'No appointments',
    );
    return '$_temp0';
  }

  @override
  String get viewProfileLabel => 'Profile';

  @override
  String get preparationNoteBadge => 'Prep Note';

  @override
  String get overrideBadge => 'Override';

  @override
  String get emptyCalendarTitle => 'No appointments scheduled';

  @override
  String get emptyCalendarHelp =>
      'Use the button below or switch dates to view or schedule appointments.';

  @override
  String get medicalAlertsTitle => 'Medical & Allergy Alerts';

  @override
  String get noKnownAllergies => 'No known drug allergies or medical alerts';

  @override
  String get unscreenedMedicalHelp =>
      'No medical history recorded yet. Complete medical screening before clinical procedures.';

  @override
  String get screenMedicalLabel => 'Screen medical history';

  @override
  String get whatsAppLabel => 'WhatsApp';

  @override
  String get callLabel => 'Call';

  @override
  String get emailActionLabel => 'Send email';

  @override
  String get sendWhatsAppReminder => 'WhatsApp reminder';

  @override
  String reminderMessageTemplate(
    String patientName,
    String clinicName,
    String dentistName,
    String date,
    String time,
  ) {
    return 'Hello $patientName, this is a reminder from $clinicName. You have a dental appointment with Dr. $dentistName on $date at $time. Please reply to this message to confirm your appointment. Thank you!';
  }

  @override
  String get noPhoneForPatient =>
      'No phone number registered for this patient.';

  @override
  String get communicationLaunchFailed => 'Could not launch application.';

  @override
  String get loadStandardProcedures => 'Load standard procedures';

  @override
  String get loadStandardProceduresHelp =>
      'Quickly add standard dental procedures to your catalogue.';

  @override
  String loadStandardProceduresConfirm(int count) {
    return 'This will add $count standard dental procedures to your clinic catalogue. You can customize prices and durations anytime. Continue?';
  }

  @override
  String get searchProceduresPlaceholder =>
      'Search procedures or categories...';

  @override
  String get allCategoriesLabel => 'All categories';

  @override
  String get activeOnlyFilter => 'Active only';

  @override
  String totalProceduresCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count procedures',
      one: '1 procedure',
    );
    return '$_temp0';
  }

  @override
  String activeProceduresCount(int count) {
    return '$count active';
  }

  @override
  String categoriesCount(int count) {
    return '$count categories';
  }

  @override
  String standardProceduresImported(int count) {
    return 'Successfully imported $count standard procedures.';
  }

  @override
  String get noMatchingProcedures =>
      'No procedures match your search or filter.';

  @override
  String get clearFiltersLabel => 'Clear filters';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String toothTreatmentsTitle(int toothNumber) {
    return 'Treatments for Tooth $toothNumber';
  }

  @override
  String get noTreatmentsPlannedForTooth =>
      'No treatments currently planned for this tooth.';

  @override
  String get suggestedTreatmentsTitle => 'Suggested Procedures';

  @override
  String get addTreatmentForTooth => 'Add Planned Treatment';

  @override
  String get scheduleAppointmentForTooth => 'Schedule Appointment';

  @override
  String get scheduleThisProcedure => 'Book Appointment';

  @override
  String get procedureAddedToPlan => 'Procedure added to treatment plan.';

  @override
  String get selectProcedureToAdd => 'Select Procedure from Catalogue';
}
