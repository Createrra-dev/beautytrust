import '../models/master_service.dart';

class MasterServicesData {
	MasterServicesData._();

	static const services = <MasterService>[
		MasterService(
			name: 'Маникюр + покрытие',
			durationLabel: '2 ч',
			price: 2500,
		),
		MasterService(
			name: 'Стрижка и укладка',
			durationLabel: '1,5 ч',
			price: 3200,
		),
		MasterService(
			name: 'Окрашивание',
			durationLabel: '3 ч',
			price: 5800,
		),
		MasterService(
			name: 'Педикюр',
			durationLabel: '1,5 ч',
			price: 2800,
		),
		MasterService(
			name: 'Брови + ламинирование',
			durationLabel: '1 ч',
			price: 1900,
		),
		MasterService(
			name: 'Кератиновое выпрямление',
			durationLabel: '4 ч',
			price: 7500,
		),
		MasterService(
			name: 'Макияж',
			durationLabel: '1,5 ч',
			price: 3500,
		),
		MasterService(
			name: 'Наращивание ресниц',
			durationLabel: '2,5 ч',
			price: 4200,
		),
	];
}
