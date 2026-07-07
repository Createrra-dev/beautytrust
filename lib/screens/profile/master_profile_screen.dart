import 'package:flutter/material.dart';

import '../../models/appointment_record.dart';
import '../../models/master_profile.dart';
import '../../services/master_avatar_service.dart';
import '../../services/master_profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/profile/avatar_picker_sheet.dart';
import '../../widgets/profile/master_avatar.dart';
import '../../widgets/profile/profile_menu_item.dart';
import '../support/support_tickets_screen.dart';
import 'tariffs_screen.dart';

class MasterProfileScreen extends StatefulWidget {
	const MasterProfileScreen({super.key});

	@override
	State<MasterProfileScreen> createState() => _MasterProfileScreenState();
}

class _MasterProfileScreenState extends State<MasterProfileScreen> {
	final _avatarService = MasterAvatarService.instance;

	@override
	void initState() {
		super.initState();
		_avatarService.addListener(_onAvatarChanged);
		_avatarService.load();
	}

	@override
	void dispose() {
		_avatarService.removeListener(_onAvatarChanged);
		super.dispose();
	}

	void _onAvatarChanged() {
		setState(() {});
	}

	Future<void> _pickAvatar() async {
		final action = await showAvatarPickerSheet(context);
		if (!mounted || action == null) {
			return;
		}

		final saved = switch (action) {
			AvatarPickerAction.camera => await _avatarService.pickFromCamera(),
			AvatarPickerAction.gallery => await _avatarService.pickFromGallery(),
		};

		if (!mounted || !saved) {
			return;
		}

		AppSnackBar.show(
			context,
			'Фото профиля обновлено',
			type: AppSnackBarType.success,
		);
	}

	@override
	Widget build(BuildContext context) {
		final profile = MasterProfileService.currentMaster;

		return SafeArea(
			child: SingleChildScrollView(
				padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						const _ProfileHeader(),
						const SizedBox(height: 24),
						_ProfileHero(
							profile: profile,
							avatarPath: _avatarService.avatarPath,
							isAvatarLoading: _avatarService.isLoading,
							onAvatarTap: _pickAvatar,
						),
						const SizedBox(height: 24),
						_ProfileStatsRow(profile: profile),
						const SizedBox(height: 20),
						_ProfileMenuCard(
							onItemTap: (item) => _onMenuTap(context, item),
							tariffLabel: profile.tariffLabel,
						),
					],
				),
			),
		);
	}

	void _onMenuTap(BuildContext context, MasterProfileMenuItem item) {
		if (item == MasterProfileMenuItem.tariff) {
			Navigator.of(context).pushNamed(TariffsScreen.routeName);
			return;
		}

		if (item == MasterProfileMenuItem.support) {
			Navigator.of(context).pushNamed(SupportTicketsScreen.routeName);
			return;
		}

		AppSnackBar.show(
			context,
			'«${item.title}» скоро будет доступно',
		);
	}
}

class _ProfileHeader extends StatelessWidget {
	const _ProfileHeader();

	@override
	Widget build(BuildContext context) {
		return const Padding(
			padding: EdgeInsets.symmetric(vertical: 8),
			child: Text(
				'Профиль мастера',
				textAlign: TextAlign.center,
				style: TextStyle(
					color: AppColors.textPrimary,
					fontSize: 18,
					fontWeight: FontWeight.w600,
				),
			),
		);
	}
}

class _ProfileHero extends StatelessWidget {
	const _ProfileHero({
		required this.profile,
		required this.avatarPath,
		required this.isAvatarLoading,
		required this.onAvatarTap,
	});

	final MasterProfile profile;
	final String? avatarPath;
	final bool isAvatarLoading;
	final VoidCallback onAvatarTap;

	@override
	Widget build(BuildContext context) {
		return Column(
			children: [
				MasterAvatar(
					firstName: profile.firstName,
					avatarPath: avatarPath,
					isLoading: isAvatarLoading,
					onTap: onAvatarTap,
				),
				const SizedBox(height: 14),
				Text(
					profile.firstName,
					style: const TextStyle(
						color: AppColors.textPrimary,
						fontSize: 22,
						fontWeight: FontWeight.w700,
					),
				),
				const SizedBox(height: 10),
				Container(
					padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
					decoration: BoxDecoration(
						color: AppColors.secondary.withValues(alpha: 0.12),
						borderRadius: BorderRadius.circular(20),
						border: Border.all(
							color: AppColors.secondary.withValues(alpha: 0.35),
						),
					),
					child: Text(
						profile.badgeLabel,
						style: const TextStyle(
							color: AppColors.secondary,
							fontSize: 13,
							fontWeight: FontWeight.w600,
						),
					),
				),
				const SizedBox(height: 10),
				Row(
					mainAxisSize: MainAxisSize.min,
					children: [
						const Icon(
							Icons.star_rounded,
							size: 18,
							color: AppColors.secondary,
						),
						const SizedBox(width: 4),
						Text(
							'${formatAppointmentRating(profile.rating)} (${profile.reviewsCount} отзывов)',
							style: const TextStyle(
								color: AppColors.secondary,
								fontSize: 14,
								fontWeight: FontWeight.w600,
							),
						),
					],
				),
			],
		);
	}
}

class _ProfileStatsRow extends StatelessWidget {
	const _ProfileStatsRow({required this.profile});

	final MasterProfile profile;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: AppColors.border),
			),
			child: IntrinsicHeight(
				child: Row(
					children: [
						Expanded(
							child: _StatColumn(
								value: '${profile.clientsCount}',
								label: 'Клиентов',
							),
						),
						const _VerticalDivider(),
						Expanded(
							child: _StatColumn(
								value: '${profile.preventedNoShows}',
								label: 'Неявок избежано',
							),
						),
						const _VerticalDivider(),
						Expanded(
							child: _StatColumn(
								value: formatServicePrice(profile.protectedIncome),
								label: 'Защищено',
							),
						),
					],
				),
			),
		);
	}
}

class _VerticalDivider extends StatelessWidget {
	const _VerticalDivider();

	@override
	Widget build(BuildContext context) {
		return Container(
			width: 1,
			margin: const EdgeInsets.symmetric(horizontal: 4),
			color: AppColors.border,
		);
	}
}

class _StatColumn extends StatelessWidget {
	const _StatColumn({
		required this.value,
		required this.label,
	});

	final String value;
	final String label;

	@override
	Widget build(BuildContext context) {
		return Column(
			mainAxisSize: MainAxisSize.min,
			children: [
				Text(
					value,
					textAlign: TextAlign.center,
					maxLines: 1,
					overflow: TextOverflow.ellipsis,
					style: const TextStyle(
						color: AppColors.textPrimary,
						fontSize: 18,
						fontWeight: FontWeight.w700,
					),
				),
				const SizedBox(height: 6),
				Text(
					label,
					textAlign: TextAlign.center,
					style: const TextStyle(
						color: AppColors.textMuted,
						fontSize: 12,
						height: 1.2,
					),
				),
			],
		);
	}
}

class _ProfileMenuCard extends StatelessWidget {
	const _ProfileMenuCard({
		required this.onItemTap,
		required this.tariffLabel,
	});

	final ValueChanged<MasterProfileMenuItem> onItemTap;
	final String tariffLabel;

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: AppColors.border),
			),
			child: Column(
				children: [
					ProfileMenuItem(
						icon: Icons.bar_chart_rounded,
						title: MasterProfileMenuItem.statistics.title,
						onTap: () => onItemTap(MasterProfileMenuItem.statistics),
					),
					const Divider(color: AppColors.border, height: 1),
					ProfileMenuItem(
						icon: Icons.chat_bubble_outline_rounded,
						title: MasterProfileMenuItem.reviews.title,
						onTap: () => onItemTap(MasterProfileMenuItem.reviews),
					),
					const Divider(color: AppColors.border, height: 1),
					ProfileMenuItem(
						icon: Icons.workspace_premium_outlined,
						title: MasterProfileMenuItem.tariff.title,
						trailingLabel: tariffLabel,
						onTap: () => onItemTap(MasterProfileMenuItem.tariff),
					),
					const Divider(color: AppColors.border, height: 1),
					ProfileMenuItem(
						icon: Icons.settings_outlined,
						title: MasterProfileMenuItem.settings.title,
						onTap: () => onItemTap(MasterProfileMenuItem.settings),
					),
					const Divider(color: AppColors.border, height: 1),
					ProfileMenuItem(
						icon: Icons.info_outline_rounded,
						title: MasterProfileMenuItem.support.title,
						onTap: () => onItemTap(MasterProfileMenuItem.support),
					),
				],
			),
		);
	}
}
