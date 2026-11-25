import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';

import '../theme/pos_motion.dart';

abstract final class AppMotionTokens {
  static const spring = SpringDescription(
    mass: .5,
    stiffness: 280,
    damping: 26,
  );
  static Duration time(BuildContext context, Duration value) =>
      PosMotion.isReducedMotion(context) ? Duration.zero : value;
  static const curve = _SpringCurve();
}

class _SpringCurve extends Curve {
  const _SpringCurve();
  static final simulation = SpringSimulation(AppMotionTokens.spring, 0, 1, 0);
  @override
  double transformInternal(double t) =>
      simulation.x(t * .38) / simulation.x(.38);
}

class SpringPressEffect extends StatefulWidget {
  const SpringPressEffect({
    super.key,
    required this.child,
    this.enabled = true,
  });
  final Widget child;
  final bool enabled;
  @override
  State<SpringPressEffect> createState() => _SpringPressEffectState();
}

class _SpringPressEffectState extends State<SpringPressEffect> {
  bool down = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => down = true),
    onPointerUp: (_) => setState(() => down = false),
    onPointerCancel: (_) => setState(() => down = false),
    child: AnimatedScale(
      scale: down && widget.enabled && !PosMotion.isReducedMotion(context)
          ? .97
          : 1,
      duration: AppMotionTokens.time(
        context,
        down ? PosMotion.fast : PosMotion.normal,
      ),
      curve: AppMotionTokens.curve,
      child: widget.child,
    ),
  );
}

class AnimatedMetricValue extends StatelessWidget {
  const AnimatedMetricValue(
    this.value, {
    super.key,
    this.format,
    required this.style,
  });
  final int value;
  final String Function(int)? format;
  final TextStyle style;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: value.toDouble(), end: value.toDouble()),
    duration: AppMotionTokens.time(context, PosMotion.sheet),
    curve: Curves.easeOutCubic,
    builder: (_, n, _) => Text(
      format?.call(n.round()) ?? n.round().toString(),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

class NavigationMotion extends StatefulWidget {
  const NavigationMotion({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  State<NavigationMotion> createState() => _NavigationMotionState();
}

class _NavigationMotionState extends State<NavigationMotion> {
  double direction = 1;
  @override
  void didUpdateWidget(NavigationMotion old) {
    super.didUpdateWidget(old);
    if (widget.index != old.index) {
      direction = widget.index < old.index ? -1 : 1;
    }
  }

  @override
  Widget build(BuildContext context) =>
      _NavigationDirection(direction: direction, child: widget.child);
}

class _NavigationDirection extends InheritedWidget {
  const _NavigationDirection({required this.direction, required super.child});
  final double direction;
  @override
  bool updateShouldNotify(_NavigationDirection old) =>
      old.direction != direction;
}

class SpringTabController extends TabController {
  SpringTabController({
    required super.length,
    required super.vsync,
    required super.initialIndex,
    required super.animationDuration,
  });
  @override
  void animateTo(
    int value, {
    Duration? duration,
    Curve curve = AppMotionTokens.curve,
  }) => super.animateTo(value, duration: duration, curve: curve);
}

class DirectionalPageTransition extends StatelessWidget {
  const DirectionalPageTransition({
    super.key,
    required this.animation,
    required this.child,
  });
  final Animation<double> animation;
  final Widget child;
  @override
  Widget build(BuildContext context) => PosMotion.isReducedMotion(context)
      ? child
      : SlideTransition(
          position: animation
              .drive(CurveTween(curve: AppMotionTokens.curve))
              .drive(
                Tween(
                  begin: Offset(
                    .055 *
                        (context
                                .dependOnInheritedWidgetOfExactType<
                                  _NavigationDirection
                                >()
                                ?.direction ??
                            1),
                    0,
                  ),
                  end: Offset.zero,
                ),
              ),
          child: child,
        );
}

class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final delay = index.clamp(0, 7) * 30;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotionTokens.time(
        context,
        Duration(milliseconds: 200 + delay),
      ),
      curve: Interval(delay / (200 + delay), 1, curve: Curves.easeOutCubic),
      builder: (_, t, child) =>
          Transform.translate(offset: Offset(0, 6 * (1 - t)), child: child),
      child: child,
    );
  }
}

// Capture positions immediately before a layout change, including any unfinished
// translation. Only matched, mounted children receive a new paint transform.
class MotionLayout extends StatefulWidget {
  const MotionLayout({super.key, required this.revision, required this.child});
  final Object revision;
  final Widget child;
  @override
  State<MotionLayout> createState() => _MotionLayoutState();
}

class _MotionLayoutState extends State<MotionLayout>
    with SingleTickerProviderStateMixin {
  final markers = <Object, _MotionAnchorState>{};
  late final controller = AnimationController(
    vsync: this,
    duration: PosMotion.smooth,
    value: 1,
  );
  int generation = 0;
  Map<Object, Offset?> previous = {};
  @override
  void didUpdateWidget(MotionLayout old) {
    super.didUpdateWidget(old);
    if (old.revision == widget.revision) return;
    previous = {for (final e in markers.entries) e.key: e.value.position};
    generation++;
    if (PosMotion.isReducedMotion(context)) {
      controller.value = 1;
    } else {
      controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) =>
      _LayoutScope(owner: this, child: widget.child);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class _LayoutScope extends InheritedWidget {
  const _LayoutScope({required this.owner, required super.child});
  final _MotionLayoutState owner;
  @override
  bool updateShouldNotify(_LayoutScope old) => owner != old.owner;
}

class MotionAnchor extends StatefulWidget {
  const MotionAnchor({super.key, required this.id, required this.child});
  final Object id;
  final Widget child;
  @override
  State<MotionAnchor> createState() => _MotionAnchorState();
}

class _MotionAnchorState extends State<MotionAnchor> {
  _MotionLayoutState? owner;
  Offset? get position {
    final box = context.findRenderObject();
    if (box is! _RenderMotionOffset || !box.attached || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(box.translation);
  }

  void remove(Object id) {
    if (owner?.markers[id] == this) owner?.markers.remove(id);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    remove(widget.id);
    owner = context.dependOnInheritedWidgetOfExactType<_LayoutScope>()?.owner;
    owner?.markers[widget.id] = this;
  }

  @override
  void didUpdateWidget(MotionAnchor old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      remove(old.id);
      owner?.markers[widget.id] = this;
    }
  }

  @override
  void dispose() {
    remove(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => owner == null
      ? widget.child
      : _MotionOffset(owner: owner!, id: widget.id, child: widget.child);
}

// Resolve the new origin after layout and before painting the first frame.
// Hit testing and child coordinate conversions use that same painted position.
class _MotionOffset extends SingleChildRenderObjectWidget {
  const _MotionOffset({
    required this.owner,
    required this.id,
    required super.child,
  });
  final _MotionLayoutState owner;
  final Object id;
  @override
  _RenderMotionOffset createRenderObject(BuildContext context) =>
      _RenderMotionOffset(owner, id);
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMotionOffset renderObject,
  ) {
    renderObject.id = id;
    renderObject.setOwner(owner);
  }
}

class _RenderMotionOffset extends RenderProxyBox {
  _RenderMotionOffset(this.motionState, this.id);
  _MotionLayoutState motionState;
  Object id;
  int generation = -1;
  Offset start = Offset.zero;
  Offset get translation =>
      start *
      (1 - AppMotionTokens.curve.transform(motionState.controller.value));
  void _tick() {
    if (generation != motionState.generation || start != Offset.zero) {
      markNeedsPaint();
    }
  }

  void setOwner(_MotionLayoutState next) {
    if (next == motionState) return;
    if (attached) motionState.controller.removeListener(_tick);
    motionState = next;
    generation = -1;
    if (attached) motionState.controller.addListener(_tick);
  }

  @override
  void attach(PipelineOwner pipelineOwner) {
    super.attach(pipelineOwner);
    motionState.controller.addListener(_tick);
  }

  @override
  void detach() {
    motionState.controller.removeListener(_tick);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (generation != motionState.generation) {
      generation = motionState.generation;
      final before = motionState.previous[id];
      start = before == null
          ? Offset.zero
          : before - localToGlobal(Offset.zero);
    }
    super.paint(context, offset + translation);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintOffset(
        offset: translation,
        position: position,
        hitTest: (result, position) =>
            super.hitTestChildren(result, position: position),
      );
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.translateByDouble(translation.dx, translation.dy, 0, 1);
}

class AnimatedNavigationIndicator extends StatelessWidget {
  const AnimatedNavigationIndicator({super.key, required this.decoration});
  final Decoration decoration;
  @override
  Widget build(BuildContext context) => MotionAnchor(
    id: #indicator,
    child: DecoratedBox(decoration: decoration),
  );
}

class SharedElementTransition extends StatelessWidget {
  const SharedElementTransition({
    super.key,
    required this.tag,
    required this.child,
  });
  final Object tag;
  final Widget child;
  @override
  Widget build(BuildContext context) => HeroMode(
    enabled: !PosMotion.isReducedMotion(context),
    child: Hero(tag: tag, child: child),
  );
}

class AnimatedDetailsPanel extends StatelessWidget {
  const AnimatedDetailsPanel({
    super.key,
    required this.animation,
    required this.child,
  });
  final Animation<double> animation;
  final Widget child;
  @override
  Widget build(BuildContext context) => SlideTransition(
    position: animation
        .drive(CurveTween(curve: AppMotionTokens.curve))
        .drive(Tween(begin: const Offset(.32, 0), end: Offset.zero)),
    child: child,
  );
}

class AnimatedFilterBar extends MotionLayout {
  const AnimatedFilterBar({
    super.key,
    required super.revision,
    required super.child,
  });
}

class ResponsiveMotionSidebar extends StatelessWidget {
  const ResponsiveMotionSidebar({
    super.key,
    required this.width,
    required this.decoration,
    required this.child,
    required this.clipBehavior,
  });
  final double width;
  final Decoration decoration;
  final Widget child;
  final Clip clipBehavior;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    width: width,
    decoration: decoration,
    duration: AppMotionTokens.time(context, PosMotion.smooth),
    curve: AppMotionTokens.curve,
    clipBehavior: clipBehavior,
    child: child,
  );
}

class DetailsPageRoute extends PageRouteBuilder<void> {
  DetailsPageRoute({
    required super.pageBuilder,
    required super.barrierLabel,
    required Duration duration,
  }) : super(
         opaque: false,
         barrierDismissible: true,
         barrierColor: Colors.black38,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
       );
  AnimationController? get dragController => controller;
}

Future<T?> showMotionDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final duration = AppMotionTokens.time(context, PosMotion.normal);
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    animationStyle: AnimationStyle(
      duration: duration,
      reverseDuration: duration,
      curve: AppMotionTokens.curve,
    ),
    builder: (ctx) => ScaleTransition(
      scale: ModalRoute.of(ctx)!.animation!
          .drive(CurveTween(curve: AppMotionTokens.curve))
          .drive(Tween(begin: .97, end: 1)),
      child: Builder(builder: builder),
    ),
  );
}
