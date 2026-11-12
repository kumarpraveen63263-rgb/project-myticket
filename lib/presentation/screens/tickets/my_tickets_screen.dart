import '../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/ticket_model.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/ticket_provider.dart';
import '../../widgets/common/app_badge.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/cached_image_widget.dart';
import '../../widgets/common/shimmer_loader.dart';

class MyTicketsScreen extends ConsumerStatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  ConsumerState<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends ConsumerState<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ticketTabs.length,
      vsync: this,
      initialIndex: ref.read(ticketTabIndexProvider),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(ticketTabIndexProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsForTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingMedium,
                AppDimensions.paddingMedium,
                AppDimensions.paddingMedium,
                0,
              ),
              child: Text(
                context.tr('My Tickets'),
                style: AppTypography.displaySmall,
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.accentMovie,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.accentMovie,
              tabs: ticketTabs.map((t) => Tab(text: t.label)).toList(),
            ),
            Expanded(
              child: ticketsAsync.when(
                loading: () => ListView(
                  children: const [
                    ShimmerTicketCard(),
                    ShimmerTicketCard(),
                    ShimmerTicketCard(),
                  ],
                ),
                error: (_, _) => AppErrorWidget(
                  onRetry: () => ref.invalidate(allBookingsProvider),
                ),
                data: (tickets) {
                  if (tickets.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.confirmation_number_outlined,
                      title:
                          'No ${ticketTabs[ref.watch(ticketTabIndexProvider)].label.toLowerCase()} tickets',
                      subtitle: 'Your bookings will show up here',
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.accentMovie,
                    onRefresh: () async {
                      ref.invalidate(allBookingsProvider);
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.paddingMedium,
                        AppDimensions.paddingMedium,
                        AppDimensions.paddingMedium,
                        AppDimensions.bottomPadding,
                      ),
                      itemCount: tickets.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppDimensions.paddingMedium),
                      itemBuilder: (_, i) => _TicketTile(booking: tickets[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final BookingModel booking;

  const _TicketTile({required this.booking});

  Color get _accent {
    switch (booking.type) {
      case BookingType.movie:
        return AppColors.accentMovie;
      case BookingType.event:
        return AppColors.accentEvent;
      case BookingType.metro:
        return AppColors.accentMetro;
    }
  }

  Color get _statusColor {
    switch (booking.status) {
      case TicketStatus.upcoming:
        return AppColors.success;
      case TicketStatus.completed:
        return AppColors.info;
      case TicketStatus.cancelled:
        return AppColors.error;
      case TicketStatus.expired:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      onTap: () => context.push(
        booking.type == BookingType.metro
            ? '/metro/ticket/${booking.id}'
            : '/ticket/${booking.id}',
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedImageWidget(
              imageUrl: booking.imageUrl,
              width: 56,
              height: 72,
              fit: BoxFit.cover,
              borderRadius: AppDimensions.radiusSmall,
              category: booking.type == BookingType.movie
                  ? ImageCategory.movie
                  : booking.type == BookingType.event
                      ? ImageCategory.event
                      : ImageCategory.metro,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.title,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppDateUtils.formatDayMonth(booking.date)} · ${booking.time}',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    booking.venue,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '#${booking.bookingId}',
                    style: AppTypography.caption.copyWith(
                      color: _accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppBadge(label: booking.status.label, color: _statusColor),
                const SizedBox(height: 12),
                Text(
                  'View Ticket',
                  style: AppTypography.caption.copyWith(
                    color: _accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
