import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/onboarding_pages_data.dart';
import '../../models/onboarding_page.dart';
import '../../services/onboarding_storage.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_background.dart';
import '../auth/phone_login_screen.dart';

class OnboardingScreen extends StatefulWidget {
	const OnboardingScreen({super.key});

	@override
	State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
	static const _pageCount = 3;

	final _pageController = PageController();
	var _currentPage = 0;

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
		final pages = OnboardingPagesData.pages;
		final isLastPage = _currentPage == _pageCount - 1;

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
										itemCount: _pageCount,
										onPageChanged: (page) {
											setState(() => _currentPage = page);
										},
										itemBuilder: (context, index) {
											return _OnboardingPageContent(
												page: pages[index],
											);
										},
									),
								),
								const SizedBox(height: 16),
								Row(
									mainAxisAlignment: MainAxisAlignment.center,
									children: List.generate(
										_pageCount,
										(index) => _PageIndicator(
											isActive: index == _currentPage,
										),
									),
								),
								const SizedBox(height: 24),
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

class _OnboardingPageContent extends StatelessWidget {
	const _OnboardingPageContent({required this.page});

	final OnboardingPage page;

	@override
	Widget build(BuildContext context) {
		if (page.hasImageLayout) {
			return _OnboardingImagePage(imageAsset: page.imageAsset!);
		}

		return Padding(
			padding: const EdgeInsets.symmetric(horizontal: 32),
			child: Column(
				children: [
					const Spacer(),
					_OnboardingIllustration(page: page),
					const SizedBox(height: 40),
					Text(
						page.title,
						textAlign: TextAlign.center,
						style: const TextStyle(
							color: AppColors.textPrimary,
							fontSize: 26,
							fontWeight: FontWeight.w700,
							height: 1.25,
						),
					),
					const SizedBox(height: 16),
					Text(
						page.description,
						textAlign: TextAlign.center,
						style: const TextStyle(
							color: AppColors.textMuted,
							fontSize: 16,
							height: 1.5,
						),
					),
					const Spacer(flex: 2),
				],
			),
		);
	}
}

class _OnboardingImagePage extends StatelessWidget {
	const _OnboardingImagePage({required this.imageAsset});

	final String imageAsset;

	@override
	Widget build(BuildContext context) {
		return LayoutBuilder(
			builder: (context, constraints) {
				return SingleChildScrollView(
					padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
					child: Image.asset(
						imageAsset,
						width: constraints.maxWidth,
						fit: BoxFit.fitWidth,
					),
				);
			},
		);
	}
}

class _OnboardingIllustration extends StatelessWidget {
	const _OnboardingIllustration({required this.page});

	final OnboardingPage page;

	@override
	Widget build(BuildContext context) {
		final accentColor = page.accentColor ?? AppColors.primary;
		final icon = page.icon ?? Icons.star_outline;

		return Container(
			width: 220,
			height: 220,
			decoration: BoxDecoration(
				shape: BoxShape.circle,
				gradient: RadialGradient(
					colors: [
						accentColor.withValues(alpha: 0.35),
						accentColor.withValues(alpha: 0.08),
						Colors.transparent,
					],
					stops: const [0.2, 0.6, 1.0],
				),
			),
			child: Center(
				child: Container(
					width: 140,
					height: 140,
					decoration: BoxDecoration(
						color: AppColors.surface,
						borderRadius: BorderRadius.circular(36),
						border: Border.all(
							color: accentColor.withValues(alpha: 0.4),
						),
						boxShadow: [
							BoxShadow(
								color: accentColor.withValues(alpha: 0.2),
								blurRadius: 32,
								spreadRadius: 4,
							),
						],
					),
					child: Icon(
						icon,
						size: 64,
						color: accentColor,
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
