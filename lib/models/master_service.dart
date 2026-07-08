class MasterService {
	const MasterService({
		this.id,
		required this.name,
		required this.durationLabel,
		required this.price,
	});

	final int? id;
	final String name;
	final String durationLabel;
	final int price;
}
