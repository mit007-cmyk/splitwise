import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../domain/entities/split_type.dart';
import '../bloc/add_expense_bloc.dart';
import '../bloc/add_expense_event.dart';
import '../bloc/add_expense_state.dart';
import '../widgets/split_editor.dart';

const _kSplitTypes = SplitType.values;
const _kSplitIcons = {
  SplitType.equally: Icons.people_alt_outlined,
  SplitType.unequally: Icons.edit_note_outlined,
  SplitType.percentage: Icons.pie_chart_outline,
  SplitType.shares: Icons.groups_outlined,
  SplitType.adjustment: Icons.tune_outlined,
};

/// Full-screen "Adjust split" flow: pick a split mode via the tab bar, then
/// fill in the per-person values for that mode. The tab controller only
/// drives which tab is visually selected — [AddExpenseBloc] is always the
/// source of truth for the active [SplitType].
class AdjustSplitPage extends StatefulWidget {
  const AdjustSplitPage({super.key});

  @override
  State<AdjustSplitPage> createState() => _AdjustSplitPageState();
}

class _AdjustSplitPageState extends State<AdjustSplitPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<AddExpenseBloc>();
    _tabController = TabController(
      length: _kSplitTypes.length,
      vsync: this,
      initialIndex: _kSplitTypes.indexOf(bloc.state.splitType),
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      bloc.add(SplitTypeChanged(_kSplitTypes[_tabController.index]));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Adjust split',
          style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          BlocBuilder<AddExpenseBloc, AddExpenseState>(
            buildWhen: (previous, current) => previous.splitError != current.splitError,
            builder: (context, state) {
              return IconButton(
                icon: Icon(Icons.check, color: state.splitError == null ? scheme.primary : scheme.error),
                onPressed: () => Navigator.of(context).pop(),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _kSplitTypes
              .map((type) => Tab(icon: Icon(_kSplitIcons[type]), text: type.label))
              .toList(),
        ),
      ),
      body: BlocBuilder<AddExpenseBloc, AddExpenseState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.lg.w,
                  AppDimensions.md.h,
                  AppDimensions.lg.w,
                  AppDimensions.sm.h,
                ),
                child: Text(
                  state.splitType.description,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              if (state.splitError != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w),
                  child: Text(
                    state.splitError!,
                    style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ),
              Expanded(child: SplitEditor(state: state)),
            ],
          );
        },
      ),
    );
  }
}
