import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';

class AyatListItem extends StatefulWidget {
  const AyatListItem({
    super.key,
    required this.ayah,
    this.onLongPress,
    this.selectionMode = false,
    this.showSurahAyahIndex = true,
  });

  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool showSurahAyahIndex;
  final Ayat ayah;

  bool _isSelected() => ayah.selected ?? false;
  void toggleSelected() => ayah.selected = !_isSelected();

  @override
  State<AyatListItem> createState() => _AyatListItemState();
}

class _AyatListItemState extends State<AyatListItem> {
  void _longPress() {
    assert(widget.onLongPress != null);
    widget.onLongPress!();
    widget.toggleSelected();
  }

  void _onTap() => setState(() {
        widget.toggleSelected();
      });

  VoidCallback? _getLongPressCallback() {
    if (widget.onLongPress != null && !widget.selectionMode) {
      return _longPress;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: widget.selectionMode
          ? Icon(widget._isSelected()
              ? Icons.check_box
              : Icons.check_box_outline_blank)
          : null,
      title: Text(
        widget.ayah.text,
        softWrap: true,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: TextStyle(
            fontFamily: "Al Mushaf",
            fontSize: Settings.instance.fontSize.toDouble(),
            letterSpacing: 0.0,
            wordSpacing: Settings.instance.wordSpacing.toDouble()),
      ),
      subtitle: widget.showSurahAyahIndex
          ? Text(widget.ayah.surahAyahText())
          : const SizedBox.shrink(),
      onLongPress: _getLongPressCallback(),
      onTap: widget.selectionMode ? _onTap : null,
    );
  }
}
