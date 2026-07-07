class AppConfig {
	AppConfig._();

	static const String apiBaseUrl = String.fromEnvironment(
		'API_BASE_URL',
		defaultValue: 'http://127.0.0.1:8000',
	);

	static const int paymentAmountKopecks = 1000;

	static const String successReturnPath = '/payments/return/success';
	static const String failReturnPath = '/payments/return/fail';
}
