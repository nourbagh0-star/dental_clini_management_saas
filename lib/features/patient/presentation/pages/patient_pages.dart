import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/utils/communication_launcher.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/responsive_record_view.dart';
import '../../../../core/widgets/workspace_page.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../domain/patient_models.dart';
import '../patient_cubit.dart';
import '../patient_medical_cubit.dart';
import '../widgets/patient_medical_alert_banner.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});
  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  String? _loadedClinicId;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final clinic = context.watch<ClinicCubit>().state.activeClinic;
    if (clinic == null) return _PatientMessage(l.chooseClinicFirst);
    if (_loadedClinicId != clinic.id) {
      _loadedClinicId = clinic.id;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<PatientCubit>().load(clinic.id),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l.patientsTitle),
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/patients/new'),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l.newPatientLabel),
      ),
      body: BlocBuilder<PatientCubit, PatientState>(
        builder: (context, state) => ListView(
          padding: AppInsets.page(AppBreakpoints.of(context)),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.wideContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l.searchPatientLabel,
                        suffixIcon: _search.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                  context.read<PatientCubit>().load(clinic.id);
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {});
                        context.read<PatientCubit>().load(
                              clinic.id,
                              query: value,
                            );
                      },
                      onSubmitted: (value) => context.read<PatientCubit>().load(
                            clinic.id,
                            query: value,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    if (state.status == PatientStatus.loading)
                      const LinearProgressIndicator(),
                    if (state.failure != null)
                      _PatientMessage(
                        failureMessage(
                          state.failure!,
                          AppLocalizations.of(context),
                        ),
                      ),
                    if (state.issue != null)
                      _PatientMessage(l.patientActionUnavailable),
                    if (state.status == PatientStatus.ready &&
                        state.patients.isEmpty)
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 24,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_search_outlined,
                                size: 56,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l.noPatientsFound,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => context.go('/patients/new'),
                                icon:
                                    const Icon(Icons.person_add_alt_1, size: 18),
                                label: Text(l.newPatientLabel),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (state.patients.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Text(
                          '${state.patients.length} ${l.patientsTitle.toLowerCase()}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ResponsiveRecordView(
                        expandAt: 760,
                        compact: Column(
                          children: [
                            for (final patient in state.patients)
                              _PatientCard(
                                patient: patient,
                                onTap: () =>
                                    context.go('/patients/${patient.id}'),
                              ),
                          ],
                        ),
                        expanded: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                DataColumn(label: Text(l.patientNameLabel)),
                                DataColumn(label: Text(l.patientNumberLabel)),
                                DataColumn(label: Text(l.contactTitle)),
                                DataColumn(label: Text(l.statusLabel)),
                              ],
                              rows: [
                                for (final patient in state.patients)
                                  DataRow(
                                    onSelectChanged: (_) =>
                                        context.go('/patients/${patient.id}'),
                                    cells: [
                                      DataCell(Text(patient.fullName)),
                                      DataCell(Text(patient.patientNumber)),
                                      DataCell(
                                        Text(
                                          patient.phone ??
                                              patient.email ??
                                              l.noContactLabel,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          patient.isArchived
                                              ? l.archivedLabel
                                              : l.activeLabel,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.onTap,
  });

  final Patient patient;
  final VoidCallback onTap;

  static int? _age(Patient p) {
    if (p.birthDate != null) {
      final birth = DateTime.tryParse(p.birthDate!);
      if (birth != null) {
        final now = DateTime.now();
        int age = now.year - birth.year;
        if (now.month < birth.month ||
            (now.month == birth.month && now.day < birth.day)) {
          age--;
        }
        return age < 0 ? 0 : age;
      }
    }
    return p.approximateAgeYears;
  }

  static String _initials(Patient patient) {
    final first = patient.firstName.trim().isNotEmpty
        ? patient.firstName.trim().characters.first
        : '';
    final last = patient.lastName.trim().isNotEmpty
        ? patient.lastName.trim().characters.first
        : '';
    final res = '$first$last'.trim();
    return res.isNotEmpty ? res.toUpperCase() : 'P';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final age = _age(patient);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: patient.isArchived
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.primaryContainer,
                foregroundColor: patient.isArchived
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
                child: Text(
                  _initials(patient),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: patient.isArchived
                                  ? theme.colorScheme.outline
                                  : theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (age != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            l.yearsOldValue(age),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${patient.patientNumber}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (patient.isArchived)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l.archivedLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l.activeLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (patient.isMinorDeclared)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 11,
                                  color: theme.colorScheme.tertiary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  l.minorBadge,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        theme.colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (patient.phone != null &&
                            patient.phone!.trim().isNotEmpty) ...[
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              patient.phone!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else if (patient.email != null &&
                            patient.email!.trim().isNotEmpty) ...[
                          Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              patient.email!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else
                          Text(
                            l.noContactLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isRtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewPatientPage extends StatefulWidget {
  const NewPatientPage({super.key});
  @override
  State<NewPatientPage> createState() => _NewPatientPageState();
}

class _NewPatientPageState extends State<NewPatientPage> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _birthDate = TextEditingController();
  final _approximateAge = TextEditingController();
  final _ageAssessedAt = TextEditingController();
  final _guardianName = TextEditingController();
  final _guardianPhone = TextEditingController();
  final _guardianEmail = TextEditingController();
  final _administrativeNotes = TextEditingController();

  DateTime? _selectedBirthDate;
  BirthDatePrecision _precision = BirthDatePrecision.unknown;
  bool _minorDeclared = false;

  @override
  void dispose() {
    _first.dispose();
    _middle.dispose();
    _last.dispose();
    _phone.dispose();
    _email.dispose();
    _birthDate.dispose();
    _approximateAge.dispose();
    _ageAssessedAt.dispose();
    _guardianName.dispose();
    _guardianPhone.dispose();
    _guardianEmail.dispose();
    _administrativeNotes.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedBirthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDate.text = DateFormat('yyyy-MM-dd').format(picked);
        final age = _calculateAge(picked);
        _minorDeclared = age < 18;
        _approximateAge.text = age.toString();
      });
    }
  }

  int _calculateAge(DateTime birth) {
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.newPatientLabel),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/patients');
            }
          },
        ),
      ),
      body: BlocConsumer<PatientCubit, PatientState>(
        listenWhen: (before, after) =>
            before.mutating &&
            !after.mutating &&
            after.status == PatientStatus.ready,
        listener: (_, state) => context.go('/patients'),
        builder: (context, state) => ListView(
          padding: AppInsets.page(AppBreakpoints.of(context)),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.contentWidth,
                ),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PatientSectionCard(
                        title: l.personalInformationSection,
                        icon: Icons.person_outline,
                        child: _ResponsiveFieldGrid(
                          children: [
                            TextFormField(
                              controller: _first,
                              decoration: InputDecoration(
                                labelText: l.firstNameLabel,
                                prefixIcon: const Icon(Icons.badge_outlined),
                              ),
                              validator: (v) => (v?.trim().isEmpty ?? true)
                                  ? l.requiredField
                                  : null,
                            ),
                            TextFormField(
                              controller: _middle,
                              decoration: InputDecoration(
                                labelText: l.middleNameLabel,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                            TextFormField(
                              controller: _last,
                              decoration: InputDecoration(
                                labelText: l.lastNameLabel,
                                prefixIcon: const Icon(Icons.badge_outlined),
                              ),
                              validator: (v) => (v?.trim().isEmpty ?? true)
                                  ? l.requiredField
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      _PatientSectionCard(
                        title: l.contactInformationSection,
                        icon: Icons.contact_phone_outlined,
                        child: _ResponsiveFieldGrid(
                          children: [
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: l.phoneLabel,
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                            ),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: l.emailLabel,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      _PatientSectionCard(
                        title: l.birthAndAgeSection,
                        icon: Icons.cake_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<BirthDatePrecision>(
                              isExpanded: true,
                              initialValue: _precision,
                              decoration: InputDecoration(
                                labelText: l.birthDateInformationLabel,
                                prefixIcon: const Icon(
                                  Icons.calendar_today_outlined,
                                ),
                              ),
                              items: BirthDatePrecision.values
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        _birthPrecisionLabel(item, l),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _precision = value;
                                  if (_precision ==
                                      BirthDatePrecision.unknown) {
                                    _selectedBirthDate = null;
                                    _birthDate.clear();
                                  }
                                });
                              },
                            ),
                            if (_precision == BirthDatePrecision.exact) ...[
                              const SizedBox(height: AppSpacing.medium),
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _pickBirthDate(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.medium,
                                    vertical: AppSpacing.small,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.6),
                                    ),
                                    color: theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_outlined,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: AppSpacing.medium),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _selectedBirthDate != null
                                                  ? DateFormat.yMMMMd().format(
                                                      _selectedBirthDate!,
                                                    )
                                                  : l.selectBirthDateLabel,
                                              style: TextStyle(
                                                fontWeight:
                                                    _selectedBirthDate != null
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _selectedBirthDate != null
                                                  ? l.yearsOldValue(
                                                      _calculateAge(
                                                        _selectedBirthDate!,
                                                      ),
                                                    )
                                                  : l.birthDateFormatLabel,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _selectedBirthDate != null
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme
                                                        .onSurfaceVariant,
                                                fontWeight:
                                                    _selectedBirthDate != null
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.small),
                                      Icon(
                                        Icons.edit_calendar_outlined,
                                        size: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (_precision ==
                                BirthDatePrecision.approximate) ...[
                              const SizedBox(height: AppSpacing.medium),
                              _ResponsiveFieldGrid(
                                children: [
                                  TextFormField(
                                    controller: _approximateAge,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: l.approximateAgeLabel,
                                      prefixIcon: const Icon(
                                        Icons.numbers_outlined,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final age = int.tryParse(val.trim());
                                      if (age != null) {
                                        setState(
                                          () => _minorDeclared = age < 18,
                                        );
                                      }
                                    },
                                  ),
                                  TextFormField(
                                    controller: _ageAssessedAt,
                                    decoration: InputDecoration(
                                      labelText: l.ageAssessedOnLabel,
                                      prefixIcon: const Icon(
                                        Icons.event_available_outlined,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: AppSpacing.small),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _minorDeclared,
                              onChanged: (value) => setState(
                                () => _minorDeclared = value ?? false,
                              ),
                              title: Text(l.knownMinorLabel),
                            ),
                          ],
                        ),
                      ),
                      if (_minorDeclared) ...[
                        const SizedBox(height: AppSpacing.medium),
                        _PatientSectionCard(
                          title: l.guardianInformationSection,
                          icon: Icons.shield_outlined,
                          child: _ResponsiveFieldGrid(
                            children: [
                              TextFormField(
                                controller: _guardianName,
                                decoration: InputDecoration(
                                  labelText: l.guardianNameLabel,
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                              ),
                              TextFormField(
                                controller: _guardianPhone,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: l.guardianPhoneLabel,
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                ),
                              ),
                              TextFormField(
                                controller: _guardianEmail,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: l.guardianEmailLabel,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.medium),
                      _PatientSectionCard(
                        title: l.administrativeNotesLabel,
                        icon: Icons.note_alt_outlined,
                        child: TextFormField(
                          controller: _administrativeNotes,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l.administrativeNotesLabel,
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      if (state.failure != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.medium,
                          ),
                          child: Text(
                            failureMessage(
                              state.failure!,
                              AppLocalizations.of(context),
                            ),
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      FilledButton(
                        onPressed: state.mutating
                            ? null
                            : () {
                                if (!(_form.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                context.read<PatientCubit>().create(
                                  PatientDraft(
                                    firstName: _first.text.trim(),
                                    middleName: _middle.text.trim().isEmpty
                                        ? null
                                        : _middle.text.trim(),
                                    lastName: _last.text.trim(),
                                    phone: _phone.text.trim().isEmpty
                                        ? null
                                        : _phone.text.trim(),
                                    email: _email.text.trim().isEmpty
                                        ? null
                                        : _email.text.trim(),
                                    birthDatePrecision: _precision,
                                    birthDate:
                                        _precision == BirthDatePrecision.exact
                                        ? _birthDate.text.trim()
                                        : null,
                                    approximateAgeYears:
                                        _precision ==
                                            BirthDatePrecision.approximate
                                        ? int.tryParse(
                                            _approximateAge.text.trim(),
                                          )
                                        : null,
                                    ageAssessedAt:
                                        _precision ==
                                            BirthDatePrecision.approximate
                                        ? (_ageAssessedAt.text.trim().isNotEmpty
                                              ? _ageAssessedAt.text.trim()
                                              : DateFormat(
                                                  'yyyy-MM-dd',
                                                ).format(DateTime.now()))
                                        : null,
                                    isMinorDeclared: _minorDeclared,
                                    guardianName:
                                        _guardianName.text.trim().isEmpty
                                        ? null
                                        : _guardianName.text.trim(),
                                    guardianPhone:
                                        _guardianPhone.text.trim().isEmpty
                                        ? null
                                        : _guardianPhone.text.trim(),
                                    guardianEmail:
                                        _guardianEmail.text.trim().isEmpty
                                        ? null
                                        : _guardianEmail.text.trim(),
                                    administrativeNotes:
                                        _administrativeNotes.text.trim().isEmpty
                                        ? null
                                        : _administrativeNotes.text.trim(),
                                  ),
                                );
                              },
                        child: state.mutating
                            ? const CircularProgressIndicator()
                            : Text(l.createPatientLabel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientSectionCard extends StatelessWidget {
  const _PatientSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            child,
          ],
        ),
      ),
    );
  }
}
class PatientProfilePage extends StatelessWidget {
  const PatientProfilePage({required this.patientId, super.key});
  final String patientId;

  int? _calculateAge(String? birthDateStr) {
    if (birthDateStr == null) return null;
    final birth = DateTime.tryParse(birthDateStr);
    if (birth == null) return null;
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  String _initials(Patient patient) {
    final first = patient.firstName.isNotEmpty ? patient.firstName[0] : '';
    final last = patient.lastName.isNotEmpty ? patient.lastName[0] : '';
    final res = '$first$last'.trim();
    return res.isNotEmpty ? res.toUpperCase() : 'P';
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _launchWhatsApp(BuildContext context, String phone) async {
    final success = await CommunicationLauncher.launchWhatsApp(phone: phone);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).communicationLaunchFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _launchCall(BuildContext context, String phone) async {
    final success = await CommunicationLauncher.launchPhoneCall(phone);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).communicationLaunchFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _launchEmail(BuildContext context, String email) async {
    final success = await CommunicationLauncher.launchEmail(email: email);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).communicationLaunchFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatBirthInfo(Patient patient, AppLocalizations l) {
    if (patient.birthDatePrecision == BirthDatePrecision.exact &&
        patient.birthDate != null) {
      final parsed = DateTime.tryParse(patient.birthDate!);
      if (parsed != null) {
        final age = _calculateAge(patient.birthDate);
        final dateStr = DateFormat.yMMMMd().format(parsed);
        return age != null ? '$dateStr (${l.yearsOldValue(age)})' : dateStr;
      }
      return patient.birthDate!;
    }
    if (patient.approximateAgeYears != null) {
      return l.approximatelyYearsValue(patient.approximateAgeYears!);
    }
    return l.birthPrecisionUnknown;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final patientState = context.watch<PatientCubit>().state;
    final patient = patientState.patients
        .where((item) => item.id == patientId)
        .firstOrNull;
    final isOwner =
        context.watch<ClinicCubit>().state.activeMembership?.isOwner ?? false;
    final roles =
        context.watch<ClinicCubit>().state.activeMembership?.roles ??
        const <String>{};
    final canReadVisits = roles.any(
      (role) => role == 'owner' || role == 'dentist' || role == 'assistant',
    );
    final canReadBilling = roles.any(
      (role) => role == 'owner' || role == 'dentist' || role == 'receptionist',
    );

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.patientProfileTitle)),
        body: _PatientMessage(l.patientProfileUnavailable),
      );
    }

    final calculatedAge =
        _calculateAge(patient.birthDate) ?? patient.approximateAgeYears;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.patientProfileTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/patients');
            }
          },
        ),
        actions: [
          if (isOwner)
            IconButton(
              icon: Icon(
                patient.isArchived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
              ),
              tooltip: patient.isArchived
                  ? l.restorePatientLabel
                  : l.archivePatientLabel,
              onPressed: patientState.mutating
                  ? null
                  : () => _confirmArchiveChange(context, patient),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.contentWidth,
          ),
          child: ListView(
            padding: AppInsets.page(AppBreakpoints.of(context)),
            children: [
              // 1. Patient Header Card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        child: Text(
                          _initials(patient),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.fullName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.extraSmall),
                            Wrap(
                              spacing: AppSpacing.small,
                              runSpacing: AppSpacing.extraSmall,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${patient.patientNumber}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: patient.isArchived
                                        ? theme.colorScheme.errorContainer
                                            .withValues(alpha: 0.7)
                                        : theme.colorScheme.primaryContainer
                                            .withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    patient.isArchived
                                        ? l.archivedLabel
                                        : l.activeLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: patient.isArchived
                                          ? theme.colorScheme.onErrorContainer
                                          : theme
                                              .colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                if (calculatedAge != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme.secondaryContainer
                                          .withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      l.yearsOldValue(calculatedAge),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme
                                            .colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                if (patient.isMinorDeclared)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme.tertiaryContainer
                                          .withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.shield_outlined,
                                          size: 13,
                                          color: theme
                                              .colorScheme.onTertiaryContainer,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          l.minorBadge,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme
                                                .onTertiaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              PatientMedicalAlertBanner(patientId: patientId),
              const SizedBox(height: AppSpacing.medium),

              // 2. Clinical Records & Treatment Hub
              _PatientSectionCard(
                title: l.clinicalHubTitle,
                icon: Icons.medical_services_outlined,
                child: _PatientActionGrid(
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          context.go('/patients/$patientId/dental-chart'),
                      icon: const Icon(Icons.grid_view_rounded),
                      label: Text(l.dentalChartTitle),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go(
                        '/patients/$patientId/treatment-plans',
                      ),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: Text(l.treatmentPlansTitle),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.go('/patients/$patientId/medical'),
                      icon: const Icon(Icons.medical_information_outlined),
                      label: Text(l.medicalProfileTitle),
                    ),
                    if (canReadVisits)
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.go('/patients/$patientId/visits'),
                        icon: const Icon(Icons.note_alt_outlined),
                        label: Text(l.visitsTitle),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // 3. Administration & Appointments Hub
              _PatientSectionCard(
                title: l.administrativeHubTitle,
                icon: Icons.badge_outlined,
                child: _PatientActionGrid(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          context.go('/appointments/new?patientId=$patientId'),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(l.bookAppointmentLabel),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/appointments'),
                      icon: const Icon(Icons.event_note_outlined),
                      label: Text(l.appointmentsTitle),
                    ),
                    if (canReadBilling)
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.go('/patients/$patientId/billing'),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: Text(l.billingTitle),
                      ),
                    if (canReadVisits)
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.go('/patients/$patientId/files'),
                        icon: const Icon(Icons.folder_outlined),
                        label: Text(l.patientFilesTitle),
                      ),
                    if (isOwner)
                      OutlinedButton.icon(
                        onPressed: patientState.mutating
                            ? null
                            : () => _confirmArchiveChange(context, patient),
                        icon: Icon(
                          patient.isArchived
                              ? Icons.unarchive
                              : Icons.archive,
                        ),
                        label: Text(
                          patient.isArchived
                              ? l.restorePatientLabel
                              : l.archivePatientLabel,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // 4. Contact & Demographics Card
              _PatientSectionCard(
                title: l.contactInformationSection,
                icon: Icons.contact_phone_outlined,
                child: Column(
                  children: [
                    _ContactDetailTile(
                      icon: Icons.phone_outlined,
                      label: l.phoneLabel,
                      value: patient.phone ?? l.noContactLabel,
                      canCopy: patient.phone != null,
                      onCopy: patient.phone != null
                          ? () => _copyToClipboard(
                                context,
                                patient.phone!,
                                l.copiedToClipboard,
                              )
                          : null,
                      onWhatsApp: patient.phone != null
                          ? () => _launchWhatsApp(context, patient.phone!)
                          : null,
                      onCall: patient.phone != null
                          ? () => _launchCall(context, patient.phone!)
                          : null,
                    ),
                    const Divider(height: 1),
                    _ContactDetailTile(
                      icon: Icons.email_outlined,
                      label: l.emailLabel,
                      value: patient.email ?? l.noContactLabel,
                      canCopy: patient.email != null,
                      onCopy: patient.email != null
                          ? () => _copyToClipboard(
                                context,
                                patient.email!,
                                l.copiedToClipboard,
                              )
                          : null,
                      onEmail: patient.email != null
                          ? () => _launchEmail(context, patient.email!)
                          : null,
                    ),
                    const Divider(height: 1),
                    _ContactDetailTile(
                      icon: Icons.cake_outlined,
                      label: l.birthInformationTitle,
                      value: _formatBirthInfo(patient, l),
                      canCopy: false,
                    ),
                  ],
                ),
              ),

              // 5. Parent / Guardian Section (if minor or details exist)
              if (patient.isMinorDeclared || patient.guardianName != null) ...[
                const SizedBox(height: AppSpacing.medium),
                _PatientSectionCard(
                  title: l.guardianInformationSection,
                  icon: Icons.shield_outlined,
                  child: Column(
                    children: [
                      if (patient.guardianName != null)
                        _ContactDetailTile(
                          icon: Icons.person_outline,
                          label: l.guardianNameLabel,
                          value: patient.guardianName!,
                          canCopy: true,
                          onCopy: () => _copyToClipboard(
                            context,
                            patient.guardianName!,
                            l.copiedToClipboard,
                          ),
                        ),
                      if (patient.guardianPhone != null) ...[
                        const Divider(height: 1),
                        _ContactDetailTile(
                          icon: Icons.phone_outlined,
                          label: l.guardianPhoneLabel,
                          value: patient.guardianPhone!,
                          canCopy: true,
                          onCopy: () => _copyToClipboard(
                            context,
                            patient.guardianPhone!,
                            l.copiedToClipboard,
                          ),
                          onWhatsApp: () => _launchWhatsApp(
                            context,
                            patient.guardianPhone!,
                          ),
                          onCall: () => _launchCall(
                            context,
                            patient.guardianPhone!,
                          ),
                        ),
                      ],
                      if (patient.guardianEmail != null) ...[
                        const Divider(height: 1),
                        _ContactDetailTile(
                          icon: Icons.email_outlined,
                          label: l.guardianEmailLabel,
                          value: patient.guardianEmail!,
                          canCopy: true,
                          onCopy: () => _copyToClipboard(
                            context,
                            patient.guardianEmail!,
                            l.copiedToClipboard,
                          ),
                          onEmail: () => _launchEmail(
                            context,
                            patient.guardianEmail!,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // 6. Administrative Notes (if exist)
              if (patient.administrativeNotes != null &&
                  patient.administrativeNotes!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.medium),
                _PatientSectionCard(
                  title: l.administrativeNotesLabel,
                  icon: Icons.note_alt_outlined,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Expanded(
                          child: Text(
                            patient.administrativeNotes!.trim(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmArchiveChange(
    BuildContext context,
    Patient patient,
  ) async {
    final l = AppLocalizations.of(context);
    final willArchive = !patient.isArchived;
    final approved = await showSettledDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          willArchive ? l.archivePatientQuestion : l.restorePatientQuestion,
        ),
        content: Text(
          willArchive
              ? l.archivePatientExplanation
              : l.restorePatientExplanation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(willArchive ? l.archiveLabel : l.restoreLabel),
          ),
        ],
      ),
    );
    if (approved != true || !context.mounted) return;

    final succeeded = await context.read<PatientCubit>().setArchived(
      patient.id,
      willArchive,
    );
    if (succeeded && context.mounted) context.go('/patients');
  }
}

class _ContactDetailTile extends StatelessWidget {
  const _ContactDetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.canCopy = false,
    this.onCopy,
    this.onWhatsApp,
    this.onCall,
    this.onEmail,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool canCopy;
  final VoidCallback? onCopy;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onCall != null)
                IconButton(
                  icon: const Icon(Icons.call_outlined, size: 18),
                  tooltip: l.callLabel,
                  onPressed: onCall,
                  visualDensity: VisualDensity.compact,
                ),
              if (onWhatsApp != null)
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  tooltip: l.whatsAppLabel,
                  color: const Color(0xFF25D366),
                  onPressed: onWhatsApp,
                  visualDensity: VisualDensity.compact,
                ),
              if (onEmail != null)
                IconButton(
                  icon: const Icon(Icons.email_outlined, size: 18),
                  tooltip: l.emailActionLabel,
                  onPressed: onEmail,
                  visualDensity: VisualDensity.compact,
                ),
              if (canCopy && onCopy != null)
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  tooltip: l.copyLabel,
                  onPressed: onCopy,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class PatientMedicalPage extends StatefulWidget {
  const PatientMedicalPage({required this.patientId, super.key});
  final String patientId;
  @override
  State<PatientMedicalPage> createState() => _PatientMedicalPageState();
}

class _PatientMedicalPageState extends State<PatientMedicalPage> {
  String? _loaded;
  final _allergies = TextEditingController();
  final _medications = TextEditingController();
  final _conditions = TextEditingController();
  final _notes = TextEditingController();
  @override
  void dispose() {
    _allergies.dispose();
    _medications.dispose();
    _conditions.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final roles =
        context.watch<ClinicCubit>().state.activeMembership?.roles ??
        const <String>{};
    final canRead =
        roles.contains('owner') ||
        roles.contains('dentist') ||
        roles.contains('assistant');
    final canEdit = roles.contains('dentist');
    if (!canRead) {
      return Scaffold(body: _PatientMessage(l.medicalRoleRestricted));
    }
    if (_loaded != widget.patientId) {
      _loaded = widget.patientId;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<PatientMedicalCubit>().load(widget.patientId),
      );
    }
    return WorkspacePage(
      title: Text(l.medicalProfileTitle),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/patients/${widget.patientId}'),
      ),
      maximumWidth: AppSpacing.contentWidth,
      scrollable: true,
      child: BlocBuilder<PatientMedicalCubit, PatientMedicalState>(
        builder: (context, state) {
          final profile = state.profile;
          if (profile != null && !state.saving) {
            _allergies.text = profile.allergies ?? '';
            _medications.text = profile.currentMedications ?? '';
            _conditions.text = profile.chronicConditions ?? '';
            _notes.text = profile.importantMedicalNotes ?? '';
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.loading) const LinearProgressIndicator(),
              if (state.loading) const SizedBox(height: AppSpacing.medium),
              TextField(
                controller: _allergies,
                enabled: canEdit && !state.saving,
                maxLines: 3,
                decoration: InputDecoration(labelText: l.allergiesLabel),
              ),
              const SizedBox(height: AppSpacing.medium),
              TextField(
                controller: _medications,
                enabled: canEdit && !state.saving,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l.currentMedicationsLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              TextField(
                controller: _conditions,
                enabled: canEdit && !state.saving,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l.chronicConditionsLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              TextField(
                controller: _notes,
                enabled: canEdit && !state.saving,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l.importantMedicalNotesLabel,
                ),
              ),
              if (canEdit) ...[
                const SizedBox(height: AppSpacing.large),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SizedBox(
                    width: AppBreakpoints.of(context) == AppLayoutClass.mobile
                        ? double.infinity
                        : 240,
                    child: FilledButton(
                      onPressed: state.saving
                          ? null
                          : () => context.read<PatientMedicalCubit>().save(
                              widget.patientId,
                              PatientMedicalProfile(
                                allergies: _allergies.text,
                                currentMedications: _medications.text,
                                chronicConditions: _conditions.text,
                                importantMedicalNotes: _notes.text,
                              ),
                            ),
                      child: Text(l.saveMedicalProfileLabel),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PatientMessage extends StatelessWidget {
  const _PatientMessage(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
  );
}

class _ResponsiveFieldGrid extends StatelessWidget {
  const _ResponsiveFieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 700 ? 2 : 1;
      final width =
          (constraints.maxWidth - AppSpacing.medium * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpacing.medium,
        runSpacing: AppSpacing.medium,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _PatientActionGrid extends StatelessWidget {
  const _PatientActionGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 500 ? 2 : 1;
      final width =
          (constraints.maxWidth - AppSpacing.small * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        children: [
          for (final child in children)
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: width,
                maxWidth: width,
                minHeight: 48,
              ),
              child: child,
            ),
        ],
      );
    },
  );
}

String _birthPrecisionLabel(BirthDatePrecision precision, AppLocalizations l) =>
    switch (precision) {
      BirthDatePrecision.unknown => l.birthPrecisionUnknown,
      BirthDatePrecision.exact => l.birthPrecisionExact,
      BirthDatePrecision.approximate => l.birthPrecisionApproximate,
    };
