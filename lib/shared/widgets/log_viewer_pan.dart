part of 'log_viewer.dart';

/// Lets a touch drag pan the log sideways.
///
/// [SelectionArea] claims horizontal drags. That is right for a mouse, where
/// dragging across text is how you select it — but on a touchscreen it left
/// the log with no way to scroll sideways at all, because Material's scrollbar
/// is not interactive on mobile platforms either. A line longer than the pane
/// simply could not be read to its end.
///
/// Sits below the selection region so it wins the gesture arena, and accepts
/// [PointerDeviceKind.touch] only so mouse selection keeps working exactly as
/// before. Vertical drags are never claimed and fall through to the list.
class _HorizontalTouchPan extends StatefulWidget {
  const _HorizontalTouchPan({required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  @override
  State<_HorizontalTouchPan> createState() => _HorizontalTouchPanState();
}

class _HorizontalTouchPanState extends State<_HorizontalTouchPan> {
  Drag? _drag;

  @override
  void dispose() {
    _drag?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        HorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              HorizontalDragGestureRecognizer
            >(
              () => HorizontalDragGestureRecognizer(
                debugOwner: this,
                supportedDevices: const {PointerDeviceKind.touch},
              ),
              (recognizer) => recognizer
                ..onStart = _onStart
                ..onUpdate = _onUpdate
                ..onEnd = _onEnd
                ..onCancel = _onCancel,
            ),
      },
      child: widget.child,
    );
  }

  /// Handed to [ScrollPosition.drag] rather than translated into `jumpTo` by
  /// hand, so the pan gets the platform's real scroll physics — friction, a
  /// fling that keeps going, resistance at the ends.
  void _onStart(DragStartDetails details) {
    if (!widget.controller.hasClients) return;
    _drag = widget.controller.position.drag(details, () => _drag = null);
  }

  void _onUpdate(DragUpdateDetails details) => _drag?.update(details);

  void _onEnd(DragEndDetails details) {
    _drag?.end(details);
    _drag = null;
  }

  void _onCancel() {
    _drag?.cancel();
    _drag = null;
  }
}
