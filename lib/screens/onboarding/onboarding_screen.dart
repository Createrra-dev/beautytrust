import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/onboarding_pages_data.dart';
import '../../models/onboarding_page.dart';
import '../../services/onboarding_storage.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/onboarding/onboarding_page_view.dart';
import '../auth/phone_login_screen.dart';

class OnboardingScreen extends StatefulWidget {
	const OnboardingScreen({super.key});

	@override
	State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
	final _pageController = PageController();
	var _currentPage = 0;

	final List<OnboardingPage> _pages = OnboardingPagesData.pages;

	@override
	void dispose() {
		_pageController.dispose();
		super.dispose();
	}

	Future<void> _finishOnboarding() async {
		await OnboardingStorage.markCompleted();
		if (!mounted) {
			return;
		}

		Navigator.of(context).pushReplacement(
			MaterialPageRoute(
				builder: (context) => const PhoneLoginScreen(),
			),
		);
	}

	void _goToNextPage() {
		_pageController.nextPage(
			duration: const Duration(milliseconds: 400),
			curve: Curves.easeOutCubic,
		);
	}

	@override
	Widget build(BuildContext context) {
		final isLastPage = _currentPage == _pages.length - 1;

		return AnnotatedRegion<SystemUiOverlayStyle>(
			value: SystemUiOverlayStyle.light,
			child: Scaffold(
				body: BrandBackground(
					child: SafeArea(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								Align(
									alignment: Alignment.centerRight,
									child: TextButton(
										onPressed: _finishOnboarding,
										child: const Text(
											'Пропустить',
											style: TextStyle(
												color: AppColors.textMuted,
												fontSize: 16,
												fontWeight: FontWeight.w500,
											),
										),
									),
								),
								Expanded(
									child: PageView.builder(
										controller: _pageController,
										itemCount: _pages.length,
										onPageChanged: (page) {
											setState(() => _currentPage = page);
										},
										itemBuilder: (context, index) {
											return OnboardingPageView(
												page: _pages[index],
												pageIndex: index,
												pageCount: _pages.length,
											);
										},
									),
								),
								const SizedBox(height: 12),
								Row(
									mainAxisAlignment: MainAxisAlignment.center,
									children: List.generate(
										_pages.length,
										(index) => _PageIndicator(
											isActive: index == _currentPage,
										),
									),
								),
								const SizedBox(height: 20),
								Padding(
									padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
									child: isLastPage
										? FilledButton(
											onPressed: _finishOnboarding,
											child: const Text('Начать'),
										)
										: Align(
											alignment: Alignment.centerRight,
											child: TextButton.icon(
												onPressed: _goToNextPage,
												icon: const Icon(
													Icons.arrow_forward_rounded,
													color: AppColors.primary,
												),
												label: const Text(
													'Далее',
													style: TextStyle(
														color: AppColors.primary,
														fontSize: 18,
														fontWeight: FontWeight.w600,
													),
												),
											),
										),
								),
							],
						),
					),
				),
			),
		);
	}
}

class _PageIndicator extends StatelessWidget {
	const _PageIndicator({required this.isActive});

	final bool isActive;

	@override
	Widget build(BuildContext context) {
		return AnimatedContainer(
			duration: const Duration(milliseconds: 200),
			margin: const EdgeInsets.symmetric(horizontal: 4),
			height: 8,
			width: isActive ? 24 : 8,
			decoration: BoxDecoration(
				color: isActive ? AppColors.primary : AppColors.surfaceElevated,
				borderRadius: BorderRadius.circular(12),
				border: isActive
					? null
					: Border.all(color: AppColors.border),
			),
		);
	}
}
