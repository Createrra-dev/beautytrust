import '../models/client_profile.dart';

class DemoMasterReviews {
	DemoMasterReviews._();

	static const List<MasterReview> ekaterina = [
		MasterReview(
			masterName: 'Анна П.',
			rating: 4.8,
			text: 'Клиентка пришла вовремя, всё отлично',
			tag: 'Пунктуальная',
		),
		MasterReview(
			masterName: 'Мария К.',
			rating: 3.2,
			text: 'Перенесла запись 2 раза, без предупреждения, молчала накануне',
			tag: 'Молчаливая',
		),
		MasterReview(
			masterName: 'Ольга С.',
			rating: 4.5,
			text: 'Всегда вежливая, оставляет хорошие чаевые',
			tag: 'Вежливая',
		),
		MasterReview(
			masterName: 'Ирина Л.',
			rating: 4.1,
			text: 'Приходит заранее, благодарит за работу',
			tag: 'Пунктуальная',
		),
		MasterReview(
			masterName: 'Светлана Д.',
			rating: 3.6,
			text: 'Иногда опаздывает на 10–15 минут, но предупреждает',
			tag: 'Опаздывает',
		),
		MasterReview(
			masterName: 'Наталья В.',
			rating: 4.9,
			text: 'Один из лучших клиентов, рекомендую',
			tag: 'Надёжная',
		),
		MasterReview(
			masterName: 'Елена М.',
			rating: 2.8,
			text: 'Отменила запись в последний момент без объяснений',
			tag: 'Отмена',
		),
		MasterReview(
			masterName: 'Ксения Р.',
			rating: 3.9,
			text: 'Общительная, приятно работать',
			tag: 'Общительная',
		),
		MasterReview(
			masterName: 'Виктория Н.',
			rating: 4.3,
			text: 'Стабильно приходит на все записи',
			tag: 'Надёжная',
		),
		MasterReview(
			masterName: 'Дарья К.',
			rating: 2.1,
			text: 'Не ответила на напоминание за день до визита',
			tag: 'Молчаливая',
		),
		MasterReview(
			masterName: 'Юлия Ф.',
			rating: 4.7,
			text: 'Приятная в общении, всегда довольна результатом',
			tag: 'Вежливая',
		),
		MasterReview(
			masterName: 'Алина Т.',
			rating: 3.4,
			text: 'Просила скидку без предоплаты, в итоге пришла',
			tag: 'Торгуется',
		),
		MasterReview(
			masterName: 'Полина Г.',
			rating: 4.0,
			text: 'Нормальный клиент, без нареканий',
			tag: 'Спокойная',
		),
		MasterReview(
			masterName: 'Татьяна Б.',
			rating: 1.9,
			text: 'Опоздала на 35 минут, не извинилась',
			tag: 'Конфликтная',
		),
		MasterReview(
			masterName: 'Людмила Ш.',
			rating: 4.6,
			text: 'Записывается регулярно, всегда пунктуальна',
			tag: 'Постоянная',
		),
	];

	static const List<MasterReview> defaultSet = [
		MasterReview(
			masterName: 'Анна П.',
			rating: 4.5,
			text: 'Клиентка пришла вовремя, всё отлично',
			tag: 'Пунктуальная',
		),
		MasterReview(
			masterName: 'Мария К.',
			rating: 3.7,
			text: 'Перенесла запись один раз, предупредила заранее',
			tag: 'Вежливая',
		),
		MasterReview(
			masterName: 'Ольга С.',
			rating: 4.2,
			text: 'Приятная в общении, оставила отзыв',
			tag: 'Общительная',
		),
		MasterReview(
			masterName: 'Ирина Л.',
			rating: 2.9,
			text: 'Долго не отвечала на сообщения перед визитом',
			tag: 'Молчаливая',
		),
		MasterReview(
			masterName: 'Светлана Д.',
			rating: 4.8,
			text: 'Приходит заранее, благодарит за работу',
			tag: 'Надёжная',
		),
		MasterReview(
			masterName: 'Наталья В.',
			rating: 3.3,
			text: 'Опоздала на 20 минут, извинилась',
			tag: 'Опаздывает',
		),
		MasterReview(
			masterName: 'Елена М.',
			rating: 4.1,
			text: 'Стабильный клиент, рекомендую',
			tag: 'Постоянная',
		),
		MasterReview(
			masterName: 'Ксения Р.',
			rating: 2.4,
			text: 'Не пришла на запись, телефон был недоступен',
			tag: 'Неявка',
		),
		MasterReview(
			masterName: 'Виктория Н.',
			rating: 4.6,
			text: 'Всегда в хорошем настроении, приятно работать',
			tag: 'Вежливая',
		),
		MasterReview(
			masterName: 'Дарья К.',
			rating: 3.8,
			text: 'Иногда просит перенести, но всегда согласовывает',
			tag: 'Гибкая',
		),
		MasterReview(
			masterName: 'Юлия Ф.',
			rating: 1.7,
			text: 'Был конфликт из-за цены, клиентка ушла недовольная',
			tag: 'Конфликтная',
		),
		MasterReview(
			masterName: 'Алина Т.',
			rating: 4.4,
			text: 'Пунктуальная, аккуратная, приятная',
			tag: 'Пунктуальная',
		),
	];
}
