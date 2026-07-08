class MasterService {
	const MasterService({
		this.id,
		required this.name,
		required this.durationLabel,
		required this.price,
		this.isOwned = false,
	});

	final int? id;
	final String name;
	final String durationLabel;
	final int price;
	final bool isOwned;
}
