import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';
import 'package:motion_tab_bar/helpers/HalfClipper.dart';
import 'package:motion_tab_bar/helpers/HalfPainter.dart';

import 'beauty_motion_tab_item.dart';

const int _animDuration = 300;

class BeautyMotionTabBar extends StatefulWidget {
	BeautyMotionTabBar({
		super.key,
		this.textStyle,
		this.tabIconColor = Colors.black,
		this.tabIconSize = 24,
		this.tabIconSelectedColor = Colors.white,
		this.tabIconSelectedSize = 24,
		this.tabSelectedColor = Colors.black,
		this.tabBarColor = Colors.white,
		this.tabBarHeight = 65,
		this.tabSize = 60,
		this.onTabItemSelected,
		required this.initialSelectedTab,
		required this.labels,
		this.icons,
		this.iconWidgets,
		this.useSafeArea = true,
		this.badges,
		this.controller,
	}) : assert(labels.contains(initialSelectedTab)),
		assert(icons != null && icons.length == labels.length),
		assert(iconWidgets == null || iconWidgets.length == labels.length),
		assert(badges == null || badges.length == labels.length);

	final Color? tabIconColor;
	final Color? tabIconSelectedColor;
	final Color? tabSelectedColor;
	final Color? tabBarColor;
	final double? tabIconSize;
	final double? tabIconSelectedSize;
	final double? tabBarHeight;
	final double? tabSize;
	final TextStyle? textStyle;
	final void Function(int index)? onTabItemSelected;
	final String initialSelectedTab;
	final List<String?> labels;
	final List<IconData>? icons;
	final List<Widget?>? iconWidgets;
	final bool useSafeArea;
	final List<Widget?>? badges;
	final MotionTabBarController? controller;

	@override
	State<BeautyMotionTabBar> createState() => _BeautyMotionTabBarState();
}

class _BeautyMotionTabBarState extends State<BeautyMotionTabBar>
		with TickerProviderStateMixin {
	late AnimationController _animationController;
	late Tween<double> _positionTween;
	late Animation<double> _positionAnimation;

	late AnimationController _fadeOutController;
	late Animation<double> _fadeFabOutAnimation;
	late Animation<double> _fadeFabInAnimation;

	late List<String?> _labels;
	late Map<String?, IconData> _icons;
	late Map<String?, Widget?> _iconWidgets;

	var _fabIconAlpha = 1.0;
	IconData? _activeIcon;
	Widget? _activeIconWidget;
	String? _selectedTab;
	Widget? _activeBadge;

	int get _tabAmount => _icons.keys.length;

	int get _index => _labels.indexOf(_selectedTab);

	double _getPosition(bool isRtl) {
		final pace = 2 / (_labels.length - 1);
		var position = (pace * _index) - 1;

		if (isRtl) {
			position = 1 - (pace * _index);
		}

		return position;
	}

	@override
	void initState() {
		super.initState();

		if (widget.controller != null) {
			widget.controller!.onTabChange = (index) {
				setState(() {
					_activeIcon = widget.icons![index];
					_activeIconWidget = widget.iconWidgets?[index];
					_selectedTab = widget.labels[index];
				});
				_initAnimationAndStart(
					_positionAnimation.value,
					_getPosition(Directionality.of(context).index == 0),
				);
			};
		}

		_labels = widget.labels;
		_icons = Map.fromIterable(
			_labels,
			key: (label) => label,
			value: (label) => widget.icons![_labels.indexOf(label)],
		);
		_iconWidgets = Map.fromIterable(
			_labels,
			key: (label) => label,
			value: (label) => widget.iconWidgets?[_labels.indexOf(label)],
		);

		_selectedTab = widget.initialSelectedTab;
		_activeIcon = _icons[_selectedTab];
		_activeIconWidget = _iconWidgets[_selectedTab];

		final selectedIndex = _labels.indexWhere(
			(element) => element == widget.initialSelectedTab,
		);
		_activeBadge = widget.badges?[selectedIndex];

		_animationController = AnimationController(
			duration: const Duration(milliseconds: _animDuration),
			vsync: this,
		);

		_fadeOutController = AnimationController(
			duration: Duration(milliseconds: _animDuration ~/ 5),
			vsync: this,
		);

		_positionTween = Tween<double>(
			begin: _getPosition(false),
			end: 1,
		);

		_positionAnimation = _positionTween.animate(
			CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
		)..addListener(() => setState(() {}));

		_fadeFabOutAnimation = Tween<double>(begin: 1, end: 0).animate(
			CurvedAnimation(parent: _fadeOutController, curve: Curves.easeOut),
		)
			..addListener(() {
				setState(() => _fabIconAlpha = _fadeFabOutAnimation.value);
			})
			..addStatusListener((status) {
				if (status == AnimationStatus.completed) {
					setState(() {
						_activeIcon = _icons[_selectedTab];
						_activeIconWidget = _iconWidgets[_selectedTab];
						final selectedIndex = _labels.indexWhere(
							(element) => element == _selectedTab,
						);
						_activeBadge = widget.badges?[selectedIndex];
					});
				}
			});

		_fadeFabInAnimation = Tween<double>(begin: 0, end: 1).animate(
			CurvedAnimation(
				parent: _animationController,
				curve: const Interval(0.8, 1, curve: Curves.easeOut),
			),
		)..addListener(() {
			setState(() => _fabIconAlpha = _fadeFabInAnimation.value);
		});
	}

	@override
	void dispose() {
		_animationController.dispose();
		_fadeOutController.dispose();
		super.dispose();
	}

	Widget _buildActiveIcon() {
		if (_activeIconWidget != null) {
			return _activeIconWidget!;
		}

		return Icon(
			_activeIcon,
			color: widget.tabIconSelectedColor,
			size: widget.tabIconSelectedSize,
		);
	}

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				color: widget.tabBarColor,
				boxShadow: const [
					BoxShadow(
						color: Colors.black12,
						offset: Offset(0, -1),
						blurRadius: 5,
					),
				],
			),
			child: SafeArea(
				bottom: widget.useSafeArea,
				child: Stack(
					alignment: Alignment.topCenter,
					children: [
						Container(
							height: widget.tabBarHeight,
							color: widget.tabBarColor,
							child: Row(
								mainAxisAlignment: MainAxisAlignment.spaceAround,
								children: _generateTabItems(),
							),
						),
						IgnorePointer(
							child: Align(
								heightFactor: 0,
								alignment: Alignment(_positionAnimation.value, 0),
								child: FractionallySizedBox(
									widthFactor: 1 / _tabAmount,
									child: Stack(
										alignment: Alignment.center,
										children: [
											SizedBox(
												height: widget.tabSize! + 30,
												width: widget.tabSize! + 30,
												child: ClipRect(
													clipper: HalfClipper(),
													child: Center(
														child: Container(
															width: widget.tabSize! + 10,
															height: widget.tabSize! + 10,
															decoration: BoxDecoration(
																color: widget.tabBarColor,
																shape: BoxShape.circle,
																boxShadow: const [
																	BoxShadow(
																		color: Colors.black12,
																		blurRadius: 8,
																	),
																],
															),
														),
													),
												),
											),
											SizedBox(
												height: widget.tabSize! + 15,
												width: widget.tabSize! + 35,
												child: CustomPaint(
													painter: HalfPainter(
														color: widget.tabBarColor,
													),
												),
											),
											SizedBox(
												height: widget.tabSize,
												width: widget.tabSize,
												child: DecoratedBox(
													decoration: BoxDecoration(
														shape: BoxShape.circle,
														color: widget.tabSelectedColor,
													),
													child: Opacity(
														opacity: _fabIconAlpha,
														child: Stack(
															alignment: Alignment.center,
															children: [
																_buildActiveIcon(),
																if (_activeBadge != null)
																	Positioned(
																		top: 0,
																		right: 0,
																		child: _activeBadge!,
																	),
															],
														),
													),
												),
											),
										],
									),
								),
							),
						),
					],
				),
			),
		);
	}

	List<Widget> _generateTabItems() {
		final isRtl = Directionality.of(context).index == 0;

		return _labels.map((tabLabel) {
			final icon = _icons[tabLabel];
			final iconWidget = _iconWidgets[tabLabel];
			final selectedIndex = _labels.indexWhere(
				(element) => element == tabLabel,
			);
			final badge = widget.badges?[selectedIndex];

			return BeautyMotionTabItem(
				selected: _selectedTab == tabLabel,
				iconData: icon,
				iconWidget: iconWidget,
				title: tabLabel,
				textStyle: widget.textStyle ?? const TextStyle(color: Colors.black),
				tabIconColor: widget.tabIconColor ?? Colors.black,
				tabIconSize: widget.tabIconSize,
				badge: badge,
				callbackFunction: () {
					setState(() {
						_activeIcon = icon;
						_activeIconWidget = iconWidget;
						_selectedTab = tabLabel;
						widget.onTabItemSelected?.call(_index);
					});
					_initAnimationAndStart(
						_positionAnimation.value,
						_getPosition(isRtl),
					);
				},
			);
		}).toList();
	}

	void _initAnimationAndStart(double from, double to) {
		_positionTween.begin = from;
		_positionTween.end = to;

		_animationController.reset();
		_fadeOutController.reset();
		_animationController.forward();
		_fadeOutController.forward();
	}
}
