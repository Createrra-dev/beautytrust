import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_title.dart';

enum PaymentWebViewResult {
	success,
	failure,
	cancelled,
}

class PaymentWebViewScreen extends StatefulWidget {
	const PaymentWebViewScreen({
		super.key,
		required this.paymentUrl,
	});

	final String paymentUrl;

	@override
	State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
	late final WebViewController _controller;
	var _isLoading = true;

	@override
	void initState() {
		super.initState();
		_controller = WebViewController()
			..setJavaScriptMode(JavaScriptMode.unrestricted)
			..setNavigationDelegate(
				NavigationDelegate(
					onPageStarted: (_) {
						if (mounted) {
							setState(() => _isLoading = true);
						}
					},
					onPageFinished: (_) {
						if (mounted) {
							setState(() => _isLoading = false);
						}
					},
					onNavigationRequest: (request) {
						final result = _resolveResult(request.url);
						if (result != null) {
							Navigator.of(context).pop(result);
							return NavigationDecision.prevent;
						}

						return NavigationDecision.navigate;
					},
				),
			)
			..loadRequest(Uri.parse(widget.paymentUrl));
	}

	PaymentWebViewResult? _resolveResult(String url) {
		if (url.contains(AppConfig.successReturnPath)) {
			return PaymentWebViewResult.success;
		}

		if (url.contains(AppConfig.failReturnPath)) {
			return PaymentWebViewResult.failure;
		}

		return null;
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: Row(
					mainAxisSize: MainAxisSize.min,
					children: const [
						AppLogo(size: 24),
						SizedBox(width: 8),
						BrandTitle(fontSize: 16),
					],
				),
				leading: IconButton(
					icon: const Icon(Icons.close, color: AppColors.textMuted),
					onPressed: () {
						Navigator.of(context).pop(PaymentWebViewResult.cancelled);
					},
				),
			),
			body: BrandBackground(
				child: Stack(
					children: [
						ClipRRect(
							borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
							child: WebViewWidget(controller: _controller),
						),
						if (_isLoading)
							const Center(
								child: CircularProgressIndicator(color: AppColors.primary),
							),
					],
				),
			),
		);
	}
}
