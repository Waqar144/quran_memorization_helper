import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/utils/colors.dart';

class AyatListItem extends StatefulWidget {
  const AyatListItem({
    super.key,
    required this.ayah,
    this.onLongPress,
    this.onTap,
    this.isSelected = false,
    this.selectionMode = false,
    this.showSurahAyahIndex = true,
  });

  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final bool selectionMode;
  final bool showSurahAyahIndex;
  final bool isSelected;
  final Ayat ayah;

  @override
  State<AyatListItem> createState() => _AyatListItemState();
}

class _AyatListItemState extends State<AyatListItem> {
  void _longPress() {
    assert(widget.onLongPress != null);
    widget.onLongPress!();
  }

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
          ? Icon(widget.isSelected
              ? Icons.check_box
              : Icons.check_box_outline_blank)
          : null,
      title: RichText(
        text: TextSpan(children: textSpansForAyah(widget.ayah)),
        softWrap: true,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
      subtitle: widget.showSurahAyahIndex
          ? Text(widget.ayah.surahAyahText())
          : const SizedBox.shrink(),
      onLongPress: _getLongPressCallback(),
      onTap: widget.selectionMode ? widget.onTap : null,
    );
  }
}
