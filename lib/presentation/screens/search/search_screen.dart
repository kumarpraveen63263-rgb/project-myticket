import '../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/metro_model.dart';
import '../../../providers/metro_provider.dart';
import '../../../providers/search_provider.dart';
import '../../widgets/common/app_chip.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/home/event_card.dart';
import '../../widgets/home/movie_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String query) {
    if (query.trim().isEmpty) return;
    ref.read(recentSearchesProvider.notifier).add(query);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final tabIndex = ref.watch(searchTabIndexProvider);
    final results = ref.watch(searchResultsProvider);
    final recent = ref.watch(recentSearchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingSmall,
                AppDimensions.paddingMedium,
                AppDimensions.paddingMedium,
                AppDimensions.paddingMedium,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  ),
                  Expanded(
                    child: AppTextField(
                      controller: _controller,
                      hintText: 'Movies, Events, Metro...',
                      autofocus: true,
                      prefixIcon: Icons.search_rounded,
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _controller.clear();
                                ref.read(searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      onChanged: (v) =>
                          ref.read(searchQueryProvider.notifier).state = v,
                      validator: null,
                    ),
                  ),
                ],
              ),
            ),
            _tabBar(tabIndex),
            Expanded(
              child: query.trim().isEmpty
                  ? _idleState(recent)
                  : results.isEmpty
                  ? AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No results found',
                      subtitle: 'Try a different keyword',
                    )
                  : _resultsList(results, tabIndex),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBar(int tabIndex) {
    final tabs = [
      context.tr('All'),
      context.tr('Movies'),
      context.tr('Events'),
      context.tr('Metro'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => SizedBox(width: 8),
        itemBuilder: (context, i) => AppChip(
          label: tabs[i],
          isSelected: tabIndex == i,
          onTap: () => ref.read(searchTabIndexProvider.notifier).state = i,
        ),
      ),
    );
  }

  Widget _idleState(List<String> recent) {
    return ListView(
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('Recent Searches'),
                style: AppTypography.titleLarge,
              ),
              GestureDetector(
                onTap: () => ref.read(recentSearchesProvider.notifier).clear(),
                child: Text(
                  'Clear',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accentMovie,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.paddingSmall),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recent
                .map(
                  (q) => AppChip(
                    label: q,
                    icon: Icons.history_rounded,
                    onTap: () {
                      _controller.text = q;
                      ref.read(searchQueryProvider.notifier).state = q;
                    },
                  ),
                )
                .toList(),
          ),
          SizedBox(height: AppDimensions.paddingLarge),
        ],
        Text(context.tr('Trending Searches'), style: AppTypography.titleLarge),
        SizedBox(height: AppDimensions.paddingSmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: trendingSearches
              .map(
                (q) => AppChip(
                  label: q,
                  icon: Icons.trending_up_rounded,
                  accentColor: AppColors.accentOffer,
                  onTap: () {
                    _controller.text = q;
                    ref.read(searchQueryProvider.notifier).state = q;
                    _submit(q);
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _resultsList(SearchResults results, int tabIndex) {
    final showMovies = tabIndex == 0 || tabIndex == 1;
    final showEvents = tabIndex == 0 || tabIndex == 2;
    final showMetro = tabIndex == 0 || tabIndex == 3;

    return ListView(
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      children: [
        if (showMovies && results.movies.isNotEmpty) ...[
          Text(context.tr('Movies'), style: AppTypography.titleLarge),
          SizedBox(height: AppDimensions.paddingSmall),
          SizedBox(
            height: MovieCard.totalHeight(140),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: results.movies.length,
              separatorBuilder: (_, _) => SizedBox(width: 12),
              itemBuilder: (_, i) => MovieCard(movie: results.movies[i]),
            ),
          ),
          SizedBox(height: AppDimensions.paddingLarge),
        ],
        if (showEvents && results.events.isNotEmpty) ...[
          Text(context.tr('Events'), style: AppTypography.titleLarge),
          SizedBox(height: AppDimensions.paddingSmall),
          SizedBox(
            height: EventCard.totalHeight(),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: results.events.length,
              separatorBuilder: (_, _) => SizedBox(width: 12),
              itemBuilder: (_, i) => EventCard(event: results.events[i]),
            ),
          ),
          SizedBox(height: AppDimensions.paddingLarge),
        ],
        if (showMetro && results.stations.isNotEmpty) ...[
          Text(context.tr('Metro Stations'), style: AppTypography.titleLarge),
          SizedBox(height: AppDimensions.paddingSmall),
          ...results.stations.map((s) => _stationTile(s)),
        ],
        SizedBox(height: AppDimensions.bottomPadding),
      ],
    );
  }

  Widget _stationTile(MetroStationModel station) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.train_rounded, color: AppColors.accentMetro),
      title: Text(station.name, style: AppTypography.titleMedium),
      subtitle: Text(station.line.label, style: AppTypography.caption),
      onTap: () {
        ref.read(fromStationProvider.notifier).state = station.name;
        context.go('/metro');
      },
    );
  }
}
