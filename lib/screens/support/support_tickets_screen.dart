import 'package:flutter/material.dart';

import '../../services/support_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/support/support_ticket_card.dart';
import 'create_support_ticket_screen.dart';
import 'support_chat_screen.dart';

class SupportTicketsScreen extends StatefulWidget {
	const SupportTicketsScreen({super.key});

	static const routeName = '/support/tickets';

	@override
	State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
	final _searchController = TextEditingController();
	final _supportService = SupportService.instance;
	var _searchQuery = '';

	@override
	void initState() {
		super.initState();
		_supportService.addListener(_onSupportChanged);
		_searchController.addListener(_onSearchChanged);
	}

	@override
	void dispose() {
		_supportService.removeListener(_onSupportChanged);
		_searchController.removeListener(_onSearchChanged);
		_searchController.dispose();
		super.dispose();
	}

	void _onSupportChanged() {
		setState(() {});
	}

	void _onSearchChanged() {
		setState(() => _searchQuery = _searchController.text);
	}

	void _openCreateTicket() {
		Navigator.of(context).pushNamed(CreateSupportTicketScreen.routeName);
	}

	void _openTicket(String ticketId) {
		Navigator.of(context).pushNamed(
			SupportChatScreen.routeName,
			arguments: ticketId,
		);
	}

	@override
	Widget build(BuildContext context) {
		final referenceNow = DateTime.now();
		final tickets = _supportService.ticketsFor(_searchQuery);

		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					const _SupportHeader(),
					Padding(
						padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
						child: TextField(
							controller: _searchController,
							style: const TextStyle(color: AppColors.textPrimary),
							decoration: InputDecoration(
								hintText: 'Поиск по обращениям',
								hintStyle: const TextStyle(color: AppColors.textMuted),
								prefixIcon: const Icon(
									Icons.search_rounded,
									color: AppColors.textMuted,
								),
								filled: true,
								fillColor: AppColors.surface,
								border: OutlineInputBorder(
									borderRadius: BorderRadius.circular(12),
									borderSide: const BorderSide(color: AppColors.border),
								),
								enabledBorder: OutlineInputBorder(
									borderRadius: BorderRadius.circular(12),
									borderSide: const BorderSide(color: AppColors.border),
								),
								focusedBorder: OutlineInputBorder(
									borderRadius: BorderRadius.circular(12),
									borderSide: const BorderSide(color: AppColors.primary),
								),
								isDense: true,
								contentPadding: const EdgeInsets.symmetric(
									horizontal: 12,
									vertical: 12,
								),
							),
						),
					),
					Padding(
						padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
						child: _SupportPromoBanner(onCreateTicket: _openCreateTicket),
					),
					Expanded(
						child: tickets.isEmpty
							? const _EmptyTicketsState()
							: ListView.separated(
								padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
								itemCount: tickets.length,
								separatorBuilder: (context, index) =>
									const SizedBox(height: 10),
								itemBuilder: (context, index) {
									final ticket = tickets[index];

									return SupportTicketCard(
										ticket: ticket,
										referenceNow: referenceNow,
										onOpen: () => _openTicket(ticket.id),
									);
								},
							),
					),
				],
			),
		);
	}
}

class _SupportHeader extends StatelessWidget {
	const _SupportHeader();

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
			child: Row(
				children: [
					IconButton(
						onPressed: () => Navigator.of(context).pop(),
						icon: const Icon(
							Icons.arrow_back_ios_new_rounded,
							color: AppColors.textPrimary,
							size: 20,
						),
					),
					const Expanded(
						child: Text(
							'Техподдержка',
							textAlign: TextAlign.center,
							style: TextStyle(
								color: AppColors.textPrimary,
								fontSize: 18,
								fontWeight: FontWeight.w600,
							),
						),
					),
					IconButton(
						onPressed: () {
							Navigator.of(context).pushNamed(
								CreateSupportTicketScreen.routeName,
							);
						},
						icon: const Icon(
							Icons.add_circle_outline_rounded,
							color: AppColors.primary,
						),
					),
				],
			),
		);
	}
}

class _SupportPromoBanner extends StatelessWidget {
	const _SupportPromoBanner({required this.onCreateTicket});

	final VoidCallback onCreateTicket;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				gradient: LinearGradient(
					colors: [
						AppColors.primary.withValues(alpha: 0.9),
						AppColors.primary.withValues(alpha: 0.65),
					],
				),
				borderRadius: BorderRadius.circular(16),
			),
			child: Row(
				children: [
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Text(
									'Нужна помощь?',
									style: TextStyle(
										color: AppColors.textPrimary,
										fontSize: 18,
										fontWeight: FontWeight.w700,
									),
								),
								const SizedBox(height: 4),
								Text(
									'Обращения видны только вам и администраторам системы',
									style: TextStyle(
										color: AppColors.textPrimary.withValues(alpha: 0.85),
										fontSize: 13,
										height: 1.35,
									),
								),
							],
						),
					),
					const SizedBox(width: 12),
					FilledButton(
						onPressed: onCreateTicket,
						style: FilledButton.styleFrom(
							backgroundColor: AppColors.textPrimary,
							foregroundColor: AppColors.primary,
							minimumSize: const Size(0, 40),
							padding: const EdgeInsets.symmetric(horizontal: 16),
							textStyle: const TextStyle(
								fontSize: 14,
								fontWeight: FontWeight.w600,
							),
						),
						child: const Text('Создать'),
					),
				],
			),
		);
	}
}

class _EmptyTicketsState extends StatelessWidget {
	const _EmptyTicketsState();

	@override
	Widget build(BuildContext context) {
		return const Center(
			child: Padding(
				padding: EdgeInsets.symmetric(horizontal: 32),
				child: Text(
					'Обращения не найдены. Создайте новое, если нужна помощь.',
					textAlign: TextAlign.center,
					style: TextStyle(
						color: AppColors.textMuted,
						fontSize: 15,
						height: 1.4,
					),
				),
			),
		);
	}
}
