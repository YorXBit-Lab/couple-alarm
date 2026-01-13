import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_note/presentation/themes/app_colors.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final List<SliderModel> slides = getSlides();
  final PageController _controller = PageController();
  int currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void nextPage() {
    if (currentIndex == slides.length - 1) {
      context.pushNamed('login');
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipPage() {
    _controller.animateToPage(
      slides.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double availableHeight = size.height - topPadding - bottomPadding;

    final double imageHeight = availableHeight * 0.52;
    final double contentHeight = availableHeight * 0.48;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            SizedBox(
              height: imageHeight,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() => currentIndex = index);
                },
                itemCount: slides.length,
                itemBuilder: (context, index) =>
                    _buildSlide(slides[index], imageHeight),
              ),
            ),

            SizedBox(
              height: contentHeight,
              child: _buildBottomContent(contentHeight),
            ),

            SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(SliderModel slide, double height) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: height * 0.8,
            maxWidth: double.infinity,
          ),
          child: Image.asset(
            slide.image,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: height * 0.6,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomContent(double height) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 12),

          _buildIndicators(),

          SizedBox(
            height: height * 0.4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: height * 0.18,
                  child: Center(
                    child: Text(
                      slides[currentIndex].title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                SizedBox(
                  height: height * 0.14,
                  child: Center(
                    child: Text(
                      slides[currentIndex].description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: height * 0.28,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: nextPage,
                    child: Text(
                      currentIndex == slides.length - 1
                          ? TransKeys.login.tr()
                          : TransKeys.continuee.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                if (currentIndex != slides.length - 1)
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: TextButton(
                      onPressed: skipPage,
                      child: Text(
                        TransKeys.skip.tr(),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildIndicators() {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          slides.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: currentIndex == index ? 24 : 8,
            decoration: BoxDecoration(
              color: currentIndex == index
                  ? AppColors.primary
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class SliderModel {
  final String image;
  final String title;
  final String description;

  SliderModel({
    required this.image,
    required this.title,
    required this.description,
  });
}

List<SliderModel> getSlides() => [
  SliderModel(
    image: "assets/images/onboard/notifications.png",
    title: TransKeys.welcome_to.tr() + ' ' + TransKeys.app_name.tr(),
    description: TransKeys.wc_subtitle.tr(),
  ),
  SliderModel(
    image: "assets/images/onboard/checklist.png",
    title: TransKeys.don_t_miss_anything.tr(),
    description: TransKeys.don_t_miss_anything_sub.tr(),
  ),
  SliderModel(
    image: "assets/images/onboard/connection.png",
    title: TransKeys.connect_to_lover.tr(),
    description: TransKeys.connect_to_lover_sub.tr(),
  ),
];
