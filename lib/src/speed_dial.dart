import 'package:flutter/material.dart';

import 'animated_child.dart';
import 'animated_floating_button.dart';
import 'background_overlay.dart';
import 'speed_dial_child.dart';
import 'speed_dial_orientation.dart';

/// Builds the Speed Dial
// ignore: must_be_immutable
class SpeedDial extends StatefulWidget {
  /// Children buttons, from the lowest to the highest.
  final List<SpeedDialChild> children;

  /// Used to get the button hidden on scroll. See examples for more info.
  final bool visible;

  /// The curve used to animate the button on scrolling.
  final Curve curve;

  final String tooltip;
  final String heroTag;
  final Color backgroundColor;
  final Color foregroundColor;
  final double elevation;
  final double buttonSize;
  final ShapeBorder shape;

  final double marginEnd;
  final double marginBottom;

  /// The color of the background overlay.
  final Color overlayColor;

  /// The opacity of the background overlay when the dial is open.
  final double overlayOpacity;

  /// The animated icon to show as the main button child. If this is provided the [child] is ignored.
  final AnimatedIconData animatedIcon;

  /// The theme for the animated icon.
  final IconThemeData animatedIconTheme;

  /// The icon of the main button, ignored if [animatedIcon] is non [null].
  final IconData icon;

  /// The active icon of the main button, Defaults to icon if not specified, ignored if [animatedIcon] is non [null].
  final IconData activeIcon;

  /// The label of the main button.
  final Widget label;

  /// The active label of the main button, Defaults to label if not specified.
  final Widget activeLabel;

  /// Transition Builder between icon and activeIcon, defaults to RotationTransition.
  final Widget Function(Widget, Animation<double>) iconTransitionBuilder;

  /// Transition Builder between label and activeLabel, defaults to FadeTransition.
  final Widget Function(Widget, Animation<double>) labelTransitionBuilder;

  /// Executed when the dial is opened.
  final VoidCallback onOpen;

  /// Executed when the dial is closed.
  final VoidCallback onClose;

  /// Executed when the dial is pressed. If given, the dial only opens on long press!
  final VoidCallback onPress;

  /// If true user is forced to close dial manually by tapping main button. WARNING: If true, overlay is not rendered.
  final bool closeManually;

  /// Open or close the dial via a notification
  final ValueNotifier<bool> openCloseDial;

  /// The speed of the animation in milliseconds
  final int animationSpeed;

  /// The orientation of the children. Default is [SpeedDialOrientation.Up]
  final SpeedDialOrientation orientation;

  SpeedDial({
    this.children = const [],
    this.visible = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 6.0,
    this.buttonSize = 56.0,
    this.overlayOpacity = 0.8,
    this.overlayColor,
    this.tooltip,
    this.heroTag,
    this.animatedIcon,
    this.animatedIconTheme,
    this.icon,
    this.activeIcon,
    this.label,
    this.activeLabel,
    this.iconTransitionBuilder,
    this.labelTransitionBuilder,
    this.marginBottom = 16,
    this.marginEnd = 16,
    this.onOpen,
    this.onClose,
    this.orientation = SpeedDialOrientation.Up,
    this.closeManually = false,
    this.shape = const CircleBorder(),
    this.curve = Curves.linear,
    this.onPress,
    this.animationSpeed = 150,
    this.openCloseDial,
  });

  @override
  _SpeedDialState createState() => _SpeedDialState();

  bool _dark;
}

class _SpeedDialState extends State<SpeedDial> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _calculateMainControllerDuration(),
      vsync: this,
    );
    widget.openCloseDial?.addListener(() {
      final show = widget.openCloseDial?.value;
      if (_open != show) {
        _toggleChildren();
      }
    });
  }

  Duration _calculateMainControllerDuration() => Duration(
      milliseconds:
          widget.animationSpeed + widget.children.length * (widget.animationSpeed / 5).round());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performAnimation() {
    if (!mounted) return;
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(SpeedDial oldWidget) {
    if (oldWidget.children.length != widget.children.length) {
      _controller.duration = _calculateMainControllerDuration();
    }

    super.didUpdateWidget(oldWidget);
  }

  void _toggleChildren() {
    if (widget.children.length > 0) {
      var newValue = !_open;
      setState(() {
        _open = newValue;
      });
      if (newValue && widget.onOpen != null) widget.onOpen();
      _performAnimation();
      if (!newValue && widget.onClose != null) widget.onClose();
    } else if (widget.onOpen != null) widget.onOpen();
  }

  List<Widget> _getChildrenList() {
    final singleChildrenTween = 1.0 / widget.children.length;

    return widget.children
        .map((SpeedDialChild child) {
          int index = widget.children.indexOf(child);

          var childAnimation = Tween(begin: 0.0, end: widget.buttonSize).animate(
            CurvedAnimation(
              parent: this._controller,
              curve: Interval(0, singleChildrenTween * (index + 1)),
            ),
          );

          return AnimatedChild(
            animation: childAnimation,
            index: index,
            visible: _open,
            dark: widget._dark,
            backgroundColor: child.backgroundColor,
            foregroundColor: child.foregroundColor,
            elevation: child.elevation,
            buttonSize: widget.buttonSize,
            child: child.child,
            label: child.label,
            labelStyle: child.labelStyle,
            labelBackgroundColor: child.labelBackgroundColor,
            labelWidget: child.labelWidget,
            onTap: child.onTap,
            toggleChildren: () {
              if (!widget.closeManually) _toggleChildren();
            },
            shape: child.shape,
            heroTag: widget.heroTag != null ? '${widget.heroTag}-child-$index' : null,
          );
        })
        .toList()
        .reversed
        .toList();
  }

  Widget _renderOverlay() {
    return PositionedDirectional(
      end: -16.0,
      bottom: -16.0,
      top: _open ? 0.0 : null,
      start: _open ? 0.0 : null,
      child: GestureDetector(
        onTap: _toggleChildren,
        child: BackgroundOverlay(
          animation: _controller,
          color: widget.overlayColor ?? (widget._dark ? Colors.grey[900] : Colors.white),
          opacity: widget.overlayOpacity,
        ),
      ),
    );
  }

  Widget _renderButton() {
    var child = widget.animatedIcon != null
        ? AnimatedIcon(
            icon: widget.animatedIcon,
            progress: _controller,
            color: widget.animatedIconTheme?.color,
            size: widget.animatedIconTheme?.size,
          )
        : AnimatedSwitcher(
            duration: Duration(milliseconds: widget.animationSpeed),
            transitionBuilder: widget.iconTransitionBuilder == null
                ? (widget, animation) => RotationTransition(
                      turns: animation,
                      child: widget,
                    )
                : widget.iconTransitionBuilder,
            child: Icon(
              (!_open || widget.activeIcon == null) ? widget.icon : widget.activeIcon,
              key: (!_open || widget.activeIcon == null) ? ValueKey<int>(0) : ValueKey<int>(1),
            ),
          );

    var label = AnimatedSwitcher(
      duration: Duration(milliseconds: widget.animationSpeed),
      transitionBuilder: widget.labelTransitionBuilder != null
          ? widget.labelTransitionBuilder
          : (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
      child: (!_open || widget.activeLabel == null) ? widget.label : widget.activeLabel,
    );

    var fabChildren = _open ? _getChildrenList() : [];

    var animatedFloatingButton = AnimatedFloatingButton(
      visible: widget.visible,
      tooltip: widget.tooltip,
      backgroundColor:
          widget.backgroundColor ?? (widget._dark ? Colors.grey[800] : Colors.grey[50]),
      foregroundColor: widget.foregroundColor ?? (widget._dark ? Colors.white : Colors.black),
      elevation: widget.elevation,
      onLongPress: _toggleChildren,
      callback: (_open || widget.onPress == null) ? _toggleChildren : widget.onPress,
      size: widget.buttonSize,
      label: widget.label != null ? label : null,
      child: child,
      heroTag: widget.heroTag,
      shape: widget.shape,
      curve: widget.curve,
    );

    switch (widget.orientation) {
      case SpeedDialOrientation.Down:
        return PositionedDirectional(
          top: MediaQuery.of(context).size.height - 56 - (widget.marginBottom - 16),
          end: widget.marginEnd - 16,
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.from(fabChildren.reversed)
                ..insert(
                    0,
                    Container(
                      margin: EdgeInsetsDirectional.only(bottom: 8.0, end: 2.0),
                      child: animatedFloatingButton,
                    )),
            ),
          ),
        );
        break;
      case SpeedDialOrientation.Up:
      default:
        return PositionedDirectional(
          bottom: widget.marginBottom - 16,
          end: widget.marginEnd - 16,
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.from(fabChildren)
                ..add(Container(
                  margin: EdgeInsetsDirectional.only(top: 8.0, end: 2.0),
                  child: animatedFloatingButton,
                )),
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    widget._dark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final children = [
      if (!widget.closeManually && widget.children.length > 0) _renderOverlay(),
      _renderButton(),
    ];

    var stack = Stack(
      alignment: Alignment.bottomRight,
      fit: StackFit.expand,
      overflow: Overflow.visible,
      children: children,
    );

    return stack;
  }
}
