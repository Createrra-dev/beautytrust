import 'package:flutter/material.dart';

import '../../models/client_profile.dart';
import '../../services/api/app_api_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/reviews/master_review_card.dart';

class MasterReviewsScreen extends StatefulWidget {
	const MasterReviewsScreen({super.key});

	static const routeName = '/profile-reviews';

	@override
	State<MasterReviewsScreen> createState() => _MasterReviewsScreenState();
}

class _MasterReviewsScreenState extends State<MasterReviewsScreen> {
	final _api = AppApiRepository();
	final List<MasterReview> _reviews = [];
	var _isLoading = true;
	String? _error;

	@override
	void initState() {
		super.initState();
		_load();
	}

	Future<void> _load() async {
		setState(() {
			_isLoading = true;
			_error = null;
		});

		try {
			final reviews = await _api.fetchProfileReviews();
			if (!mounted) {
				return;
			}
			setState(() {
				_reviews
					..clear()
					..addAll(reviews);
				_isLoading = false;
			});
		} catch (error) {
			if (!mounted) {
				return;
			}
			setState(() {
				_error = error.toString();
				_isLoading = false;
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		return SafeArea(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Padding(
						padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
						child: Row(
							children: [
								IconButton(
									onPressed: () => Navigator.of(context).pop(),
									icon: const Icon(Icons.arrow_back_ios_new_rounded),
								),
								const Expanded(
									child: Text(
										'Отзывы',
										textAlign: TextAlign.center,
										style: TextStyle(
											fontSize: 18,
											fontWeight: FontWeight.w600,
										),
									),
								),
								const SizedBox(width: 48),
							],
						),
					),
					Expanded(
						child: _isLoading
							? const Center(child: CircularProgressIndicator())
							: _error != null
								? Center(
									child: Text(
										_error!,
										style: const TextStyle(color: AppColors.error),
									),
								)
								: _reviews.isEmpty
									? const Center(
										child: Text(
											'Пока нет отзывов',
											style: TextStyle(color: AppColors.textMuted),
										),
									)
									: RefreshIndicator(
										onRefresh: _load,
										child: ListView.separated(
											padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
											itemCount: _reviews.length,
											separatorBuilder: (context, index) => const SizedBox(height: 12),
											itemBuilder: (context, index) {
												return MasterReviewCard(review: _reviews[index]);
											},
										),
									),
					),
				],
			),
		);
	}
}
