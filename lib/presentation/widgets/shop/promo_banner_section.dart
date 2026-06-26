import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/mock_data.dart';

class PromoBannerSection extends StatefulWidget {
  const PromoBannerSection({super.key});
  @override
  State<PromoBannerSection> createState() => _PromoBannerSectionState();
}

class _PromoBannerSectionState extends State<PromoBannerSection> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    const banners = MockData.promoBanners;
    return Column(children: [
      CarouselSlider(
        options: CarouselOptions(
          height: 160,
          viewportFraction: 1.0,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 4),
          onPageChanged: (i, _) => setState(() => _current = i),
        ),
        items: banners.map((b) => _buildBannerItem(b)).toList(),
      ),
      const SizedBox(height: 8),
      AnimatedSmoothIndicator(
        activeIndex: _current,
        count: banners.length,
        effect: const WormEffect(dotHeight: 6, dotWidth: 6, activeDotColor: AppColors.primary, dotColor: AppColors.outlineVariant),
      ),
    ]);
  }

  Widget _buildBannerItem(Map<String, String> b) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
        children: [
          // Full background image
          Image.asset(
            b['image'] ?? 'assets/images/pho.jpg',
            fit: BoxFit.cover,
          ),
          // Dark gradient overlay for text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.2),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          // Text content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                  child: Text(b['tag'] ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(height: 6),
                Text(b['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                const SizedBox(height: 4),
                Text(b['desc'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xDDFFFFFF))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Xem ngay →', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
