import '../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/metro_model.dart';
import '../../../data/repositories/metro_repository.dart';
import '../../../providers/metro_provider.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/metro/station_chip.dart';

class StationSearchScreen extends ConsumerStatefulWidget {
  const StationSearchScreen({super.key});

  @override
  ConsumerState<StationSearchScreen> createState() =>
      _StationSearchScreenState();
}

class _StationSearchScreenState extends ConsumerState<StationSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allStations = ref.watch(metroStationsProvider);
    final filtered = _query.isEmpty
        ? allStations
        : allStations
              .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();

    final grouped = <String, List<MetroStationModel>>{};
    for (final s in filtered) {
      final letter = s.name[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(s);
    }
    final letters = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_rounded),
        ),
        title: Text(context.tr('Select Station')),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppDimensions.paddingMedium),
            child: AppTextField(
              controller: _controller,
              hintText: context.tr('Search stations'),
              autofocus: true,
              prefixIcon: Icons.search_rounded,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (_query.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr('Popular Stations'),
                  style: AppTypography.titleLarge,
                ),
              ),
            ),
          if (_query.isEmpty)
            Padding(
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MetroRepository.popularStations
                    .map(
                      (s) => StationChip(label: s, onTap: () => context.pop(s)),
                    )
                    .toList(),
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? AppEmptyState(
                    icon: Icons.location_off_outlined,
                    title: context.tr('No stations found'),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(
                      bottom: AppDimensions.bottomPadding,
                    ),
                    itemCount: letters.length,
                    itemBuilder: (context, i) {
                      final letter = letters[i];
                      final stations = grouped[letter]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppDimensions.paddingMedium,
                              AppDimensions.paddingMedium,
                              0,
                              4,
                            ),
                            child: Text(
                              letter,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.accentMetro,
                              ),
                            ),
                          ),
                          ...stations.map(
                            (s) => ListTile(
                              leading: Icon(
                                Icons.train_rounded,
                                color: AppColors.accentMetro,
                              ),
                              title: Text(
                                s.name,
                                style: AppTypography.bodyLarge,
                              ),
                              trailing: StationLineBadge(line: s.line),
                              onTap: () => context.pop(s.name),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
