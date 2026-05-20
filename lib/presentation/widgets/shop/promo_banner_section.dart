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
    final banners = MockData.promoBanners;
    return Column(children: [
      CarouselSlider(
        options: CarouselOptions(
          height: 130,
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryHover], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(children: [
        Positioned(right: -20, top: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle))),
        Positioned(right: 60, bottom: -30, child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(4)),
                child: Text(b['tag'] ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(height: 4),
              Text(b['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
              const SizedBox(height: 2),
              Text(b['desc'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xE6FFFFFF))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                child: const Text('Xem ngay →', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ])),
            const SizedBox(width: 12),
            Text(b['emoji'] ?? '🍜', style: const TextStyle(fontSize: 52)),
          ]),
        ),
      ]),
    );
  }
}
