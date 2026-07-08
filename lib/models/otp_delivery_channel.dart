enum OtpDeliveryChannel {
	telegram,
	flashCall;

	String get apiValue {
		return switch (this) {
			OtpDeliveryChannel.telegram => 'telegram',
			OtpDeliveryChannel.flashCall => 'flash_call',
		};
	}

	static OtpDeliveryChannel fromApiValue(String value) {
		return switch (value) {
			'flash_call' => OtpDeliveryChannel.flashCall,
			_ => OtpDeliveryChannel.telegram,
		};
	}

	String get title {
		return switch (this) {
			OtpDeliveryChannel.telegram => 'Telegram',
			OtpDeliveryChannel.flashCall => 'Звонок',
		};
	}
}
