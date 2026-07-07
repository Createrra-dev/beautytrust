import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../brand_background.dart';

class AuthScaffold extends StatelessWidget {
	const AuthScaffold({
		super.key,
		required this.body,
		this.showBackButton = false,
		this.centerBody = false,
	});

	final Widget body;
	final bool showBackButton;
	final bool centerBody;

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: BrandBackground(
				child: SafeArea(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							if (showBackButton)
								Align(
									alignment: Alignment.centerLeft,
									child: IconButton(
										onPressed: () => Navigator.of(context).maybePop(),
										icon: const Icon(
											Icons.arrow_back_ios_new_rounded,
											color: AppColors.textPrimary,
											size: 20,
										),
									),
								),
							Expanded(
								child: centerBody
									? Center(child: body)
									: body,
							),
						],
					),
				),
			),
		);
	}
}
