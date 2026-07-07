import 'client_profile.dart';

class ClientCheckResult {
	const ClientCheckResult({
		required this.clientName,
		required this.profile,
	});

	final String clientName;
	final ClientProfile profile;
}
