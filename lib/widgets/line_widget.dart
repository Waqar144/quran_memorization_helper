import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'tap_and_longpress_gesture_recognizer.dart';
import 'dart:math';

(double, List<double>) getFontSize(
    List<TextSpan> spans, double availableWidth) {
  int i = 0;
  double largest = 0.0;
  int largestIndex = 0;
  const fontStyle = TextStyle(
    // color: Theme.of(context).textTheme.bodyMedium?.color,
    fontFamily: "Al Mushaf",
    fontSize: 26,
    letterSpacing: 0,
    wordSpacing: 0,
  );
  for (final s in spans) {
    final p = TextPainter(
        text: TextSpan(children: [s], style: fontStyle),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right);
    p.layout(minWidth: 0, maxWidth: double.infinity);
    double width = p.width;
    if (width > largest) {
      largestIndex = i;
    }
    largest = max(width, largest);
    // print("$i): ${p.width}");
    i++;
  }
  print("largest::::: ($largestIndex, $largest) --- $availableWidth");

  double bestFontSize = 0;
  for (int font = 26; font > 10; --font) {
    final fontStyle = TextStyle(
      fontFamily: "Al Mushaf",
      fontSize: font.toDouble(),
      letterSpacing: 0,
      wordSpacing: 1,
    );
    final p = TextPainter(
        text: TextSpan(children: [spans[largestIndex]], style: fontStyle),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right);
    p.layout(minWidth: 0, maxWidth: double.infinity);
    if (p.width < availableWidth) {
      bestFontSize = font.toDouble();
      break;
    }
  }

  final bestFontStyle = TextStyle(
    fontFamily: "Al Mushaf",
    fontSize: bestFontSize,
    letterSpacing: 0,
    wordSpacing: 1,
  );
  List<double> lineSizes = [];
  for (final s in spans) {
    final p = TextPainter(
        text: TextSpan(children: [s], style: bestFontStyle),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right);
    p.layout(minWidth: 0, maxWidth: double.infinity);
    lineSizes.add(p.width);
  }

  print("Best: $bestFontSize");
  return (bestFontSize, lineSizes);
}

class LineWidget extends LeafRenderObjectWidget {
  final TextSpan span;

  const LineWidget({super.key, required this.span});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLineObject(span);
  }

  @override
  void updateRenderObject(BuildContext context, RenderLineObject renderObject) {
    renderObject.span = span;
  }
}

class RenderLineObject extends RenderBox {
  TextSpan _span;
  TextSpan get span => _span;
  set span(TextSpan value) {
    _span = value;
    markNeedsPaint();
  }

  final _textPainter = TextPainter();

  late TapAndLongPressGestureRecognizer _recognizer;

  void _onLongPress() {
    print("onLongPress");
  }

  void _onTouch() {
    print("onTap");
  }

  RenderLineObject(this._span) {
    _recognizer = TapAndLongPressGestureRecognizer(
        onLongPress: _onLongPress, onTap: _onTouch, enableFeedback: true);
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.smallest;
  }

  @override
  bool hitTestSelf(Offset position) {
    return true;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      final pos = _textPainter.getPositionForOffset(event.localPosition);
      final span = _textPainter.text!.getSpanForPosition(pos);
      if (span is TextSpan) {
        print("clicked : ${span.text}");
        span.recognizer?.addPointer(event);
        _recognizer.addPointer(event);
        // markNeedsPaint();
      }
    }
    super.handleEvent(event, entry);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // print("paint");
    _textPainter.text = span;
    _textPainter.textDirection = TextDirection.rtl;
    _textPainter.textAlign = TextAlign.right;
    _textPainter.layout(
      maxWidth: double.infinity,
      minWidth: constraints.minWidth,
    );
    // print("${_textPainter.width} ---- ${constraints.maxWidth}");
    _textPainter.paint(context.canvas, offset);
  }
}
