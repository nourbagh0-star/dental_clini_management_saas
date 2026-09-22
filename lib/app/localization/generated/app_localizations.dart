import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @createStaffAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Create staff account'**
  String get createStaffAccountLabel;

  /// No description provided for @createStaffAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the staff member\'s email and a temporary password (15–128 characters). Share the login details privately. They must change the password before accessing the clinic. No email will be sent.'**
  String get createStaffAccountHelp;

  /// No description provided for @temporaryPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Temporary password'**
  String get temporaryPasswordLabel;

  /// No description provided for @staffAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Staff account created. Share the login details privately. A password change is required at first sign-in.'**
  String get staffAccountCreated;

  /// No description provided for @staffAccountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account could not be created. The email may already be registered, or account creation is temporarily unavailable. Existing accounts were not changed.'**
  String get staffAccountUnavailable;

  /// No description provided for @initialPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your own password'**
  String get initialPasswordTitle;

  /// No description provided for @initialPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Replace the temporary password with a different password of at least 15 characters. Clinic access stays locked until you finish. Then sign in again with your new password.'**
  String get initialPasswordHelp;

  /// No description provided for @emailConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your email is verified. Sign in to continue.'**
  String get emailConfirmed;

  /// No description provided for @invalidConfirmationLink.
  ///
  /// In en, this message translates to:
  /// **'This verification link is invalid or expired. Sign in to request a new link.'**
  String get invalidConfirmationLink;

  /// No description provided for @confirmationLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox and open the verification link, then return to sign in. Wait at least 60 seconds before resending.'**
  String get confirmationLinkSent;

  /// No description provided for @resendLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Resend verification link'**
  String get resendLinkLabel;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DentaFlow'**
  String get appTitle;

  /// No description provided for @demoLabel.
  ///
  /// In en, this message translates to:
  /// **'DEMO WORKSPACE'**
  String get demoLabel;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your clinic, organized.'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'A shared workspace for your dental clinic. Appointment and patient workflows are coming in the next development phases.'**
  String get welcomeBody;

  /// No description provided for @demoNotice.
  ///
  /// In en, this message translates to:
  /// **'Fictional data only. This preview is not ready for real patient records.'**
  String get demoNotice;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Make yourself comfortable'**
  String get appearanceTitle;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @systemLabel.
  ///
  /// In en, this message translates to:
  /// **'Use device settings'**
  String get systemLabel;

  /// No description provided for @lightLabel.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightLabel;

  /// No description provided for @darkLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkLabel;

  /// No description provided for @englishLabel.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLabel;

  /// No description provided for @russianLabel.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get russianLabel;

  /// No description provided for @arabicLabel.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabicLabel;

  /// No description provided for @storageWarning.
  ///
  /// In en, this message translates to:
  /// **'Your preferences could not be saved or restored. You can still use this preview.'**
  String get storageWarning;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page unavailable'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This page is not available in the current preview.'**
  String get notFoundBody;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back to workspace'**
  String get backHome;

  /// No description provided for @startupTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the workspace'**
  String get startupTitle;

  /// No description provided for @startupBody.
  ///
  /// In en, this message translates to:
  /// **'The application could not start. Check the development configuration and try again.'**
  String get startupBody;

  /// No description provided for @configurationBody.
  ///
  /// In en, this message translates to:
  /// **'The development configuration is invalid. Check the environment and public backend settings. Production is not enabled.'**
  String get configurationBody;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryLabel;

  /// No description provided for @networkFailure.
  ///
  /// In en, this message translates to:
  /// **'Connection unavailable. Please try again.'**
  String get networkFailure;

  /// No description provided for @authenticationFailure.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get authenticationFailure;

  /// No description provided for @authorizationFailure.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission for this action.'**
  String get authorizationFailure;

  /// No description provided for @validationFailure.
  ///
  /// In en, this message translates to:
  /// **'Please check the information and try again.'**
  String get validationFailure;

  /// No description provided for @serverFailure.
  ///
  /// In en, this message translates to:
  /// **'The service is temporarily unavailable. Please try again.'**
  String get serverFailure;

  /// No description provided for @notFoundFailure.
  ///
  /// In en, this message translates to:
  /// **'The requested record is unavailable.'**
  String get notFoundFailure;

  /// No description provided for @unknownFailure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get unknownFailure;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @signInLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInLabel;

  /// No description provided for @registerLabel.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerLabel;

  /// No description provided for @forgotLabel.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotLabel;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyTitle;

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get codeLabel;

  /// No description provided for @verifyLabel.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get verifyLabel;

  /// No description provided for @resendLabel.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendLabel;

  /// No description provided for @changeEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmailLabel;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover your account'**
  String get forgotTitle;

  /// No description provided for @sendCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Send recovery code'**
  String get sendCodeLabel;

  /// No description provided for @sendResetLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLinkLabel;

  /// No description provided for @recoveryLinkSent.
  ///
  /// In en, this message translates to:
  /// **'If this account exists, open the password-reset link in your email to choose a new password.'**
  String get recoveryLinkSent;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetTitle;

  /// No description provided for @resetLabel.
  ///
  /// In en, this message translates to:
  /// **'Save new password'**
  String get resetLabel;

  /// No description provided for @lockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspace locked'**
  String get lockedTitle;

  /// No description provided for @lockedBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to unlock your account.'**
  String get lockedBody;

  /// No description provided for @unlockLabel.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockLabel;

  /// No description provided for @switchAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Switch account'**
  String get switchAccountLabel;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready'**
  String get accountTitle;

  /// No description provided for @accountBody.
  ///
  /// In en, this message translates to:
  /// **'Clinic setup will be available in the next phase. Your account has no clinic role yet.'**
  String get accountBody;

  /// No description provided for @lockLabel.
  ///
  /// In en, this message translates to:
  /// **'Lock workspace'**
  String get lockLabel;

  /// No description provided for @logoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutLabel;

  /// No description provided for @backLoginLabel.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backLoginLabel;

  /// No description provided for @passwordHelp.
  ///
  /// In en, this message translates to:
  /// **'Use at least 15 characters. Spaces and password managers are welcome.'**
  String get passwordHelp;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @passwordShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 15 characters.'**
  String get passwordShort;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords must match.'**
  String get passwordMismatch;

  /// No description provided for @invalidCodeInput.
  ///
  /// In en, this message translates to:
  /// **'Enter the six-digit email code.'**
  String get invalidCodeInput;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @authCredentials.
  ///
  /// In en, this message translates to:
  /// **'The credentials could not be verified. Please try again.'**
  String get authCredentials;

  /// No description provided for @authUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email before signing in.'**
  String get authUnconfirmed;

  /// No description provided for @authInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'This code is invalid or expired. Request a new one.'**
  String get authInvalidCode;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'This password does not meet the server requirements.'**
  String get authWeakPassword;

  /// No description provided for @authRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait before trying again.'**
  String get authRateLimited;

  /// No description provided for @authStorage.
  ///
  /// In en, this message translates to:
  /// **'Session storage is unavailable. Access remains blocked; check browser or device storage settings.'**
  String get authStorage;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Authentication is not configured. Open the configured development build.'**
  String get authUnavailable;

  /// No description provided for @authRevocation.
  ///
  /// In en, this message translates to:
  /// **'Signed out on this device. Server session revocation could not be confirmed.'**
  String get authRevocation;

  /// No description provided for @authResetPartial.
  ///
  /// In en, this message translates to:
  /// **'Password changed, but revoking all sessions could not be confirmed. Sign in again; other sessions may still be active.'**
  String get authResetPartial;

  /// No description provided for @authResetDone.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Please sign in again.'**
  String get authResetDone;

  /// No description provided for @authCodeSent.
  ///
  /// In en, this message translates to:
  /// **'If this address is eligible, an email code has been sent. Check your inbox. Codes expire after one hour; wait at least 60 seconds before resending.'**
  String get authCodeSent;

  /// No description provided for @restoringTitle.
  ///
  /// In en, this message translates to:
  /// **'Checking your session'**
  String get restoringTitle;

  /// No description provided for @restoreFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Session could not be restored'**
  String get restoreFailedTitle;

  /// No description provided for @privacyHidden.
  ///
  /// In en, this message translates to:
  /// **'Workspace hidden'**
  String get privacyHidden;

  /// No description provided for @authSettings.
  ///
  /// In en, this message translates to:
  /// **'Appearance and language'**
  String get authSettings;

  /// No description provided for @continueAuth.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account'**
  String get continueAuth;

  /// No description provided for @clinicSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your clinic'**
  String get clinicSetupTitle;

  /// No description provided for @clinicSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Create your first clinic to begin using DentaFlow. You can create more clinics later.'**
  String get clinicSetupBody;

  /// No description provided for @createClinicLabel.
  ///
  /// In en, this message translates to:
  /// **'Create clinic'**
  String get createClinicLabel;

  /// No description provided for @clinicNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Clinic name'**
  String get clinicNameLabel;

  /// No description provided for @clinicNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Use the name staff and patients recognize.'**
  String get clinicNameHelp;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @timeZoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get timeZoneLabel;

  /// No description provided for @timeZoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Prefilled from this device. Change it if the clinic operates elsewhere.'**
  String get timeZoneHelp;

  /// No description provided for @selectClinicTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a clinic'**
  String get selectClinicTitle;

  /// No description provided for @selectClinicBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the clinic you want to work in. You can switch clinics later.'**
  String get selectClinicBody;

  /// No description provided for @currentClinicTitle.
  ///
  /// In en, this message translates to:
  /// **'Clinic selected'**
  String get currentClinicTitle;

  /// No description provided for @currentClinicBody.
  ///
  /// In en, this message translates to:
  /// **'Active workspace: {clinicName}. Select an action below or proceed directly to your dashboard.'**
  String currentClinicBody(Object clinicName);

  /// No description provided for @switchClinicLabel.
  ///
  /// In en, this message translates to:
  /// **'Switch clinic'**
  String get switchClinicLabel;

  /// No description provided for @addClinicLabel.
  ///
  /// In en, this message translates to:
  /// **'Add another clinic'**
  String get addClinicLabel;

  /// No description provided for @clinicLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading your clinics'**
  String get clinicLoadTitle;

  /// No description provided for @clinicLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not load your clinics. Try again.'**
  String get clinicLoadFailed;

  /// No description provided for @timeZoneUtc.
  ///
  /// In en, this message translates to:
  /// **'UTC'**
  String get timeZoneUtc;

  /// No description provided for @visitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get visitsTitle;

  /// No description provided for @newSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get newSessionLabel;

  /// No description provided for @noVisitsMessage.
  ///
  /// In en, this message translates to:
  /// **'No clinical visits yet.'**
  String get noVisitsMessage;

  /// No description provided for @clinicalViewOnly.
  ///
  /// In en, this message translates to:
  /// **'You have view-only access to clinical sessions.'**
  String get clinicalViewOnly;

  /// No description provided for @linkedAppointmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked appointment'**
  String get linkedAppointmentLabel;

  /// No description provided for @walkInLabel.
  ///
  /// In en, this message translates to:
  /// **'Walk-in visit'**
  String get walkInLabel;

  /// No description provided for @draftStatus.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draftStatus;

  /// No description provided for @finalizedStatus.
  ///
  /// In en, this message translates to:
  /// **'Finalized'**
  String get finalizedStatus;

  /// No description provided for @enteredInErrorStatus.
  ///
  /// In en, this message translates to:
  /// **'Entered in error'**
  String get enteredInErrorStatus;

  /// No description provided for @clinicalNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Clinical notes'**
  String get clinicalNotesLabel;

  /// No description provided for @recommendationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendationsLabel;

  /// No description provided for @saveDraftLabel.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraftLabel;

  /// No description provided for @finalizeSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Finalize session'**
  String get finalizeSessionLabel;

  /// No description provided for @markInErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Mark entered in error'**
  String get markInErrorLabel;

  /// No description provided for @addAmendmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Add amendment'**
  String get addAmendmentLabel;

  /// No description provided for @amendmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Amendments'**
  String get amendmentsTitle;

  /// No description provided for @amendmentTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get amendmentTextLabel;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// No description provided for @selectVisitTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Create clinical session'**
  String get selectVisitTypeTitle;

  /// No description provided for @chooseAppointmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose appointment'**
  String get chooseAppointmentLabel;

  /// No description provided for @chooseDentistLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose dentist'**
  String get chooseDentistLabel;

  /// No description provided for @visitDateTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit date and time'**
  String get visitDateTimeLabel;

  /// No description provided for @createDraftLabel.
  ///
  /// In en, this message translates to:
  /// **'Create draft'**
  String get createDraftLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @loadMoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMoreLabel;

  /// No description provided for @reloadLatestLabel.
  ///
  /// In en, this message translates to:
  /// **'Reload latest draft'**
  String get reloadLatestLabel;

  /// No description provided for @revisionConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'Another staff member saved this draft. Reload the latest version before continuing.'**
  String get revisionConflictMessage;

  /// No description provided for @sessionUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This clinical session is unavailable.'**
  String get sessionUnavailableMessage;

  /// No description provided for @clinicalActionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'The clinical action could not be completed. Check the session and try again.'**
  String get clinicalActionFailedMessage;

  /// No description provided for @finalizeWarning.
  ///
  /// In en, this message translates to:
  /// **'After finalization, the original clinical record cannot be edited. Corrections require a signed amendment.'**
  String get finalizeWarning;

  /// No description provided for @originalRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Original clinical record'**
  String get originalRecordTitle;

  /// No description provided for @appointmentSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Appointment visit'**
  String get appointmentSessionLabel;

  /// No description provided for @sessionDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Session date'**
  String get sessionDateLabel;

  /// No description provided for @assignedDentistLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned dentist'**
  String get assignedDentistLabel;

  /// No description provided for @lastSavedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last saved'**
  String get lastSavedLabel;

  /// No description provided for @openClinicalSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Open clinical session'**
  String get openClinicalSessionLabel;

  /// No description provided for @patientFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Patient files'**
  String get patientFilesTitle;

  /// No description provided for @uploadFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload file'**
  String get uploadFileLabel;

  /// No description provided for @noPatientFilesMessage.
  ///
  /// In en, this message translates to:
  /// **'No patient files yet.'**
  String get noPatientFilesMessage;

  /// No description provided for @patientFilesViewOnly.
  ///
  /// In en, this message translates to:
  /// **'You have view-only access to patient files.'**
  String get patientFilesViewOnly;

  /// No description provided for @includeArchivedFilesLabel.
  ///
  /// In en, this message translates to:
  /// **'Show archived files'**
  String get includeArchivedFilesLabel;

  /// No description provided for @allFileCategoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allFileCategoriesLabel;

  /// No description provided for @fileCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fileCategoryLabel;

  /// No description provided for @fileCategoryXray.
  ///
  /// In en, this message translates to:
  /// **'X-ray'**
  String get fileCategoryXray;

  /// No description provided for @fileCategoryClinicalPhoto.
  ///
  /// In en, this message translates to:
  /// **'Clinical photo'**
  String get fileCategoryClinicalPhoto;

  /// No description provided for @fileCategoryConsent.
  ///
  /// In en, this message translates to:
  /// **'Consent'**
  String get fileCategoryConsent;

  /// No description provided for @fileCategoryReferral.
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get fileCategoryReferral;

  /// No description provided for @fileCategoryLaboratory.
  ///
  /// In en, this message translates to:
  /// **'Laboratory result'**
  String get fileCategoryLaboratory;

  /// No description provided for @fileCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get fileCategoryOther;

  /// No description provided for @fileDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get fileDescriptionLabel;

  /// No description provided for @chooseFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose JPG, PNG, or PDF'**
  String get chooseFileLabel;

  /// No description provided for @fileTypeHelp.
  ///
  /// In en, this message translates to:
  /// **'Maximum 15 MB. Demo files only.'**
  String get fileTypeHelp;

  /// No description provided for @fileSelectionInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid JPG, PNG, or PDF file up to 15 MB.'**
  String get fileSelectionInvalid;

  /// No description provided for @uploadingFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Uploading file'**
  String get uploadingFileLabel;

  /// No description provided for @validatingFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Validating file securely…'**
  String get validatingFileLabel;

  /// No description provided for @cancelUploadLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel upload'**
  String get cancelUploadLabel;

  /// No description provided for @openFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get openFileLabel;

  /// No description provided for @openPdfLabel.
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get openPdfLabel;

  /// No description provided for @archiveFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Archive file'**
  String get archiveFileLabel;

  /// No description provided for @restoreFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Restore file'**
  String get restoreFileLabel;

  /// No description provided for @uploadReplacementLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload replacement'**
  String get uploadReplacementLabel;

  /// No description provided for @archiveFileWarning.
  ///
  /// In en, this message translates to:
  /// **'The file will remain stored and auditable. Enter a reason to archive it.'**
  String get archiveFileWarning;

  /// No description provided for @archivedFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedFileLabel;

  /// No description provided for @fileUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This patient file is unavailable.'**
  String get fileUnavailableMessage;

  /// No description provided for @fileActionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'The file action could not be completed. Check the file and try again.'**
  String get fileActionFailedMessage;

  /// No description provided for @fileSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get fileSizeLabel;

  /// No description provided for @uploadedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploadedAtLabel;

  /// No description provided for @fileLinkedVisitLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked visit'**
  String get fileLinkedVisitLabel;

  /// No description provided for @patientFilesRestricted.
  ///
  /// In en, this message translates to:
  /// **'Patient files are restricted to authorized clinical staff.'**
  String get patientFilesRestricted;

  /// No description provided for @billingTitle.
  ///
  /// In en, this message translates to:
  /// **'Billing & invoices'**
  String get billingTitle;

  /// No description provided for @newInvoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'New invoice'**
  String get newInvoiceLabel;

  /// No description provided for @noInvoicesMessage.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet.'**
  String get noInvoicesMessage;

  /// No description provided for @billingRestricted.
  ///
  /// In en, this message translates to:
  /// **'Billing is available to authorized billing and clinical staff.'**
  String get billingRestricted;

  /// No description provided for @invoiceDraftLabel.
  ///
  /// In en, this message translates to:
  /// **'Draft invoice'**
  String get invoiceDraftLabel;

  /// No description provided for @invoiceItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice items'**
  String get invoiceItemsTitle;

  /// No description provided for @noInvoiceItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'No procedures have been added.'**
  String get noInvoiceItemsMessage;

  /// No description provided for @addCatalogueItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Add from catalogue'**
  String get addCatalogueItemLabel;

  /// No description provided for @addTreatmentItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Add from treatment plan'**
  String get addTreatmentItemLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @approveContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Approve clinical content'**
  String get approveContentLabel;

  /// No description provided for @reopenContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Reopen clinical content'**
  String get reopenContentLabel;

  /// No description provided for @financialDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial details'**
  String get financialDetailsTitle;

  /// No description provided for @unitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get unitPriceLabel;

  /// No description provided for @discountTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount type'**
  String get discountTypeLabel;

  /// No description provided for @discountNoneLabel.
  ///
  /// In en, this message translates to:
  /// **'No discount'**
  String get discountNoneLabel;

  /// No description provided for @discountFixedLabel.
  ///
  /// In en, this message translates to:
  /// **'Fixed amount'**
  String get discountFixedLabel;

  /// No description provided for @discountPercentageLabel.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get discountPercentageLabel;

  /// No description provided for @discountValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount value'**
  String get discountValueLabel;

  /// No description provided for @taxRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax rate (%)'**
  String get taxRateLabel;

  /// No description provided for @invoiceLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice language'**
  String get invoiceLanguageLabel;

  /// No description provided for @languageEnglishLabel.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishLabel;

  /// No description provided for @languageRussianLabel.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageRussianLabel;

  /// No description provided for @languageArabicLabel.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabicLabel;

  /// No description provided for @saveFinancialsLabel.
  ///
  /// In en, this message translates to:
  /// **'Save financial details'**
  String get saveFinancialsLabel;

  /// No description provided for @finalizeInvoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Finalize invoice'**
  String get finalizeInvoiceLabel;

  /// No description provided for @finalizeInvoiceWarning.
  ///
  /// In en, this message translates to:
  /// **'Finalization assigns a permanent invoice number. The invoice items and prices cannot be edited afterward.'**
  String get finalizeInvoiceWarning;

  /// No description provided for @cancelInvoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel invoice'**
  String get cancelInvoiceLabel;

  /// No description provided for @recordPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPaymentLabel;

  /// No description provided for @paymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get paymentAmountLabel;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethodLabel;

  /// No description provided for @paymentCashLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentCashLabel;

  /// No description provided for @paymentCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentCardLabel;

  /// No description provided for @paymentBankLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get paymentBankLabel;

  /// No description provided for @paymentOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get paymentOtherLabel;

  /// No description provided for @referenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference (optional)'**
  String get referenceLabel;

  /// No description provided for @patientCreditLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient credit'**
  String get patientCreditLabel;

  /// No description provided for @applyCreditLabel.
  ///
  /// In en, this message translates to:
  /// **'Apply credit'**
  String get applyCreditLabel;

  /// No description provided for @paymentHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments & corrections'**
  String get paymentHistoryTitle;

  /// No description provided for @refundLabel.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refundLabel;

  /// No description provided for @correctionLabel.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get correctionLabel;

  /// No description provided for @exportInvoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Open invoice PDF'**
  String get exportInvoiceLabel;

  /// No description provided for @invoiceSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get invoiceSubtotalLabel;

  /// No description provided for @invoiceDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get invoiceDiscountLabel;

  /// No description provided for @invoiceTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get invoiceTaxLabel;

  /// No description provided for @invoiceTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get invoiceTotalLabel;

  /// No description provided for @invoicePaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get invoicePaidLabel;

  /// No description provided for @invoiceDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get invoiceDueLabel;

  /// No description provided for @paymentUnpaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get paymentUnpaidLabel;

  /// No description provided for @paymentPartialLabel.
  ///
  /// In en, this message translates to:
  /// **'Partially paid'**
  String get paymentPartialLabel;

  /// No description provided for @paymentPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paymentPaidLabel;

  /// No description provided for @invoiceCancelledLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get invoiceCancelledLabel;

  /// No description provided for @billingActionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'The billing action could not be completed. Reload the invoice and try again.'**
  String get billingActionFailedMessage;

  /// No description provided for @billingConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'This invoice changed or is no longer eligible for that action. Reload it and try again.'**
  String get billingConflictMessage;

  /// No description provided for @invoicePdfUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'The invoice PDF could not be prepared. Try again.'**
  String get invoicePdfUnavailableMessage;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardActivePatients.
  ///
  /// In en, this message translates to:
  /// **'Active patients'**
  String get dashboardActivePatients;

  /// No description provided for @dashboardAppointmentsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Appointments this week'**
  String get dashboardAppointmentsThisWeek;

  /// No description provided for @dashboardCompletedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Treatments completed this month'**
  String get dashboardCompletedThisMonth;

  /// No description provided for @dashboardOutstandingPayments.
  ///
  /// In en, this message translates to:
  /// **'Outstanding payments'**
  String get dashboardOutstandingPayments;

  /// No description provided for @dashboardOutstandingInvoices.
  ///
  /// In en, this message translates to:
  /// **'{count} outstanding invoices'**
  String dashboardOutstandingInvoices(int count);

  /// No description provided for @dashboardTodayAppointments.
  ///
  /// In en, this message translates to:
  /// **'Today\'s appointments'**
  String get dashboardTodayAppointments;

  /// No description provided for @dashboardUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming appointments'**
  String get dashboardUpcomingAppointments;

  /// No description provided for @dashboardNextSevenDays.
  ///
  /// In en, this message translates to:
  /// **'Next seven days'**
  String get dashboardNextSevenDays;

  /// No description provided for @dashboardNoTodayAppointments.
  ///
  /// In en, this message translates to:
  /// **'No appointments scheduled for today.'**
  String get dashboardNoTodayAppointments;

  /// No description provided for @dashboardNoUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments in the next seven days.'**
  String get dashboardNoUpcomingAppointments;

  /// No description provided for @dashboardViewAllAppointments.
  ///
  /// In en, this message translates to:
  /// **'View all appointments'**
  String get dashboardViewAllAppointments;

  /// No description provided for @dashboardLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {value}'**
  String dashboardLastUpdated(String value);

  /// No description provided for @dashboardTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Clinic time · {value}'**
  String dashboardTimeZone(String value);

  /// No description provided for @dashboardRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh dashboard'**
  String get dashboardRefresh;

  /// No description provided for @dashboardRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'The latest dashboard data could not be loaded. Showing the previous result.'**
  String get dashboardRefreshFailed;

  /// No description provided for @dashboardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The dashboard is temporarily unavailable.'**
  String get dashboardUnavailable;

  /// No description provided for @dashboardNoActiveClinic.
  ///
  /// In en, this message translates to:
  /// **'Choose an active clinic to open its dashboard.'**
  String get dashboardNoActiveClinic;

  /// No description provided for @dashboardOpenPatients.
  ///
  /// In en, this message translates to:
  /// **'Open patients'**
  String get dashboardOpenPatients;

  /// No description provided for @dashboardOpenTreatments.
  ///
  /// In en, this message translates to:
  /// **'Open treatments'**
  String get dashboardOpenTreatments;

  /// No description provided for @dashboardOpenBilling.
  ///
  /// In en, this message translates to:
  /// **'Open billing'**
  String get dashboardOpenBilling;

  /// No description provided for @appointmentStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get appointmentStatusScheduled;

  /// No description provided for @appointmentStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get appointmentStatusConfirmed;

  /// No description provided for @appointmentStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get appointmentStatusInProgress;

  /// No description provided for @appointmentStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get appointmentStatusCompleted;

  /// No description provided for @appointmentStatusNoShow.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get appointmentStatusNoShow;

  /// No description provided for @appointmentStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get appointmentStatusCancelled;

  /// No description provided for @auditTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get auditTitle;

  /// No description provided for @auditOpen.
  ///
  /// In en, this message translates to:
  /// **'Open audit log'**
  String get auditOpen;

  /// No description provided for @auditRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh audit log'**
  String get auditRefresh;

  /// No description provided for @auditUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The audit log is temporarily unavailable.'**
  String get auditUnavailable;

  /// No description provided for @auditOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only an active clinic owner can view the audit log.'**
  String get auditOwnerOnly;

  /// No description provided for @auditNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No recorded activity in this date range.'**
  String get auditNoEvents;

  /// No description provided for @auditNoFilterResults.
  ///
  /// In en, this message translates to:
  /// **'No activity matches these filters.'**
  String get auditNoFilterResults;

  /// No description provided for @auditFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get auditFilters;

  /// No description provided for @auditClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get auditClearFilters;

  /// No description provided for @auditDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get auditDateRange;

  /// No description provided for @auditEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get auditEmployee;

  /// No description provided for @auditAllEmployees.
  ///
  /// In en, this message translates to:
  /// **'All employees'**
  String get auditAllEmployees;

  /// No description provided for @auditCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get auditCategory;

  /// No description provided for @auditAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get auditAllCategories;

  /// No description provided for @auditEntityType.
  ///
  /// In en, this message translates to:
  /// **'Entity type'**
  String get auditEntityType;

  /// No description provided for @auditAllEntities.
  ///
  /// In en, this message translates to:
  /// **'All entities'**
  String get auditAllEntities;

  /// No description provided for @auditLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get auditLoadMore;

  /// No description provided for @auditDetails.
  ///
  /// In en, this message translates to:
  /// **'Event details'**
  String get auditDetails;

  /// No description provided for @auditOccurredAt.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get auditOccurredAt;

  /// No description provided for @auditAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get auditAction;

  /// No description provided for @auditEntity.
  ///
  /// In en, this message translates to:
  /// **'Entity'**
  String get auditEntity;

  /// No description provided for @auditReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get auditReason;

  /// No description provided for @auditNoReason.
  ///
  /// In en, this message translates to:
  /// **'No reason recorded'**
  String get auditNoReason;

  /// No description provided for @auditActorRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles at the time'**
  String get auditActorRoles;

  /// No description provided for @auditFormerActor.
  ///
  /// In en, this message translates to:
  /// **'Former or unavailable staff member'**
  String get auditFormerActor;

  /// No description provided for @auditCategoryAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get auditCategoryAccess;

  /// No description provided for @auditCategoryPatient.
  ///
  /// In en, this message translates to:
  /// **'Patient administration'**
  String get auditCategoryPatient;

  /// No description provided for @auditCategoryScheduling.
  ///
  /// In en, this message translates to:
  /// **'Scheduling'**
  String get auditCategoryScheduling;

  /// No description provided for @auditCategoryClinical.
  ///
  /// In en, this message translates to:
  /// **'Clinical'**
  String get auditCategoryClinical;

  /// No description provided for @auditCategoryFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get auditCategoryFinancial;

  /// No description provided for @auditCategoryStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff and security'**
  String get auditCategoryStaff;

  /// No description provided for @auditOtherAction.
  ///
  /// In en, this message translates to:
  /// **'Other recorded action'**
  String get auditOtherAction;

  /// No description provided for @auditOpenRecord.
  ///
  /// In en, this message translates to:
  /// **'Open related record'**
  String get auditOpenRecord;

  /// No description provided for @auditShowingRange.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to} · {timeZone}'**
  String auditShowingRange(String from, String to, String timeZone);

  /// No description provided for @auditRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'The latest audit activity could not be loaded. Showing the previous result.'**
  String get auditRefreshFailed;

  /// No description provided for @auditActionAccess.
  ///
  /// In en, this message translates to:
  /// **'Sensitive access recorded'**
  String get auditActionAccess;

  /// No description provided for @auditActionPatient.
  ///
  /// In en, this message translates to:
  /// **'Patient administration changed'**
  String get auditActionPatient;

  /// No description provided for @auditActionScheduling.
  ///
  /// In en, this message translates to:
  /// **'Schedule or appointment changed'**
  String get auditActionScheduling;

  /// No description provided for @auditActionClinical.
  ///
  /// In en, this message translates to:
  /// **'Clinical record changed'**
  String get auditActionClinical;

  /// No description provided for @auditActionFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial record changed'**
  String get auditActionFinancial;

  /// No description provided for @auditActionStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff or security changed'**
  String get auditActionStaff;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleDentist.
  ///
  /// In en, this message translates to:
  /// **'Dentist'**
  String get roleDentist;

  /// No description provided for @roleAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get roleAssistant;

  /// No description provided for @roleReceptionist.
  ///
  /// In en, this message translates to:
  /// **'Receptionist'**
  String get roleReceptionist;

  /// No description provided for @auditResultCount.
  ///
  /// In en, this message translates to:
  /// **'Result count'**
  String get auditResultCount;

  /// No description provided for @auditApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get auditApplyFilters;

  /// No description provided for @appointmentsWithTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Appointments · {timeZone}'**
  String appointmentsWithTimeZone(String timeZone);

  /// No description provided for @previousWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get previousWeekLabel;

  /// No description provided for @nextWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get nextWeekLabel;

  /// No description provided for @newAppointmentLabel.
  ///
  /// In en, this message translates to:
  /// **'New appointment'**
  String get newAppointmentLabel;

  /// No description provided for @noAppointmentsWeek.
  ///
  /// In en, this message translates to:
  /// **'No appointments in this week.'**
  String get noAppointmentsWeek;

  /// No description provided for @chooseClinicFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a clinic first.'**
  String get chooseClinicFirst;

  /// No description provided for @clinicTimeZoneValue.
  ///
  /// In en, this message translates to:
  /// **'Clinic time zone: {timeZone}'**
  String clinicTimeZoneValue(String timeZone);

  /// No description provided for @findPatientLabel.
  ///
  /// In en, this message translates to:
  /// **'Find patient by name, phone, email, or number'**
  String get findPatientLabel;

  /// No description provided for @patientSelectedValue.
  ///
  /// In en, this message translates to:
  /// **'Patient selected: {patientId}'**
  String patientSelectedValue(String patientId);

  /// No description provided for @dentistLabel.
  ///
  /// In en, this message translates to:
  /// **'Dentist'**
  String get dentistLabel;

  /// No description provided for @chooseDentistValidation.
  ///
  /// In en, this message translates to:
  /// **'Choose a dentist'**
  String get chooseDentistValidation;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTimeLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @minutesValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String minutesValue(int minutes);

  /// No description provided for @appointmentPurposeOptional.
  ///
  /// In en, this message translates to:
  /// **'Purpose (optional, non-clinical)'**
  String get appointmentPurposeOptional;

  /// No description provided for @ownerOverrideOptional.
  ///
  /// In en, this message translates to:
  /// **'Owner override reason (only when needed)'**
  String get ownerOverrideOptional;

  /// No description provided for @createAppointmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Create appointment'**
  String get createAppointmentLabel;

  /// No description provided for @rescheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get rescheduleLabel;

  /// No description provided for @confirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmLabel;

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startLabel;

  /// No description provided for @completeLabel.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeLabel;

  /// No description provided for @markNoShowLabel.
  ///
  /// In en, this message translates to:
  /// **'Mark no-show'**
  String get markNoShowLabel;

  /// No description provided for @preparationNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Preparation note'**
  String get preparationNoteLabel;

  /// No description provided for @ownerOverrideReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner override reason'**
  String get ownerOverrideReasonTitle;

  /// No description provided for @overrideConflictHelp.
  ///
  /// In en, this message translates to:
  /// **'Only needed if the new time conflicts'**
  String get overrideConflictHelp;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @useReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Use reason'**
  String get useReasonLabel;

  /// No description provided for @operationalPreparationNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Operational preparation note'**
  String get operationalPreparationNoteTitle;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @cancellationReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get cancellationReasonTitle;

  /// No description provided for @appointmentUnavailableIssue.
  ///
  /// In en, this message translates to:
  /// **'The patient or appointment is unavailable.'**
  String get appointmentUnavailableIssue;

  /// No description provided for @appointmentForbiddenIssue.
  ///
  /// In en, this message translates to:
  /// **'Your role cannot perform this appointment action.'**
  String get appointmentForbiddenIssue;

  /// No description provided for @appointmentPatientOverlapIssue.
  ///
  /// In en, this message translates to:
  /// **'This patient already has an overlapping appointment.'**
  String get appointmentPatientOverlapIssue;

  /// No description provided for @appointmentDentistOverlapIssue.
  ///
  /// In en, this message translates to:
  /// **'The dentist already has an overlapping appointment.'**
  String get appointmentDentistOverlapIssue;

  /// No description provided for @appointmentWorkingHoursIssue.
  ///
  /// In en, this message translates to:
  /// **'This time is outside the dentist working hours.'**
  String get appointmentWorkingHoursIssue;

  /// No description provided for @appointmentLeaveIssue.
  ///
  /// In en, this message translates to:
  /// **'The dentist is on leave at this time.'**
  String get appointmentLeaveIssue;

  /// No description provided for @appointmentUnavailablePeriodIssue.
  ///
  /// In en, this message translates to:
  /// **'The dentist is unavailable at this time.'**
  String get appointmentUnavailablePeriodIssue;

  /// No description provided for @appointmentOverrideRequiredIssue.
  ///
  /// In en, this message translates to:
  /// **'An Owner must add a reason to override this conflict.'**
  String get appointmentOverrideRequiredIssue;

  /// No description provided for @appointmentInvalidTransitionIssue.
  ///
  /// In en, this message translates to:
  /// **'This appointment status cannot be changed that way.'**
  String get appointmentInvalidTransitionIssue;

  /// No description provided for @patientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patientsTitle;

  /// No description provided for @newPatientLabel.
  ///
  /// In en, this message translates to:
  /// **'New patient'**
  String get newPatientLabel;

  /// No description provided for @searchPatientLabel.
  ///
  /// In en, this message translates to:
  /// **'Search name, phone, email, or number'**
  String get searchPatientLabel;

  /// No description provided for @archivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedLabel;

  /// No description provided for @patientActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This patient action is not available.'**
  String get patientActionUnavailable;

  /// No description provided for @noPatientsFound.
  ///
  /// In en, this message translates to:
  /// **'No patients found.'**
  String get noPatientsFound;

  /// No description provided for @noContactLabel.
  ///
  /// In en, this message translates to:
  /// **'No contact'**
  String get noContactLabel;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @birthDateInformationLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth date information'**
  String get birthDateInformationLabel;

  /// No description provided for @birthPrecisionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get birthPrecisionUnknown;

  /// No description provided for @birthPrecisionExact.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get birthPrecisionExact;

  /// No description provided for @birthPrecisionApproximate.
  ///
  /// In en, this message translates to:
  /// **'Approximate'**
  String get birthPrecisionApproximate;

  /// No description provided for @birthDateFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth date (YYYY-MM-DD)'**
  String get birthDateFormatLabel;

  /// No description provided for @approximateAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Approximate age in years'**
  String get approximateAgeLabel;

  /// No description provided for @ageAssessedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Age assessed on (YYYY-MM-DD)'**
  String get ageAssessedOnLabel;

  /// No description provided for @knownMinorLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient is known to be under 18'**
  String get knownMinorLabel;

  /// No description provided for @guardianNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Guardian name'**
  String get guardianNameLabel;

  /// No description provided for @guardianPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Guardian phone'**
  String get guardianPhoneLabel;

  /// No description provided for @guardianEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Guardian email'**
  String get guardianEmailLabel;

  /// No description provided for @createPatientLabel.
  ///
  /// In en, this message translates to:
  /// **'Create patient'**
  String get createPatientLabel;

  /// No description provided for @patientProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Patient profile'**
  String get patientProfileTitle;

  /// No description provided for @patientProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Patient profile is unavailable. Return to search and select the patient again.'**
  String get patientProfileUnavailable;

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactTitle;

  /// No description provided for @medicalProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical profile'**
  String get medicalProfileTitle;

  /// No description provided for @appointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointmentsTitle;

  /// No description provided for @dentalChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Dental Chart'**
  String get dentalChartTitle;

  /// No description provided for @treatmentPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Treatment plans'**
  String get treatmentPlansTitle;

  /// No description provided for @restorePatientLabel.
  ///
  /// In en, this message translates to:
  /// **'Restore patient'**
  String get restorePatientLabel;

  /// No description provided for @archivePatientLabel.
  ///
  /// In en, this message translates to:
  /// **'Archive patient'**
  String get archivePatientLabel;

  /// No description provided for @birthInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Birth information'**
  String get birthInformationTitle;

  /// No description provided for @approximatelyYearsValue.
  ///
  /// In en, this message translates to:
  /// **'Approximately {years} years'**
  String approximatelyYearsValue(int years);

  /// No description provided for @archivePatientQuestion.
  ///
  /// In en, this message translates to:
  /// **'Archive patient?'**
  String get archivePatientQuestion;

  /// No description provided for @restorePatientQuestion.
  ///
  /// In en, this message translates to:
  /// **'Restore patient?'**
  String get restorePatientQuestion;

  /// No description provided for @archivePatientExplanation.
  ///
  /// In en, this message translates to:
  /// **'Archived patients remain in the clinic record and can be restored by an owner.'**
  String get archivePatientExplanation;

  /// No description provided for @restorePatientExplanation.
  ///
  /// In en, this message translates to:
  /// **'This returns the patient to the active clinic record.'**
  String get restorePatientExplanation;

  /// No description provided for @archiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveLabel;

  /// No description provided for @restoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreLabel;

  /// No description provided for @medicalRoleRestricted.
  ///
  /// In en, this message translates to:
  /// **'Medical information is not available for your role.'**
  String get medicalRoleRestricted;

  /// No description provided for @allergiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergiesLabel;

  /// No description provided for @currentMedicationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Current medications'**
  String get currentMedicationsLabel;

  /// No description provided for @chronicConditionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Chronic conditions'**
  String get chronicConditionsLabel;

  /// No description provided for @importantMedicalNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Important medical notes'**
  String get importantMedicalNotesLabel;

  /// No description provided for @saveMedicalProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Save medical profile'**
  String get saveMedicalProfileLabel;

  /// No description provided for @staffTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staffTitle;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @inviteStaffLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite staff'**
  String get inviteStaffLabel;

  /// No description provided for @staffOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only clinic owners can manage staff.'**
  String get staffOwnerOnly;

  /// No description provided for @manageStaffDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage roles and access for this clinic.'**
  String get manageStaffDescription;

  /// No description provided for @webInvitationOnly.
  ///
  /// In en, this message translates to:
  /// **'Send invitations from the Web workspace.'**
  String get webInvitationOnly;

  /// No description provided for @verifiedEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified email'**
  String get verifiedEmailLabel;

  /// No description provided for @sendInvitationLabel.
  ///
  /// In en, this message translates to:
  /// **'Send invitation'**
  String get sendInvitationLabel;

  /// No description provided for @saveRolesLabel.
  ///
  /// In en, this message translates to:
  /// **'Save roles'**
  String get saveRolesLabel;

  /// No description provided for @reactivateStaffQuestion.
  ///
  /// In en, this message translates to:
  /// **'Reactivate staff member?'**
  String get reactivateStaffQuestion;

  /// No description provided for @deactivateStaffQuestion.
  ///
  /// In en, this message translates to:
  /// **'Deactivate staff member?'**
  String get deactivateStaffQuestion;

  /// No description provided for @reactivateLabel.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivateLabel;

  /// No description provided for @deactivateLabel.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivateLabel;

  /// No description provided for @confirmPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPasswordTitle;

  /// No description provided for @invalidInvitationLink.
  ///
  /// In en, this message translates to:
  /// **'This invitation link is invalid or unavailable.'**
  String get invalidInvitationLink;

  /// No description provided for @joinClinicTitle.
  ///
  /// In en, this message translates to:
  /// **'Join clinic'**
  String get joinClinicTitle;

  /// No description provided for @acceptInvitationHelp.
  ///
  /// In en, this message translates to:
  /// **'Accept this invitation only if you signed in with the email address it was sent to.'**
  String get acceptInvitationHelp;

  /// No description provided for @acceptInvitationLabel.
  ///
  /// In en, this message translates to:
  /// **'Accept invitation'**
  String get acceptInvitationLabel;

  /// No description provided for @staffCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff ({count})'**
  String staffCountTitle(int count);

  /// No description provided for @inactiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveLabel;

  /// No description provided for @editRolesLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit roles'**
  String get editRolesLabel;

  /// No description provided for @invitationCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitations ({count})'**
  String invitationCountTitle(int count);

  /// No description provided for @resendInvitationLabel.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resendInvitationLabel;

  /// No description provided for @revokeInvitationLabel.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revokeInvitationLabel;

  /// No description provided for @invitationPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get invitationPending;

  /// No description provided for @invitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get invitationAccepted;

  /// No description provided for @invitationRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get invitationRevoked;

  /// No description provided for @invitationExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get invitationExpired;

  /// No description provided for @staffInvalidInputIssue.
  ///
  /// In en, this message translates to:
  /// **'Check the information and try again.'**
  String get staffInvalidInputIssue;

  /// No description provided for @ownerPasswordRequiredIssue.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password to continue.'**
  String get ownerPasswordRequiredIssue;

  /// No description provided for @invitationUnavailableIssue.
  ///
  /// In en, this message translates to:
  /// **'This invitation is unavailable.'**
  String get invitationUnavailableIssue;

  /// No description provided for @staffMemberUnavailableIssue.
  ///
  /// In en, this message translates to:
  /// **'This staff member is unavailable.'**
  String get staffMemberUnavailableIssue;

  /// No description provided for @doctorScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Doctor schedule'**
  String get doctorScheduleTitle;

  /// No description provided for @scheduleChooseClinic.
  ///
  /// In en, this message translates to:
  /// **'Choose a clinic before viewing schedules.'**
  String get scheduleChooseClinic;

  /// No description provided for @clinicTimeZoneExplanation.
  ///
  /// In en, this message translates to:
  /// **'All times use the clinic time zone: {timeZone}.'**
  String clinicTimeZoneExplanation(String timeZone);

  /// No description provided for @setWeeklyHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Set weekly hours'**
  String get setWeeklyHoursLabel;

  /// No description provided for @addUnavailableTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Add leave or unavailable time'**
  String get addUnavailableTimeLabel;

  /// No description provided for @weeklyHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly hours'**
  String get weeklyHoursTitle;

  /// No description provided for @noWeeklyHours.
  ///
  /// In en, this message translates to:
  /// **'No weekly hours have been set for this dentist.'**
  String get noWeeklyHours;

  /// No description provided for @unavailablePeriodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave and unavailable periods'**
  String get unavailablePeriodsTitle;

  /// No description provided for @noUnavailablePeriods.
  ///
  /// In en, this message translates to:
  /// **'No leave or unavailable periods are recorded.'**
  String get noUnavailablePeriods;

  /// No description provided for @leaveLabel.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveLabel;

  /// No description provided for @unavailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailableLabel;

  /// No description provided for @removeLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeLabel;

  /// No description provided for @scheduleConflictOwnerReview.
  ///
  /// In en, this message translates to:
  /// **'This change conflicts with {count} future appointment(s). An Owner must review it.'**
  String scheduleConflictOwnerReview(int count);

  /// No description provided for @weekdayNumberHelp.
  ///
  /// In en, this message translates to:
  /// **'Use 1 for Monday through 7 for Sunday.'**
  String get weekdayNumberHelp;

  /// No description provided for @workingDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Working days'**
  String get workingDaysLabel;

  /// No description provided for @startTimeFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time (HH:MM)'**
  String get startTimeFormatLabel;

  /// No description provided for @endTimeFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'End time (HH:MM)'**
  String get endTimeFormatLabel;

  /// No description provided for @breakStartOptional.
  ///
  /// In en, this message translates to:
  /// **'Break start (optional)'**
  String get breakStartOptional;

  /// No description provided for @breakEndOptional.
  ///
  /// In en, this message translates to:
  /// **'Break end (optional)'**
  String get breakEndOptional;

  /// No description provided for @effectiveFromFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective from (YYYY-MM-DD)'**
  String get effectiveFromFormatLabel;

  /// No description provided for @addUnavailableTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add unavailable time'**
  String get addUnavailableTimeTitle;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @startsLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get startsLabel;

  /// No description provided for @endsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get endsLabel;

  /// No description provided for @reasonOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptionalLabel;

  /// No description provided for @effectiveFromValue.
  ///
  /// In en, this message translates to:
  /// **'Effective from {date}'**
  String effectiveFromValue(String date);

  /// No description provided for @noWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'No working hours'**
  String get noWorkingHours;

  /// No description provided for @breakLabel.
  ///
  /// In en, this message translates to:
  /// **'break'**
  String get breakLabel;

  /// No description provided for @reviewAffectedAppointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Review affected appointments'**
  String get reviewAffectedAppointmentsTitle;

  /// No description provided for @affectedAppointmentsExplanation.
  ///
  /// In en, this message translates to:
  /// **'This change conflicts with {count} future appointment(s). They will remain booked and be flagged for manual resolution.'**
  String affectedAppointmentsExplanation(int count);

  /// No description provided for @ownerConfirmationReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner confirmation reason'**
  String get ownerConfirmationReasonLabel;

  /// No description provided for @cancelChangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel change'**
  String get cancelChangeLabel;

  /// No description provided for @confirmAndFlagLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm and flag'**
  String get confirmAndFlagLabel;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @scheduleEditForbiddenIssue.
  ///
  /// In en, this message translates to:
  /// **'You cannot change this dentist schedule.'**
  String get scheduleEditForbiddenIssue;

  /// No description provided for @activeDentistRequiredIssue.
  ///
  /// In en, this message translates to:
  /// **'This staff member is not an active dentist.'**
  String get activeDentistRequiredIssue;

  /// No description provided for @effectiveDateInvalidIssue.
  ///
  /// In en, this message translates to:
  /// **'Choose a future clinic date.'**
  String get effectiveDateInvalidIssue;

  /// No description provided for @exceptionUnavailableIssue.
  ///
  /// In en, this message translates to:
  /// **'This unavailable period is no longer available.'**
  String get exceptionUnavailableIssue;

  /// No description provided for @affectedAppointmentsIssue.
  ///
  /// In en, this message translates to:
  /// **'This schedule change affects future appointments and requires Owner review.'**
  String get affectedAppointmentsIssue;

  /// No description provided for @scheduleSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Weekly hours saved.'**
  String get scheduleSavedMessage;

  /// No description provided for @scheduleInvalidInputMessage.
  ///
  /// In en, this message translates to:
  /// **'Check the working days, times, break, and effective date.'**
  String get scheduleInvalidInputMessage;

  /// No description provided for @scheduleForLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule for'**
  String get scheduleForLabel;

  /// No description provided for @scheduleActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active schedule'**
  String get scheduleActiveLabel;

  /// No description provided for @scheduleUpcomingLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming schedule'**
  String get scheduleUpcomingLabel;

  /// No description provided for @scheduleHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule history'**
  String get scheduleHistoryLabel;

  /// No description provided for @scheduleHistoryHelp.
  ///
  /// In en, this message translates to:
  /// **'Previous and superseded working-hour versions'**
  String get scheduleHistoryHelp;

  /// No description provided for @editWeeklyHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit weekly schedule'**
  String get editWeeklyHoursLabel;

  /// No description provided for @selectWorkingDaysHelp.
  ///
  /// In en, this message translates to:
  /// **'Select the days this dentist works.'**
  String get selectWorkingDaysHelp;

  /// No description provided for @includeBreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Include a break'**
  String get includeBreakLabel;

  /// No description provided for @effectiveDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective date'**
  String get effectiveDateLabel;

  /// No description provided for @closedLabel.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedLabel;

  /// No description provided for @scheduleSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule summary'**
  String get scheduleSummaryLabel;

  /// No description provided for @procedureCatalogueTitle.
  ///
  /// In en, this message translates to:
  /// **'Procedure catalogue'**
  String get procedureCatalogueTitle;

  /// No description provided for @backToClinicLabel.
  ///
  /// In en, this message translates to:
  /// **'Back to clinic'**
  String get backToClinicLabel;

  /// No description provided for @newProcedureLabel.
  ///
  /// In en, this message translates to:
  /// **'New procedure'**
  String get newProcedureLabel;

  /// No description provided for @editProcedureLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit procedure'**
  String get editProcedureLabel;

  /// No description provided for @procedureCatalogueOwnerHelp.
  ///
  /// In en, this message translates to:
  /// **'Create the services dentists can add to treatment plans.'**
  String get procedureCatalogueOwnerHelp;

  /// No description provided for @procedureCatalogueViewerHelp.
  ///
  /// In en, this message translates to:
  /// **'Available clinic procedures and standard prices.'**
  String get procedureCatalogueViewerHelp;

  /// No description provided for @noProceduresCatalogue.
  ///
  /// In en, this message translates to:
  /// **'No procedures yet. An owner can add the first procedure.'**
  String get noProceduresCatalogue;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// No description provided for @activateLabel.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activateLabel;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @standardPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Standard price'**
  String get standardPriceLabel;

  /// No description provided for @durationMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration in minutes'**
  String get durationMinutesLabel;

  /// No description provided for @validPriceValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price.'**
  String get validPriceValidation;

  /// No description provided for @durationRangeValidation.
  ///
  /// In en, this message translates to:
  /// **'Use 5 to 720 minutes.'**
  String get durationRangeValidation;

  /// No description provided for @treatmentPlansUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Treatment plans are unavailable. Return to the patient list and select the patient again.'**
  String get treatmentPlansUnavailable;

  /// No description provided for @noActiveDentist.
  ///
  /// In en, this message translates to:
  /// **'No active dentist membership is available.'**
  String get noActiveDentist;

  /// No description provided for @newPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get newPlanLabel;

  /// No description provided for @treatmentViewOnly.
  ///
  /// In en, this message translates to:
  /// **'Your role has view-only access to treatment plans.'**
  String get treatmentViewOnly;

  /// No description provided for @noTreatmentPlan.
  ///
  /// In en, this message translates to:
  /// **'No treatment plan yet. A dentist can prepare a draft plan.'**
  String get noTreatmentPlan;

  /// No description provided for @newTreatmentPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'New treatment plan'**
  String get newTreatmentPlanTitle;

  /// No description provided for @leadDentistLabel.
  ///
  /// In en, this message translates to:
  /// **'Lead dentist'**
  String get leadDentistLabel;

  /// No description provided for @planNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Plan notes (optional)'**
  String get planNotesOptional;

  /// No description provided for @editPlanNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit plan notes'**
  String get editPlanNotesTitle;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @ownerAddProcedureFirst.
  ///
  /// In en, this message translates to:
  /// **'The clinic owner must add an active procedure first.'**
  String get ownerAddProcedureFirst;

  /// No description provided for @addProcedureLabel.
  ///
  /// In en, this message translates to:
  /// **'Add procedure'**
  String get addProcedureLabel;

  /// No description provided for @procedureLabel.
  ///
  /// In en, this message translates to:
  /// **'Procedure'**
  String get procedureLabel;

  /// No description provided for @fdiToothOptional.
  ///
  /// In en, this message translates to:
  /// **'FDI tooth number (optional)'**
  String get fdiToothOptional;

  /// No description provided for @validFdiValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid FDI tooth number.'**
  String get validFdiValidation;

  /// No description provided for @estimatedPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated price'**
  String get estimatedPriceLabel;

  /// No description provided for @assignedDentistOptional.
  ///
  /// In en, this message translates to:
  /// **'Assigned dentist (optional)'**
  String get assignedDentistOptional;

  /// No description provided for @notAssignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get notAssignedLabel;

  /// No description provided for @clinicalDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Clinical description (optional)'**
  String get clinicalDescriptionOptional;

  /// No description provided for @saveProcedureLabel.
  ///
  /// In en, this message translates to:
  /// **'Save procedure'**
  String get saveProcedureLabel;

  /// No description provided for @planTransitionQuestion.
  ///
  /// In en, this message translates to:
  /// **'{status} treatment plan?'**
  String planTransitionQuestion(String status);

  /// No description provided for @activatePlanExplanation.
  ///
  /// In en, this message translates to:
  /// **'This makes the plan the patient’s active treatment plan.'**
  String get activatePlanExplanation;

  /// No description provided for @finalPlanTransitionExplanation.
  ///
  /// In en, this message translates to:
  /// **'This status change is recorded and cannot be reversed.'**
  String get finalPlanTransitionExplanation;

  /// No description provided for @plansTitle.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plansTitle;

  /// No description provided for @procedureCountValue.
  ///
  /// In en, this message translates to:
  /// **'{count} procedures'**
  String procedureCountValue(int count);

  /// No description provided for @editNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit notes'**
  String get editNotesLabel;

  /// No description provided for @activatePlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Activate plan'**
  String get activatePlanLabel;

  /// No description provided for @cancelPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel plan'**
  String get cancelPlanLabel;

  /// No description provided for @completePlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Complete plan'**
  String get completePlanLabel;

  /// No description provided for @planHasNoProcedures.
  ///
  /// In en, this message translates to:
  /// **'This plan has no procedures yet.'**
  String get planHasNoProcedures;

  /// No description provided for @unavailableProcedure.
  ///
  /// In en, this message translates to:
  /// **'Unavailable procedure'**
  String get unavailableProcedure;

  /// No description provided for @toothNumberValue.
  ///
  /// In en, this message translates to:
  /// **'Tooth {number}'**
  String toothNumberValue(int number);

  /// No description provided for @dentistValue.
  ///
  /// In en, this message translates to:
  /// **'Dentist: {email}'**
  String dentistValue(String email);

  /// No description provided for @changeStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get changeStatusLabel;

  /// No description provided for @planStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get planStatusDraft;

  /// No description provided for @planStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get planStatusActive;

  /// No description provided for @planStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get planStatusCompleted;

  /// No description provided for @planStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get planStatusCancelled;

  /// No description provided for @itemStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get itemStatusPlanned;

  /// No description provided for @itemStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get itemStatusApproved;

  /// No description provided for @itemStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get itemStatusInProgress;

  /// No description provided for @itemStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get itemStatusCompleted;

  /// No description provided for @itemStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get itemStatusCancelled;

  /// No description provided for @treatmentForbiddenIssue.
  ///
  /// In en, this message translates to:
  /// **'Your clinic role cannot make this change.'**
  String get treatmentForbiddenIssue;

  /// No description provided for @treatmentUnavailableIssue.
  ///
  /// In en, this message translates to:
  /// **'This record is no longer available.'**
  String get treatmentUnavailableIssue;

  /// No description provided for @treatmentInvalidInputIssue.
  ///
  /// In en, this message translates to:
  /// **'Check the entered information and try again.'**
  String get treatmentInvalidInputIssue;

  /// No description provided for @treatmentDraftOnlyIssue.
  ///
  /// In en, this message translates to:
  /// **'Only a draft treatment plan can be edited.'**
  String get treatmentDraftOnlyIssue;

  /// No description provided for @treatmentActiveRequiredIssue.
  ///
  /// In en, this message translates to:
  /// **'The treatment plan must be active for this change.'**
  String get treatmentActiveRequiredIssue;

  /// No description provided for @treatmentItemsRequiredIssue.
  ///
  /// In en, this message translates to:
  /// **'Add at least one procedure before activating the plan.'**
  String get treatmentItemsRequiredIssue;

  /// No description provided for @activePlanExistsIssue.
  ///
  /// In en, this message translates to:
  /// **'This patient already has an active treatment plan.'**
  String get activePlanExistsIssue;

  /// No description provided for @treatmentInvalidTransitionIssue.
  ///
  /// In en, this message translates to:
  /// **'That status change is not allowed.'**
  String get treatmentInvalidTransitionIssue;

  /// No description provided for @dentalChartUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Dental Chart is unavailable. Return to the patient list and select the patient again.'**
  String get dentalChartUnavailable;

  /// No description provided for @backToPatientProfile.
  ///
  /// In en, this message translates to:
  /// **'Back to patient profile'**
  String get backToPatientProfile;

  /// No description provided for @permanentTeethLabel.
  ///
  /// In en, this message translates to:
  /// **'Permanent teeth'**
  String get permanentTeethLabel;

  /// No description provided for @primaryTeethLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary teeth'**
  String get primaryTeethLabel;

  /// No description provided for @selectToothToAdd.
  ///
  /// In en, this message translates to:
  /// **'Select a tooth to add a condition'**
  String get selectToothToAdd;

  /// No description provided for @addConditionToTooth.
  ///
  /// In en, this message translates to:
  /// **'Add condition to tooth {number}'**
  String addConditionToTooth(int number);

  /// No description provided for @selectToothFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a tooth first.'**
  String get selectToothFirst;

  /// No description provided for @addConditionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add condition — tooth {number}'**
  String addConditionTitle(int number);

  /// No description provided for @conditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get conditionLabel;

  /// No description provided for @surfaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get surfaceLabel;

  /// No description provided for @clinicalNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Clinical note (optional)'**
  String get clinicalNoteOptional;

  /// No description provided for @saveConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Save condition'**
  String get saveConditionLabel;

  /// No description provided for @resolveConditionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Resolve condition?'**
  String get resolveConditionQuestion;

  /// No description provided for @resolveConditionExplanation.
  ///
  /// In en, this message translates to:
  /// **'{condition} on tooth {number} will remain in the patient history.'**
  String resolveConditionExplanation(String condition, int number);

  /// No description provided for @resolveLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolveLabel;

  /// No description provided for @markEntryErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark entry as error'**
  String get markEntryErrorTitle;

  /// No description provided for @entryErrorReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Why is this entry incorrect?'**
  String get entryErrorReasonLabel;

  /// No description provided for @preserveAsErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Preserve as error'**
  String get preserveAsErrorLabel;

  /// No description provided for @selectToothReview.
  ///
  /// In en, this message translates to:
  /// **'Select a tooth to review its active conditions.'**
  String get selectToothReview;

  /// No description provided for @healthyToothMessage.
  ///
  /// In en, this message translates to:
  /// **'Tooth {number} is healthy. No active condition is recorded.'**
  String healthyToothMessage(int number);

  /// No description provided for @toothHealthySemantics.
  ///
  /// In en, this message translates to:
  /// **'Tooth {number}, healthy'**
  String toothHealthySemantics(int number);

  /// No description provided for @toothConditionsSemantics.
  ///
  /// In en, this message translates to:
  /// **'Tooth {number}, {count} active conditions'**
  String toothConditionsSemantics(int number, int count);

  /// No description provided for @markAsErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Mark as error'**
  String get markAsErrorLabel;

  /// No description provided for @conditionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Condition history'**
  String get conditionHistoryTitle;

  /// No description provided for @recordedItemsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} recorded items'**
  String recordedItemsValue(int count);

  /// No description provided for @noDentalHistory.
  ///
  /// In en, this message translates to:
  /// **'No Dental Chart history has been recorded.'**
  String get noDentalHistory;

  /// No description provided for @loadMoreHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Load more history'**
  String get loadMoreHistoryLabel;

  /// No description provided for @dentalRoleRestricted.
  ///
  /// In en, this message translates to:
  /// **'Dental Chart clinical details are not available for your role.'**
  String get dentalRoleRestricted;

  /// No description provided for @surfaceWhole.
  ///
  /// In en, this message translates to:
  /// **'Whole tooth'**
  String get surfaceWhole;

  /// No description provided for @surfaceMesial.
  ///
  /// In en, this message translates to:
  /// **'Mesial'**
  String get surfaceMesial;

  /// No description provided for @surfaceDistal.
  ///
  /// In en, this message translates to:
  /// **'Distal'**
  String get surfaceDistal;

  /// No description provided for @surfaceOcclusal.
  ///
  /// In en, this message translates to:
  /// **'Occlusal'**
  String get surfaceOcclusal;

  /// No description provided for @surfaceBuccal.
  ///
  /// In en, this message translates to:
  /// **'Buccal'**
  String get surfaceBuccal;

  /// No description provided for @surfaceLingual.
  ///
  /// In en, this message translates to:
  /// **'Lingual'**
  String get surfaceLingual;

  /// No description provided for @conditionCaries.
  ///
  /// In en, this message translates to:
  /// **'Caries'**
  String get conditionCaries;

  /// No description provided for @conditionFilling.
  ///
  /// In en, this message translates to:
  /// **'Filling'**
  String get conditionFilling;

  /// No description provided for @conditionCrown.
  ///
  /// In en, this message translates to:
  /// **'Crown'**
  String get conditionCrown;

  /// No description provided for @conditionRootCanal.
  ///
  /// In en, this message translates to:
  /// **'Root canal'**
  String get conditionRootCanal;

  /// No description provided for @conditionFracture.
  ///
  /// In en, this message translates to:
  /// **'Fracture'**
  String get conditionFracture;

  /// No description provided for @conditionMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get conditionMissing;

  /// No description provided for @conditionExtraction.
  ///
  /// In en, this message translates to:
  /// **'Extraction required'**
  String get conditionExtraction;

  /// No description provided for @conditionImplant.
  ///
  /// In en, this message translates to:
  /// **'Implant'**
  String get conditionImplant;

  /// No description provided for @conditionStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get conditionStatusActive;

  /// No description provided for @conditionStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get conditionStatusResolved;

  /// No description provided for @conditionStatusError.
  ///
  /// In en, this message translates to:
  /// **'Entered in error'**
  String get conditionStatusError;

  /// No description provided for @odontogramForbiddenIssue.
  ///
  /// In en, this message translates to:
  /// **'Your role cannot change Dental Chart conditions.'**
  String get odontogramForbiddenIssue;

  /// No description provided for @odontogramUnavailableIssue.
  ///
  /// In en, this message translates to:
  /// **'This patient or condition is no longer available.'**
  String get odontogramUnavailableIssue;

  /// No description provided for @odontogramInvalidInputIssue.
  ///
  /// In en, this message translates to:
  /// **'Check the tooth, surface, and condition details.'**
  String get odontogramInvalidInputIssue;

  /// No description provided for @missingToothConflictIssue.
  ///
  /// In en, this message translates to:
  /// **'Resolve or correct the existing natural-tooth condition before recording this tooth as missing.'**
  String get missingToothConflictIssue;

  /// No description provided for @duplicateConditionIssue.
  ///
  /// In en, this message translates to:
  /// **'This active condition is already recorded for the selected tooth surface.'**
  String get duplicateConditionIssue;

  /// No description provided for @conditionNotActiveIssue.
  ///
  /// In en, this message translates to:
  /// **'This condition is already closed and remains in history.'**
  String get conditionNotActiveIssue;

  /// No description provided for @validAmountValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get validAmountValidation;

  /// No description provided for @quantityRangeValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity from 0.01 to 999.99.'**
  String get quantityRangeValidation;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @moreLabel.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreLabel;

  /// No description provided for @workspaceNavigationLabel.
  ///
  /// In en, this message translates to:
  /// **'Workspace navigation'**
  String get workspaceNavigationLabel;

  /// No description provided for @themeSystemLabel.
  ///
  /// In en, this message translates to:
  /// **'System theme'**
  String get themeSystemLabel;

  /// No description provided for @languageSystemLabel.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get languageSystemLabel;

  /// No description provided for @clinicSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get clinicSectionTitle;

  /// No description provided for @privacySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySectionTitle;

  /// No description provided for @accountSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSectionTitle;

  /// No description provided for @applicationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get applicationSectionTitle;

  /// No description provided for @developmentMvpLabel.
  ///
  /// In en, this message translates to:
  /// **'Development MVP · fictional data only'**
  String get developmentMvpLabel;

  /// No description provided for @currentRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get currentRoleLabel;

  /// No description provided for @patientNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient number'**
  String get patientNumberLabel;

  /// No description provided for @patientNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientNameLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @noAppointmentsDay.
  ///
  /// In en, this message translates to:
  /// **'No appointments scheduled for this day.'**
  String get noAppointmentsDay;

  /// No description provided for @dentitionLabel.
  ///
  /// In en, this message translates to:
  /// **'Dentition'**
  String get dentitionLabel;

  /// No description provided for @quadrantUpperRight.
  ///
  /// In en, this message translates to:
  /// **'Upper Right (UR)'**
  String get quadrantUpperRight;

  /// No description provided for @quadrantUpperLeft.
  ///
  /// In en, this message translates to:
  /// **'Upper Left (UL)'**
  String get quadrantUpperLeft;

  /// No description provided for @quadrantLowerRight.
  ///
  /// In en, this message translates to:
  /// **'Lower Right (LR)'**
  String get quadrantLowerRight;

  /// No description provided for @quadrantLowerLeft.
  ///
  /// In en, this message translates to:
  /// **'Lower Left (LL)'**
  String get quadrantLowerLeft;

  /// No description provided for @dentalMidline.
  ///
  /// In en, this message translates to:
  /// **'Midline'**
  String get dentalMidline;

  /// No description provided for @maxillaUpperJaw.
  ///
  /// In en, this message translates to:
  /// **'Upper Jaw (Maxilla)'**
  String get maxillaUpperJaw;

  /// No description provided for @mandibleLowerJaw.
  ///
  /// In en, this message translates to:
  /// **'Lower Jaw (Mandible)'**
  String get mandibleLowerJaw;

  /// No description provided for @visitReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for visit'**
  String get visitReasonLabel;

  /// No description provided for @quickReasonCheckup.
  ///
  /// In en, this message translates to:
  /// **'Routine Checkup'**
  String get quickReasonCheckup;

  /// No description provided for @quickReasonCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning / Scaling'**
  String get quickReasonCleaning;

  /// No description provided for @quickReasonToothache.
  ///
  /// In en, this message translates to:
  /// **'Toothache / Emergency'**
  String get quickReasonToothache;

  /// No description provided for @quickReasonConsultation.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get quickReasonConsultation;

  /// No description provided for @quickReasonFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get quickReasonFollowUp;

  /// No description provided for @doctorWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Working hours: {hours}'**
  String doctorWorkingHours(String hours);

  /// No description provided for @doctorOffDuty.
  ///
  /// In en, this message translates to:
  /// **'Doctor has no scheduled hours on this day'**
  String get doctorOffDuty;

  /// No description provided for @doctorOnLeave.
  ///
  /// In en, this message translates to:
  /// **'Doctor is on leave on this date'**
  String get doctorOnLeave;

  /// No description provided for @changePatientLabel.
  ///
  /// In en, this message translates to:
  /// **'Change patient'**
  String get changePatientLabel;

  /// No description provided for @overrideScheduleQuestion.
  ///
  /// In en, this message translates to:
  /// **'Override doctor schedule conflict (Owner only)'**
  String get overrideScheduleQuestion;

  /// No description provided for @selectedPatientCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected patient'**
  String get selectedPatientCardTitle;

  /// No description provided for @doctorNoScheduleConfigured.
  ///
  /// In en, this message translates to:
  /// **'Doctor has no working schedule configured in this clinic'**
  String get doctorNoScheduleConfigured;

  /// No description provided for @timeOutsideWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Selected time ({time}) is outside doctor\'s working hours ({hours})'**
  String timeOutsideWorkingHours(String time, String hours);

  /// No description provided for @appointmentConflictExplanation.
  ///
  /// In en, this message translates to:
  /// **'This appointment conflicts with the doctor\'s schedule (off-duty, on leave, or outside working hours). As clinic owner, please enter an override reason above to confirm.'**
  String get appointmentConflictExplanation;

  /// No description provided for @middleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Middle / Father\'s name'**
  String get middleNameLabel;

  /// No description provided for @administrativeNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Administrative / Clinic notes'**
  String get administrativeNotesLabel;

  /// No description provided for @personalInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformationSection;

  /// No description provided for @contactInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformationSection;

  /// No description provided for @birthAndAgeSection.
  ///
  /// In en, this message translates to:
  /// **'Birth Date & Age'**
  String get birthAndAgeSection;

  /// No description provided for @selectBirthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Select birth date'**
  String get selectBirthDateLabel;

  /// No description provided for @guardianInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Parent / Guardian Contact (Minor)'**
  String get guardianInformationSection;

  /// No description provided for @newPatientShortcut.
  ///
  /// In en, this message translates to:
  /// **'+ Register New Patient'**
  String get newPatientShortcut;

  /// No description provided for @yearsOldValue.
  ///
  /// In en, this message translates to:
  /// **'{age} years old'**
  String yearsOldValue(int age);

  /// No description provided for @ageInYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'Age in years'**
  String get ageInYearsLabel;

  /// No description provided for @clinicalHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Clinical Records & Treatment'**
  String get clinicalHubTitle;

  /// No description provided for @administrativeHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Administration & Appointments'**
  String get administrativeHubTitle;

  /// No description provided for @bookAppointmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointmentLabel;

  /// No description provided for @minorBadge.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get minorBadge;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @copyLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyLabel;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @appointmentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No appointments} =1{1 appointment} other{{count} appointments}}'**
  String appointmentsCount(int count);

  /// No description provided for @viewProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get viewProfileLabel;

  /// No description provided for @preparationNoteBadge.
  ///
  /// In en, this message translates to:
  /// **'Prep Note'**
  String get preparationNoteBadge;

  /// No description provided for @overrideBadge.
  ///
  /// In en, this message translates to:
  /// **'Override'**
  String get overrideBadge;

  /// No description provided for @emptyCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'No appointments scheduled'**
  String get emptyCalendarTitle;

  /// No description provided for @emptyCalendarHelp.
  ///
  /// In en, this message translates to:
  /// **'Use the button below or switch dates to view or schedule appointments.'**
  String get emptyCalendarHelp;

  /// No description provided for @medicalAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical & Allergy Alerts'**
  String get medicalAlertsTitle;

  /// No description provided for @noKnownAllergies.
  ///
  /// In en, this message translates to:
  /// **'No known drug allergies or medical alerts'**
  String get noKnownAllergies;

  /// No description provided for @unscreenedMedicalHelp.
  ///
  /// In en, this message translates to:
  /// **'No medical history recorded yet. Complete medical screening before clinical procedures.'**
  String get unscreenedMedicalHelp;

  /// No description provided for @screenMedicalLabel.
  ///
  /// In en, this message translates to:
  /// **'Screen medical history'**
  String get screenMedicalLabel;

  /// No description provided for @whatsAppLabel.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsAppLabel;

  /// No description provided for @callLabel.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callLabel;

  /// No description provided for @emailActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Send email'**
  String get emailActionLabel;

  /// No description provided for @sendWhatsAppReminder.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp reminder'**
  String get sendWhatsAppReminder;

  /// No description provided for @reminderMessageTemplate.
  ///
  /// In en, this message translates to:
  /// **'Hello {patientName}, this is a reminder from {clinicName}. You have a dental appointment with Dr. {dentistName} on {date} at {time}. Please reply to this message to confirm your appointment. Thank you!'**
  String reminderMessageTemplate(
    String patientName,
    String clinicName,
    String dentistName,
    String date,
    String time,
  );

  /// No description provided for @noPhoneForPatient.
  ///
  /// In en, this message translates to:
  /// **'No phone number registered for this patient.'**
  String get noPhoneForPatient;

  /// No description provided for @communicationLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not launch application.'**
  String get communicationLaunchFailed;

  /// No description provided for @loadStandardProcedures.
  ///
  /// In en, this message translates to:
  /// **'Load standard procedures'**
  String get loadStandardProcedures;

  /// No description provided for @loadStandardProceduresHelp.
  ///
  /// In en, this message translates to:
  /// **'Quickly add standard dental procedures to your catalogue.'**
  String get loadStandardProceduresHelp;

  /// No description provided for @loadStandardProceduresConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will add {count} standard dental procedures to your clinic catalogue. You can customize prices and durations anytime. Continue?'**
  String loadStandardProceduresConfirm(int count);

  /// No description provided for @searchProceduresPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search procedures or categories...'**
  String get searchProceduresPlaceholder;

  /// No description provided for @allCategoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategoriesLabel;

  /// No description provided for @activeOnlyFilter.
  ///
  /// In en, this message translates to:
  /// **'Active only'**
  String get activeOnlyFilter;

  /// No description provided for @totalProceduresCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 procedure} other{{count} procedures}}'**
  String totalProceduresCount(int count);

  /// No description provided for @activeProceduresCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String activeProceduresCount(int count);

  /// No description provided for @categoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String categoriesCount(int count);

  /// No description provided for @standardProceduresImported.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} standard procedures.'**
  String standardProceduresImported(int count);

  /// No description provided for @noMatchingProcedures.
  ///
  /// In en, this message translates to:
  /// **'No procedures match your search or filter.'**
  String get noMatchingProcedures;

  /// No description provided for @clearFiltersLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFiltersLabel;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// No description provided for @toothTreatmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Treatments for Tooth {toothNumber}'**
  String toothTreatmentsTitle(int toothNumber);

  /// No description provided for @noTreatmentsPlannedForTooth.
  ///
  /// In en, this message translates to:
  /// **'No treatments currently planned for this tooth.'**
  String get noTreatmentsPlannedForTooth;

  /// No description provided for @suggestedTreatmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested Procedures'**
  String get suggestedTreatmentsTitle;

  /// No description provided for @addTreatmentForTooth.
  ///
  /// In en, this message translates to:
  /// **'Add Planned Treatment'**
  String get addTreatmentForTooth;

  /// No description provided for @scheduleAppointmentForTooth.
  ///
  /// In en, this message translates to:
  /// **'Schedule Appointment'**
  String get scheduleAppointmentForTooth;

  /// No description provided for @scheduleThisProcedure.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get scheduleThisProcedure;

  /// No description provided for @procedureAddedToPlan.
  ///
  /// In en, this message translates to:
  /// **'Procedure added to treatment plan.'**
  String get procedureAddedToPlan;

  /// No description provided for @selectProcedureToAdd.
  ///
  /// In en, this message translates to:
  /// **'Select Procedure from Catalogue'**
  String get selectProcedureToAdd;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
