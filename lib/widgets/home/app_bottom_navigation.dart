import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum AppTab {
	check,
	history,
	community,
	profile,
}

class AppBottomNavigation extends StatelessWidget {
	const AppBottomNavigation({
		super.key,
		required this.currentTab,
		required this.onTabSelected,
	});

	final AppTab currentTab;
	final ValueChanged<AppTab> onTabSelected;

	@override
	Widget build(BuildContext context) {
		return DecoratedBox(
			decoration: const BoxDecoration(
				color: AppColors.background,
				border: Border(
					top: BorderSide(color: AppColors.border),
				),
			),
			child: SafeArea(
				top: false,
				child: Padding(
					padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
					child: Row(
						children: [
							_buildItem(
								tab: AppTab.check,
								label: 'Проверка',
								icon: const _CheckTabIcon(),
							),
							_buildItem(
								tab: AppTab.history,
								label: 'История',
								icon: const Icon(Icons.schedule_outlined),
							),
							_buildItem(
								tab: AppTab.community,
								label: 'Сообщество',
								icon: const Icon(Icons.people_outline_rounded),
							),
							_buildItem(
								tab: AppTab.profile,
								label: 'Профиль',
								icon: const Icon(Icons.person_outline_rounded),
							),
						],
					),
				),
			),
		);
	}

	Widget _buildItem({
		required AppTab tab,
		required String label,
		required Widget icon,
	}) {
		final isActive = currentTab == tab;
		final color = isActive ? AppColors.primary : AppColors.textMuted;

		return Expanded(
			child: Material(
				color: Colors.transparent,
				child: InkWell(
					onTap: () => onTabSelected(tab),
					borderRadius: BorderRadius.circular(12),
					child: Padding(
						padding: const EdgeInsets.symmetric(vertical: 4),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								IconTheme(
									data: IconThemeData(color: color, size: 24),
									child: icon,
								),
								const SizedBox(height: 4),
								Text(
									label,
									style: TextStyle(
										color: color,
										fontSize: 12,
										fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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

class _CheckTabIcon extends StatelessWidget {
	const _CheckTabIcon();

	@override
	Widget build(BuildContext context) {
		final color = IconTheme.of(context).color ?? AppColors.textMuted;

		return SizedBox(
			width: 24,
			height: 24,
			child: Stack(
				alignment: Alignment.center,
				children: [
					Container(
						width: 22,
						height: 22,
						decoration: BoxDecoration(
							shape: BoxShape.circle,
							border: Border.all(color: color, width: 1.5),
						),
					),
					Icon(
						Icons.close_rounded,
						size: 14,
						color: color,
					),
				],
			),
		);
	}
}
