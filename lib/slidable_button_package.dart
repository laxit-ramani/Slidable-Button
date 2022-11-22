library slidable_button_package;

import 'package:flutter/material.dart';
import 'package:slidable_button_package/button_clipper.dart';
import 'package:slidable_button_package/button_simulation.dart';

class AnimatedSlidableButton extends StatefulWidget {
  final Widget? label;
  final Widget? child;
  final Color? disabledColor;
  final Color? buttonColor;
  final Color? color;
  final BoxBorder? border;
  final BorderRadius borderRadius;
  final BorderRadius buttonBorderRadius;
  final double height;
  final double width;
  final double? buttonWidth;
  final double? buttonHeight;
  final EdgeInsets? padding;
  final bool dismissible;
  final ButtonPosition initialPosition;
  final double completeSlideAt;
  final ValueChanged<ButtonPosition>? onChanged;
  final AnimationController? controller;
  final bool isRestart;
  final bool tristate;
  final bool autoSlide;
  final bool isVertical;

  const AnimatedSlidableButton({
    Key? key,
    required this.onChanged,
    this.controller,
    this.child,
    this.autoSlide = true,
    this.disabledColor,
    this.buttonColor,
    this.color,
    this.label,
    this.border,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(10.0)),
    this.buttonBorderRadius = const BorderRadius.all(Radius.circular(10.0)),
    this.initialPosition = ButtonPosition.start,
    this.completeSlideAt = 0.5,
    this.height = 36.0,
    this.width = 120.0,
    this.buttonWidth,
    this.buttonHeight,
    this.isVertical = false,
    this.dismissible = true,
    this.isRestart = false,
    this.tristate = false,
  }) : super(key: key);

  @override
  State<AnimatedSlidableButton> createState() => _AnimatedSlidableButtonState();
}

class _AnimatedSlidableButtonState extends State<AnimatedSlidableButton>
    with SingleTickerProviderStateMixin {
  final GlobalKey _containerKey = GlobalKey();
  final GlobalKey _positionedKey = GlobalKey();

  late final AnimationController _controller;
  late Animation<double> _contentAnimation;
  Offset _start = Offset.zero;
  bool _isSliding = false;

  RenderBox? get _positioned =>
      _positionedKey.currentContext!.findRenderObject() as RenderBox?;

  RenderBox? get _container =>
      _containerKey.currentContext!.findRenderObject() as RenderBox?;

  double get _buttonWidth {
    final width = widget.buttonWidth ?? double.minPositive;
    final maxWidth = widget.width * 3 / 4;
    if (width > maxWidth) return maxWidth;
    return width;
  }

  double get _buttonHeight {
    final height = widget.buttonHeight ?? double.minPositive;
    final maxHeight = widget.height * 3 / 4;
    if (height > maxHeight) return maxHeight;
    return height;
  }

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? AnimationController.unbounded(vsync: this);
    _contentAnimation = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _initialPositionController();
  }

  void _initialPositionController() {
    if (widget.initialPosition == ButtonPosition.end) {
      _controller.value = 1.0;
    } else {
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: widget.border,
        borderRadius: widget.borderRadius,
      ),
      child: Stack(
        key: _containerKey,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: widget.borderRadius,
            ),
            child: widget.dismissible
                ? ClipRRect(
                    clipper: ButtonClipper(
                      animation: _controller,
                      borderRadius: widget.borderRadius,
                    ),
                    borderRadius: widget.borderRadius,
                    child: SizedBox.expand(
                      child: FadeTransition(
                        opacity: _contentAnimation,
                        child: widget.child,
                      ),
                    ),
                  )
                : SizedBox.expand(child: widget.child),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Align(
              alignment: widget.isVertical
                  ? Alignment(0.0, (_controller.value * 2.0) - 1.0)
                  : Alignment((_controller.value * 2.0) - 1.0, 0.0),
              child: child,
            ),
            child: Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: Container(
                key: _positionedKey,
                height: _buttonHeight,
                width: _buttonWidth,
                decoration: BoxDecoration(
                  borderRadius: widget.buttonBorderRadius,
                  color: widget.onChanged == null
                      ? widget.disabledColor ?? Colors.grey
                      : widget.buttonColor,
                ),
                child: widget.onChanged == null
                    ? Center(child: widget.label)
                    : GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragStart: _onDragStart,
                        onHorizontalDragUpdate: _onDragUpdate,
                        onHorizontalDragEnd: _onDragEnd,
                        child: Center(child: widget.label),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    final pos = _positioned!.globalToLocal(details.globalPosition);
    _start = widget.isVertical ? Offset(0.0, pos.dy) : Offset(pos.dx, 0.0);
    _controller.stop(canceled: true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final pos = widget.isVertical
        ? _container!.globalToLocal(details.globalPosition) - _start
        : _positioned!.globalToLocal(details.globalPosition);
    final extent = widget.isVertical
        ? _container!.size.height - _positioned!.size.height
        : _container!.size.width - _positioned!.size.width;
    _controller.value = widget.isVertical
        ? (pos.dy.clamp(0.0, extent) / extent)
        : (pos.dx.clamp(0.0, extent) / extent);

    if (widget.tristate && !_isSliding) {
      _isSliding = true;
      _onChanged(ButtonPosition.sliding);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.autoSlide) return _afterDragEnd();

    final extent = widget.isVertical
        ? _container!.size.height - _positioned!.size.height
        : _container!.size.width - _positioned!.size.width;
    double fractionalVelocity = (details.primaryVelocity! / extent).abs();
    if (fractionalVelocity < 0.5) {
      fractionalVelocity = 0.5;
    }

    double acceleration, velocity;
    if (_controller.value >= widget.completeSlideAt) {
      acceleration = 0.5;
      velocity = fractionalVelocity;
    } else {
      acceleration = -0.5;
      velocity = -fractionalVelocity;
    }

    final simulation = ButtonSimulation(
      acceleration,
      _controller.value,
      1.0,
      velocity,
    );

    _controller.animateWith(simulation).whenComplete(_afterDragEnd);
  }

  void _afterDragEnd() {
    ButtonPosition position =
        _controller.value <= .5 ? ButtonPosition.start : ButtonPosition.end;

    if (widget.isRestart && widget.initialPosition != position) {
      _initialPositionController();
    }

    _isSliding = false;

    _onChanged(position);
  }

  void _onChanged(ButtonPosition position) {
    if (widget.onChanged != null) {
      widget.onChanged!(position);
    }
  }
}

enum ButtonPosition {
  start,
  end,

  /// Only available if `tristate` is true
  sliding,
}
