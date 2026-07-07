import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/payment_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_title.dart';
import 'payment_webview_screen.dart';

class PaymentScreen extends StatefulWidget {
	const PaymentScreen({super.key});

	@override
	State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
	final PaymentApi _paymentApi = PaymentApi();

	var _isPaying = false;
	String? _statusMessage;
	var _lastPaymentSuccess = false;

	@override
	void initState() {
		super.initState();
		_statusMessage = 'Бэкенд: ${AppConfig.apiBaseUrl}';
	}

	Future<void> _pay() async {
		setState(() {
			_isPaying = true;
			_statusMessage = 'Создание платежа...';
			_lastPaymentSuccess = false;
		});

		try {
			final initResult = await _paymentApi.initPayment();

			if (!mounted) {
				return;
			}

			setState(() {
				_statusMessage = 'Открываем платежную форму...';
			});

			final webViewResult = await Navigator.of(context).push<PaymentWebViewResult>(
				MaterialPageRoute(
					builder: (context) => PaymentWebViewScreen(
						paymentUrl: initResult.paymentUrl,
					),
				),
			);

			if (!mounted) {
				return;
			}

			if (webViewResult == PaymentWebViewResult.cancelled) {
				setState(() {
					_statusMessage = 'Оплата отменена';
				});
				return;
			}

			setState(() {
				_statusMessage = 'Проверяем статус платежа...';
			});

			final statusResult = await _paymentApi.getPaymentStatus(initResult.paymentId);

			if (!mounted) {
				return;
			}

			if (statusResult.success) {
				await _showMessage(
					'Оплата успешна',
					'Статус: ${statusResult.status}\nOrderId: ${statusResult.orderId ?? initResult.orderId}',
				);
				setState(() {
					_statusMessage = 'Последний платеж: успешно (${statusResult.status})';
					_lastPaymentSuccess = true;
				});
				return;
			}

			await _showMessage(
				'Оплата не выполнена',
				'Статус: ${statusResult.status}',
			);
			setState(() {
				_statusMessage = 'Последний платеж: ${statusResult.status}';
			});
		} on PaymentApiException catch (error) {
			if (!mounted) {
				return;
			}

			await _showMessage('Ошибка', error.message);
			setState(() {
				_statusMessage = error.message;
			});
		} catch (error) {
			if (!mounted) {
				return;
			}

			await _showMessage('Ошибка', error.toString());
			setState(() {
				_statusMessage = error.toString();
			});
		} finally {
			if (mounted) {
				setState(() {
					_isPaying = false;
				});
			}
		}
	}

	Future<void> _showMessage(String title, String message) async {
		await showDialog<void>(
			context: context,
			builder: (context) => AlertDialog(
				title: Text(title),
				content: Text(message),
				actions: [
					TextButton(
						onPressed: () => Navigator.of(context).pop(),
						child: const Text('OK'),
					),
				],
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: Row(
					mainAxisSize: MainAxisSize.min,
					children: const [
						AppLogo(size: 28),
						SizedBox(width: 10),
						BrandTitle(),
					],
				),
			),
			body: BrandBackground(
				child: SafeArea(
					child: LayoutBuilder(
						builder: (context, constraints) {
							return SingleChildScrollView(
								padding: const EdgeInsets.all(24),
								child: ConstrainedBox(
									constraints: BoxConstraints(minHeight: constraints.maxHeight),
									child: Column(
										mainAxisAlignment: MainAxisAlignment.spaceBetween,
										crossAxisAlignment: CrossAxisAlignment.stretch,
										children: [
											const SizedBox(height: 8),
											Card(
												child: Padding(
													padding: const EdgeInsets.symmetric(
														horizontal: 24,
														vertical: 32,
													),
													child: Column(
														children: [
															const AppLogo(size: 96),
															const SizedBox(height: 16),
															const BrandTitle(fontSize: 32),
															const SizedBox(height: 12),
															const BrandSlogan(fontSize: 15),
															const SizedBox(height: 24),
															const GradientText(
																'10 ₽',
																style: TextStyle(
																	fontSize: 48,
																	fontWeight: FontWeight.w700,
																),
															),
															const SizedBox(height: 8),
															const Text(
																'тестовый платёж',
																textAlign: TextAlign.center,
																style: TextStyle(
																	fontSize: 14,
																	color: AppColors.textMuted,
																),
															),
														],
													),
												),
											),
											Column(
												crossAxisAlignment: CrossAxisAlignment.stretch,
												children: [
													if (_statusMessage != null) ...[
														const SizedBox(height: 20),
														Text(
															_statusMessage!,
															textAlign: TextAlign.center,
															style: TextStyle(
																color: _lastPaymentSuccess
																	? AppColors.secondary
																	: AppColors.textMuted,
															),
														),
													],
													const SizedBox(height: 24),
													FilledButton.icon(
														onPressed: _isPaying ? null : _pay,
														icon: _isPaying
															? const SizedBox(
																width: 20,
																height: 20,
																child: CircularProgressIndicator(
																	strokeWidth: 2,
																	color: AppColors.textPrimary,
																),
															)
															: const Icon(Icons.payment),
														label: Text(_isPaying ? 'Оплата...' : 'Оплатить'),
													),
													const SizedBox(height: 12),
													Text(
														'API: ${AppConfig.apiBaseUrl}',
														textAlign: TextAlign.center,
														style: const TextStyle(
															fontSize: 12,
															color: AppColors.textMuted,
														),
													),
												],
											),
										],
									),
								),
							);
						},
					),
				),
			),
		);
	}
}
