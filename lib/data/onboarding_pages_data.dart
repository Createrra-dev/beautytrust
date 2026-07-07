import '../models/onboarding_page.dart';
import '../widgets/app_logo.dart';

class OnboardingPagesData {
	OnboardingPagesData._();

	static const pages = <OnboardingPage>[
		OnboardingPage(imageAsset: AppAssets.onboarding1),
		OnboardingPage(imageAsset: AppAssets.onboarding2),
		OnboardingPage(imageAsset: AppAssets.onboarding3),
	];
}
