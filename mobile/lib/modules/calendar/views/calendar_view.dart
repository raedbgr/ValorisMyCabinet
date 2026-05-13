import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/calendar_controller.dart';
import '../widgets/deadline_card.dart';

class CalendarView extends GetView<CalendarController> {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brand,
              onRefresh: () async => controller.refresh(),
              child: Obx(() {
                final hasAny = controller.urgent.isNotEmpty ||
                    controller.upcoming.isNotEmpty ||
                    controller.late.isNotEmpty ||
                    controller.complete.isNotEmpty;
                return CustomScrollView(
                  slivers: [
                    if (!hasAny)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    else ...[
                      SliverToBoxAdapter(child: _buildSections()),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 64, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Calendrier',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              letterSpacing: -0.7,
              height: 1.15,
            ),
          ),
          // Spacer to match the avatar size in the Documents screen header,
          // keeping the title's vertical position identical.
          SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }

  Widget _buildSections() {
    return Obx(() {
      final urgentList = [...controller.urgent, ...controller.upcoming];
      final lateList = controller.late;
      final completeList = controller.complete;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lateList.isNotEmpty) ...[
              _sectionLabel('En retard'),
              ...lateList.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DeadlineCard(deadline: d),
                  )),
            ],
            if (urgentList.isNotEmpty) ...[
              _sectionLabel('À venir'),
              ...urgentList.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DeadlineCard(deadline: d),
                  )),
            ],
            if (completeList.isNotEmpty) ...[
              _sectionLabel('Complétées'),
              ...completeList.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DeadlineCard(deadline: d),
                  )),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 48,
            color: AppColors.text3,
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucune échéance',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.text2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.text2,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
