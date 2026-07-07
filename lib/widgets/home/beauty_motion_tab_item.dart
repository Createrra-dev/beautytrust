import 'package:flutter/material.dart';

const double _iconOff = -3;
const double _iconOn = 0;
const double _textOff = 3;
const double _textOn = 1;
const double _alphaOff = 0;
const double _alphaOn = 1;
const int _animDuration = 300;

class BeautyMotionTabItem extends StatefulWidget {
	const BeautyMotionTabItem({
		super.key,
		required this.title,
		required this.selected,
		required this.textStyle,
		required this.tabIconColor,
		required this.callbackFunction,
		this.iconData,
		this.iconWidget,
		this.tabIconSize = 24,
		this.badge,
	});

	final String? title;
	final bool selected;
	final IconData? iconData;
	final Widget? iconWidget;
	final TextStyle textStyle;
	final VoidCallback callbackFunction;
	final Color tabIconColor;
	final double? tabIconSize;
	final Widget? badge;

	@override
	State<BeautyMotionTabItem> createState() => _BeautyMotionTabItemState();
}

class _BeautyMotionTabItemState extends State<BeautyMotionTabItem> {
	var _iconYAlign = _iconOn;
	var _textYAlign = _textOff;
	var _iconAlpha = _alphaOn;

	@override
	void initState() {
		super.initState();
		_setIconTextAlpha();
	}

	@override
	void didUpdateWidget(BeautyMotionTabItem oldWidget) {
		super.didUpdateWidget(oldWidget);
		_setIconTextAlpha();
	}

	void _setIconTextAlpha() {
		setState(() {
			_iconYAlign = widget.selected ? _iconOff : _iconOn;
			_textYAlign = widget.selected ? _textOn : _textOff;
			_iconAlpha = widget.selected ? _alphaOff : _alphaOn;
		});
	}

	Widget _buildIcon() {
		if (widget.iconWidget != null) {
			return widget.iconWidget!;
		}

		return Icon(
			widget.iconData,
			color: widget.tabIconColor,
			size: widget.tabIconSize,
		);
	}

	@override
	Widget build(BuildContext context) {
		return Expanded(
			child: Stack(
				fit: StackFit.expand,
				children: [
					Container(
						height: double.infinity,
						width: double.infinity,
						alignment: Alignment.center,
						child: AnimatedAlign(
							duration: const Duration(milliseconds: _animDuration),
							alignment: Alignment(0, _textYAlign),
							child: Padding(
								padding: const EdgeInsets.all(8),
								child: widget.selected
									? Text(
										widget.title!,
										style: widget.textStyle,
										softWrap: false,
										maxLines: 1,
										textAlign: TextAlign.center,
									)
									: const Text(''),
							),
						),
					),
					InkWell(
						onTap: widget.callbackFunction,
						child: SizedBox(
							height: double.infinity,
							width: double.infinity,
							child: AnimatedAlign(
								duration: const Duration(milliseconds: _animDuration),
								curve: Curves.easeIn,
								alignment: Alignment(0, _iconYAlign),
								child: AnimatedOpacity(
									duration: const Duration(milliseconds: _animDuration),
									opacity: _iconAlpha,
									child: Stack(
										alignment: Alignment.center,
										children: [
											IconButton(
												highlightColor: Colors.transparent,
												splashColor: Colors.transparent,
												padding: EdgeInsets.zero,
												icon: _buildIcon(),
												onPressed: widget.callbackFunction,
											),
											if (widget.badge != null)
												Positioned(
													top: 0,
													right: 0,
													child: widget.badge!,
												),
										],
									),
								),
							),
						),
					),
				],
			),
		);
	}
}
