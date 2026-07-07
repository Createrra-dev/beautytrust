import '../widgets/home/app_bottom_navigation.dart';

class MainShellNavigation {
	MainShellNavigation._();

	static final MainShellNavigation instance = MainShellNavigation._();

	void Function(int index)? _selectTab;

	void register(void Function(int index) selectTab) {
		_selectTab = selectTab;
	}

	void unregister() {
		_selectTab = null;
	}

	void goToHome() {
		_selectTab?.call(AppBottomNavigation.homeTabIndex);
	}
}
