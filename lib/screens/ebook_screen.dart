import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../widgets/assets.dart';
import '../widgets/entrance.dart';
import '../widgets/marquee_ticker.dart';
import '../widgets/primary_button.dart';
import '../widgets/wave.dart';

class EBookScreen extends StatelessWidget {
  const EBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final book = MockData.premiumBook;

    return Scaffold(
      backgroundColor: AppColors.yellow,
      drawer: const AppDrawer(),
      extendBody: true,
      bottomNavigationBar: const AppBottomNav(current: 2),
      body: Builder(
        builder: (context) => CustomScrollView(
          slivers: [
            SliverPinnedHeader(
              height: 220,
              child: WaveHeader(
                height: 220,
                greeting: 'Hello! Aster!',
                headline: 'Welcome to dodo premium book collection',
                onMenu: () => Scaffold.of(context).openDrawer(),
                avatar: const AssetImage(Img.avatar),
                onAvatarTap: () =>
                    AppRoutes.goToSection(context, AppRoutes.profile),
              ),
            ),
            const SliverToBoxAdapter(child: MarqueeTicker()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
              sliver: SliverList.list(
                children: staggered([
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(book.cover,
                                width: 150, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 150,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text('${book.priceBirr} birr',
                                style: const TextStyle(
                                    color: AppColors.yellow,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(book.title, style: AppTheme.h2),
                            const SizedBox(height: 8),
                            Text(
                              'Detailed explanations, real exam-style questions '
                              'and pass strategies — curated for the 2027 COC.',
                              style: AppTheme.body,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text('Subjects covered',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final s in book.subjects)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(s,
                              style: const TextStyle(
                                  color: AppColors.yellow,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Buy for ${book.priceBirr} birr',
                    withLogo: true,
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.payMethod,
                      arguments: ExamPack(
                        id: 'ebook',
                        title: book.title,
                        image: book.cover,
                        questionCount: 2800,
                        priceBirr: book.priceBirr,
                        freeLimit: 0,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
