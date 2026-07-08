class RegistrationDraft {
	const RegistrationDraft({
		required this.firstName,
		required this.password,
		this.email,
	});

	final String firstName;
	final String password;
	final String? email;

	String? get normalizedEmail {
		final value = email?.trim();
		if (value == null || value.isEmpty) {
			return null;
		}
		return value;
	}
}
