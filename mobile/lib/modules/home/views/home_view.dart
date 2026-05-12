import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../controllers/home_controller.dart';
import '../widgets/hero_deadline_card.dart';
import '../widgets/assistant_preview_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/recent_doc_row.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../navigation/main_navigation_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: () async => controller.refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildGreetingRow(context)),
            SliverToBoxAdapter(child: _buildHeroSection()),
            SliverToBoxAdapter(child: _buildAssistantSection()),
            SliverToBoxAdapter(child: _buildStatsSection()),
            SliverToBoxAdapter(child: _buildRecentDocsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 64, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formattedDate(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.text2,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Obx(() {
                final user = Get.find<AuthController>().currentUser.value;
                final name = user?.firstName ?? 'Marie';
                return Text(
                  'Bonjour, $name',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: -0.5,
                  ),
                );
              }),
            ],
          ),
          Obx(() {
            final user = Get.find<AuthController>().currentUser.value;
            return GestureDetector(
              onTap: () => _showAccountSheet(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AvatarWidget(
                  name: user?.fullName ?? 'Marie Martin',
                  size: 40,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Obx(() {
      final deadline = controller.nextDeadline.value;
      if (deadline == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: HeroDeadlineCard(deadline: deadline),
      );
    });
  }

  Widget _buildAssistantSection() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AssistantPreviewCard(),
    );
  }

  Widget _buildStatsSection() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: StatCard(
                value: '${controller.totalDocsThisMonth.value}',
                label: 'Documents ce mois',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                value: '${controller.upcomingDeadlinesCount.value}',
                label: 'Échéances à venir',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                value: '${controller.completionRate.value}%',
                label: 'Taux de complétude',
                accent: AppColors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDocsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DOCUMENTS RÉCENTS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text2,
                  letterSpacing: 0.6,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    Get.find<MainNavigationController>().goToDocuments(),
                child: const Text(
                  'Tout voir',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < controller.recentDocs.length; i++)
                    RecentDocRow(
                      doc: controller.recentDocs[i],
                      isLast: i == controller.recentDocs.length - 1,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const days = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]}';
  }

  void _showAccountSheet(BuildContext context) {
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    AvatarWidget(name: user?.fullName ?? 'Invité', size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Invité',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.companyName ?? user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.text2,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    auth.signOut();
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.redT,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.red.withAlpha(60)),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 16, color: AppColors.red),
                        SizedBox(width: 8),
                        Text(
                          'Se déconnecter',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
