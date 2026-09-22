import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/value/money.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../clinic/domain/clinic_models.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../domain/standard_dental_procedures.dart';
import '../../domain/treatment_plan_models.dart';
import '../treatment_plan_cubit.dart';

class ProcedureCataloguePage extends StatefulWidget {
  const ProcedureCataloguePage({super.key});

  @override
  State<ProcedureCataloguePage> createState() => _ProcedureCataloguePageState();
}

class _ProcedureCataloguePageState extends State<ProcedureCataloguePage> {
  String? _loadedClinicId;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _activeOnly = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final value = _searchController.text.trim();
      if (_searchQuery != value) {
        setState(() => _searchQuery = value);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final clinicState = context.watch<ClinicCubit>().state;
    final clinic = clinicState.activeClinic;
    final canManage = clinicState.activeMembership?.isOwner ?? false;
    if (clinic == null) {
      return Scaffold(body: Center(child: Text(l.chooseClinicFirst)));
    }
    if (_loadedClinicId != clinic.id) {
      _loadedClinicId = clinic.id;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<TreatmentPlanCubit>().loadCatalogue(clinic.id),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l.procedureCatalogueTitle),
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/dashboard');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _editProcedure(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(l.newProcedureLabel),
            )
          : null,
      body: BlocConsumer<TreatmentPlanCubit, TreatmentPlanState>(
        listener: (context, state) {
          if (state.issue != null) {
            _showMessage(context, _issueMessage(state.issue!, l));
          }
        },
        builder: (context, state) {
          final allProcedures = state.procedures;
          final categories = allProcedures
              .map((p) => p.category.trim())
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()..sort();

          final filteredProcedures = allProcedures.where((p) {
            if (_activeOnly && !p.active) return false;
            if (_selectedCategory != null &&
                p.category.trim() != _selectedCategory) {
              return false;
            }
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final matchesName = p.name.toLowerCase().contains(query);
              final matchesCat = p.category.toLowerCase().contains(query);
              if (!matchesName && !matchesCat) return false;
            }
            return true;
          }).toList();

          final activeCount = allProcedures.where((p) => p.active).length;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.wideContentWidth,
              ),
              child: ListView(
                padding: AppInsets.page(AppBreakpoints.of(context)),
                children: [
                  _HeaderSummary(
                    clinic: clinic,
                    canManage: canManage,
                    totalCount: allProcedures.length,
                    activeCount: activeCount,
                    categoriesCount: categories.length,
                    onLoadStandardProcedures: () =>
                        _confirmAndLoadStandardProcedures(context, clinic.id),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  if (state.status == TreatmentPlanLoadStatus.loading ||
                      state.mutating)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.medium),
                      child: LinearProgressIndicator(),
                    ),
                  if (state.failure != null)
                    _MessageCard(
                      message: failureMessage(
                        state.failure!,
                        AppLocalizations.of(context),
                      ),
                    ),
                  if (state.status == TreatmentPlanLoadStatus.ready &&
                      allProcedures.isEmpty)
                    _EmptyCatalogueCard(
                      canManage: canManage,
                      onLoadStandards: () =>
                          _confirmAndLoadStandardProcedures(context, clinic.id),
                      onAddProcedure: () => _editProcedure(context),
                    )
                  else ...[
                    _FilterBar(
                      searchController: _searchController,
                      categories: categories,
                      selectedCategory: _selectedCategory,
                      activeOnly: _activeOnly,
                      onCategorySelected: (cat) =>
                          setState(() => _selectedCategory = cat),
                      onToggleActiveOnly: (val) =>
                          setState(() => _activeOnly = val),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    if (filteredProcedures.isEmpty)
                      _NoResultsCard(
                        onClearFilters: () {
                          setState(() {
                            _searchController.clear();
                            _selectedCategory = null;
                            _activeOnly = false;
                          });
                        },
                      )
                    else
                      for (final procedure in filteredProcedures)
                        _ProcedureCard(
                          procedure: procedure,
                          currencyCode: clinic.currencyCode,
                          canManage: canManage,
                          onEdit: () => _editProcedure(context, procedure),
                          onToggleActive: () => context
                              .read<TreatmentPlanCubit>()
                              .setProcedureActive(
                                procedure.id,
                                !procedure.active,
                              ),
                        ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmAndLoadStandardProcedures(
    BuildContext context,
    String clinicId,
  ) async {
    final l = AppLocalizations.of(context);
    final count = StandardDentalProcedures.defaults.length;
    final confirmed = await showSettledDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.loadStandardProcedures),
        content: DialogBody(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.loadStandardProceduresConfirm(count)),
              const SizedBox(height: AppSpacing.medium),
              Text(
                l.loadStandardProceduresHelp,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancelLabel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.playlist_add_rounded),
            label: Text(l.loadStandardProcedures),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final locale = Localizations.localeOf(context).languageCode;
      final drafts = StandardDentalProcedures.draftsForLocale(locale);
      final success = await context
          .read<TreatmentPlanCubit>()
          .createProceduresBatch(clinicId, drafts);
      if (context.mounted && success) {
        _showMessage(context, l.standardProceduresImported(count));
      }
    }
  }

  Future<void> _editProcedure(
    BuildContext context, [
    ClinicProcedure? existing,
  ]) async {
    final l = AppLocalizations.of(context);
    final form = GlobalKey<FormState>();
    final name = TextEditingController(text: existing?.name);
    final category = TextEditingController(text: existing?.category);
    final price = TextEditingController(
      text: existing?.defaultPrice.toDecimalString(),
    );
    final duration = TextEditingController(
      text: existing?.durationMinutes.toString() ?? '30',
    );

    final submitted = await showSettledDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? l.newProcedureLabel : l.editProcedureLabel,
          ),
          content: DialogBody(
            child: Form(
              key: form,
              child: SingleChildScrollView(
                child: DialogFormColumn(
                  children: [
                    TextFormField(
                      controller: name,
                      autofocus: existing == null,
                      maxLength: 120,
                      decoration: InputDecoration(
                        labelText: l.nameLabel,
                        prefixIcon: const Icon(Icons.title_rounded),
                      ),
                      validator: (value) => _required(value, l),
                    ),
                    TextFormField(
                      controller: category,
                      maxLength: 80,
                      decoration: InputDecoration(
                        labelText: l.categoryLabel,
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      validator: (value) => _required(value, l),
                    ),
                    TextFormField(
                      controller: price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l.standardPriceLabel,
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                      validator: (value) {
                        final amount = Money.tryParseUserInput(
                          value?.trim() ?? '',
                        );
                        return amount == null ? l.validPriceValidation : null;
                      },
                    ),
                    TextFormField(
                      controller: duration,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.durationMinutesLabel,
                        prefixIcon: const Icon(Icons.schedule_rounded),
                      ),
                      validator: (value) {
                        final minutes = int.tryParse(value?.trim() ?? '');
                        return minutes == null || minutes < 5 || minutes > 720
                            ? l.durationRangeValidation
                            : null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small,
                      children: [15, 30, 45, 60, 90].map((m) {
                        final isSelected = duration.text.trim() == '$m';
                        return ActionChip(
                          avatar: const Icon(Icons.timer_outlined, size: 16),
                          label: Text(l.durationMinutes(m)),
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          onPressed: () {
                            setDialogState(() {
                              duration.text = '$m';
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l.cancelLabel),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text(l.saveLabel),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      final draft = ProcedureDraft(
        name: name.text.trim(),
        category: category.text.trim(),
        defaultPrice: Money.tryParseUserInput(price.text)!,
        durationMinutes: int.parse(duration.text.trim()),
      );
      final cubit = context.read<TreatmentPlanCubit>();
      final clinicId = context.read<ClinicCubit>().state.activeClinicId;
      if (clinicId != null) {
        if (existing == null) {
          await cubit.createProcedure(clinicId, draft);
        } else {
          await cubit.updateProcedure(existing.id, draft);
        }
      }
    }
    name.dispose();
    category.dispose();
    price.dispose();
    duration.dispose();
  }

  String? _required(String? value, AppLocalizations l) =>
      value == null || value.trim().isEmpty ? l.requiredField : null;
}

class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({
    required this.clinic,
    required this.canManage,
    required this.totalCount,
    required this.activeCount,
    required this.categoriesCount,
    required this.onLoadStandardProcedures,
  });

  final Clinic clinic;
  final bool canManage;
  final int totalCount;
  final int activeCount;
  final int categoriesCount;
  final VoidCallback onLoadStandardProcedures;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 560;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.medical_services_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clinic.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                canManage
                                    ? l.procedureCatalogueOwnerHelp
                                    : l.procedureCatalogueViewerHelp,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isNarrow && canManage && totalCount > 0) ...[
                          const SizedBox(width: AppSpacing.small),
                          OutlinedButton.icon(
                            onPressed: onLoadStandardProcedures,
                            icon: const Icon(Icons.playlist_add_rounded),
                            label: Text(l.loadStandardProcedures),
                          ),
                        ],
                      ],
                    ),
                    if (isNarrow && canManage && totalCount > 0) ...[
                      const SizedBox(height: AppSpacing.medium),
                      OutlinedButton.icon(
                        onPressed: onLoadStandardProcedures,
                        icon: const Icon(Icons.playlist_add_rounded),
                        label: Text(l.loadStandardProcedures),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            const Divider(),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.medium,
              runSpacing: AppSpacing.small,
              children: [
                _StatBadge(
                  icon: Icons.format_list_bulleted_rounded,
                  label: l.totalProceduresCount(totalCount),
                  color: theme.colorScheme.primary,
                ),
                _StatBadge(
                  icon: Icons.check_circle_outline_rounded,
                  label: l.activeProceduresCount(activeCount),
                  color: Colors.teal,
                ),
                _StatBadge(
                  icon: Icons.category_outlined,
                  label: l.categoriesCount(categoriesCount),
                  color: Colors.indigo,
                ),
                _StatBadge(
                  icon: Icons.monetization_on_outlined,
                  label: '${clinic.currencyCode} · ${clinic.timeZone}',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizing.controlRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.categories,
    required this.selectedCategory,
    required this.activeOnly,
    required this.onCategorySelected,
    required this.onToggleActiveOnly,
  });

  final TextEditingController searchController;
  final List<String> categories;
  final String? selectedCategory;
  final bool activeOnly;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<bool> onToggleActiveOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: l.searchProceduresPlaceholder,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => searchController.clear(),
                  )
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text(l.allCategoriesLabel),
                selected: selectedCategory == null,
                onSelected: (selected) {
                  if (selected) onCategorySelected(null);
                },
              ),
              const SizedBox(width: AppSpacing.small),
              for (final cat in categories) ...[
                ChoiceChip(
                  label: Text(cat),
                  selected: selectedCategory == cat,
                  onSelected: (selected) {
                    onCategorySelected(selected ? cat : null);
                  },
                ),
                const SizedBox(width: AppSpacing.small),
              ],
              FilterChip(
                avatar: Icon(
                  activeOnly
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                ),
                label: Text(l.activeOnlyFilter),
                selected: activeOnly,
                onSelected: onToggleActiveOnly,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProcedureCard extends StatelessWidget {
  const _ProcedureCard({
    required this.procedure,
    required this.currencyCode,
    required this.canManage,
    required this.onEdit,
    required this.onToggleActive,
  });

  final ClinicProcedure procedure;
  final String currencyCode;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  (IconData, Color) _categoryStyle(String category, ColorScheme colorScheme) {
    final lower = category.toLowerCase();
    if (lower.contains('prevent') ||
        lower.contains('وقائ') ||
        lower.contains('профилакт') ||
        lower.contains('فحص') ||
        lower.contains('exam') ||
        lower.contains('диагност')) {
      return (Icons.health_and_safety_outlined, Colors.teal);
    }
    if (lower.contains('restor') ||
        lower.contains('حشو') ||
        lower.contains('ترميم') ||
        lower.contains('терап') ||
        lower.contains('пломб')) {
      return (Icons.brush_outlined, Colors.blue);
    }
    if (lower.contains('endo') ||
        lower.contains('عصب') ||
        lower.contains('جذور') ||
        lower.contains('пульп') ||
        lower.contains('канал')) {
      return (Icons.healing_outlined, Colors.purple);
    }
    if (lower.contains('surg') ||
        lower.contains('جراح') ||
        lower.contains('خلع') ||
        lower.contains('хирург') ||
        lower.contains('удал')) {
      return (Icons.content_cut_outlined, Colors.deepOrange);
    }
    if (lower.contains('prostho') ||
        lower.contains('تركيب') ||
        lower.contains('تعويض') ||
        lower.contains('ортопед') ||
        lower.contains('коронк')) {
      return (Icons.handyman_outlined, Colors.indigo);
    }
    if (lower.contains('perio') ||
        lower.contains('لثة') ||
        lower.contains('пародонт')) {
      return (Icons.spa_outlined, Colors.pink);
    }
    if (lower.contains('cosmetic') ||
        lower.contains('تجميل') ||
        lower.contains('эстет') ||
        lower.contains('отбелив')) {
      return (Icons.auto_awesome_outlined, Colors.amber.shade800);
    }
    return (Icons.medical_services_outlined, colorScheme.primary);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (icon, color) = _categoryStyle(procedure.category, theme.colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                procedure.active ? icon : Icons.block_flipped,
                color: procedure.active ? color : theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          procedure.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: procedure.active
                                ? null
                                : TextDecoration.lineThrough,
                            color: procedure.active
                                ? null
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        '${procedure.defaultPrice.toDecimalString()} $currencyCode',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: procedure.active
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: color.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          procedure.category,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l.durationMinutes(procedure.durationMinutes),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!procedure.active)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l.inactiveLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (canManage) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (action) {
                  if (action == 'edit') {
                    onEdit();
                  } else {
                    onToggleActive();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18),
                        const SizedBox(width: AppSpacing.small),
                        Text(l.editLabel),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          procedure.active
                              ? Icons.block_outlined
                              : Icons.check_circle_outline,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Text(
                          procedure.active
                              ? l.deactivateLabel
                              : l.activateLabel,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _EmptyCatalogueCard extends StatelessWidget {
  const _EmptyCatalogueCard({
    required this.canManage,
    required this.onLoadStandards,
    required this.onAddProcedure,
  });

  final bool canManage;
  final VoidCallback onLoadStandards;
  final VoidCallback onAddProcedure;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.medical_services_outlined,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              l.noProceduresCatalogue,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              l.loadStandardProceduresHelp,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (canManage) ...[
              const SizedBox(height: AppSpacing.large),
              Wrap(
                spacing: AppSpacing.medium,
                runSpacing: AppSpacing.small,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: onLoadStandards,
                    icon: const Icon(Icons.playlist_add_rounded),
                    label: Text(l.loadStandardProcedures),
                  ),
                  OutlinedButton.icon(
                    onPressed: onAddProcedure,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.newProcedureLabel),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoResultsCard extends StatelessWidget {
  const _NoResultsCard({required this.onClearFilters});

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              l.noMatchingProcedures,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.medium),
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear_all_rounded),
              label: Text(l.clearFiltersLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
  );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _issueMessage(
  TreatmentPlanOperationIssue issue,
  AppLocalizations l,
) => switch (issue) {
  TreatmentPlanOperationIssue.forbidden => l.treatmentForbiddenIssue,
  TreatmentPlanOperationIssue.unavailable => l.treatmentUnavailableIssue,
  TreatmentPlanOperationIssue.invalidInput => l.treatmentInvalidInputIssue,
  TreatmentPlanOperationIssue.draftOnly => l.treatmentDraftOnlyIssue,
  TreatmentPlanOperationIssue.activeRequired => l.treatmentActiveRequiredIssue,
  TreatmentPlanOperationIssue.itemsRequired => l.treatmentItemsRequiredIssue,
  TreatmentPlanOperationIssue.activePlanExists => l.activePlanExistsIssue,
  TreatmentPlanOperationIssue.invalidTransition =>
    l.treatmentInvalidTransitionIssue,
};
