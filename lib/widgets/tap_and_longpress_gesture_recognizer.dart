import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show HapticFeedback;

/// A TapGestureRecognizer that adds [LongPressGestureRecognizer] support to it
class TapAndLongPressGestureRecognizer extends TapGestureRecognizer {
  /// Creates a gesture recognizer.
  TapAndLongPressGestureRecognizer(
      {required this.onLongPress,
      required this.onTap,
      this.enableFeedback = true});

  bool _longPressAccepted = false;
  // The buttons sent by `PointerDownEvent`. If a `PointerMoveEvent` comes with a
  // different set of buttons, the gesture is canceled.
  int? _initialButtons;

  GestureLongPressCallback onLongPress;

  @override
  GestureTapCallback? onTap;

  @override
  Duration? deadline = const Duration(milliseconds: 500);

  PointerDownEvent? _down;
  PointerUpEvent? _up;

  /// Whether to vibrate on long press
  bool enableFeedback;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    switch (event.buttons) {
      case kPrimaryButton:
        return true;
      default:
        return false;
    }
  }

  @override
  void didExceedDeadline() {
    // Exceeding the deadline puts the gesture in the accepted state.
    resolve(GestureDisposition.accepted);
    _longPressAccepted = true;
    super.acceptGesture(primaryPointer!);
    _checkLongPressStart();
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      if (!_longPressAccepted) {
        _up = event;
        _checkTapUp();
        // event is handled, tell base call to cancel it
        super.handlePrimaryPointer(const PointerCancelEvent());
      }
      _resetTap();
      _resetLongPress();
    } else if (event is PointerCancelEvent) {
      super.handlePrimaryPointer(event);
      _resetLongPress();
      _resetTap();
    } else if (event is PointerDownEvent) {
      _initialButtons = event.buttons;
      _down = event;
    } else if (event is PointerMoveEvent) {
      if (event.buttons != _initialButtons) {
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(primaryPointer!);
      }
    }
  }

  void _checkTapUp() {
    if (_up == null) {
      return;
    }
    assert(_up!.pointer == _down!.pointer);
    switch (_down!.buttons) {
      case kPrimaryButton:
        invokeCallback<void>('onTap', onTap!);
        break;
      default:
    }
  }

  void _resetTap() {
    _up = null;
    _down = null;
  }

  void _checkLongPressStart() {
    switch (_initialButtons) {
      case kPrimaryButton:
        if (enableFeedback) {
          HapticFeedback.vibrate();
        }
        invokeCallback<void>('onLongPress', onLongPress);
        break;
      default:
        assert(false, 'Unhandled button $_initialButtons');
    }
  }

  void _resetLongPress() {
    _longPressAccepted = false;
    _initialButtons = null;
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (disposition == GestureDisposition.rejected) {
      if (_longPressAccepted) {
        // This can happen if the gesture has been canceled. For example when
        // the buttons have changed.
        _resetLongPress();
      }
    }
    super.resolve(disposition);
  }

  @override
  void acceptGesture(int pointer) {
    // do nothing, if we call super.acceptGesture we will not
    // get longPress as accepting will stop the timer
  }

  @override
  String get debugDescription => 'tap or long press';
}
