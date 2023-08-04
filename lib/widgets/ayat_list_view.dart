import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';

class AyatListItem extends StatefulWidget {
  const AyatListItem({
    super.key,
    required this.ayah,
    this.onLongPress,
    this.selectionMode = false,
  });

  final VoidCallback? onLongPress;
  final bool selectionMode;
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
      onLongPress: _getLongPressCallback(),
      onTap: widget.selectionMode ? _onTap : null,
    );
  }
}

class AyatListView extends StatelessWidget {
  const AyatListView(this._ayatsList,
      {super.key, required this.onLongPress, this.selectionMode = false});

  final List<Ayat> _ayatsList;
  final VoidCallback onLongPress;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(indent: 8, endIndent: 8, color: Colors.grey, height: 2),
      itemCount: _ayatsList.length,
      itemBuilder: (context, index) {
        final ayat = _ayatsList[index];
        return AyatListItem(
            key: ObjectKey(ayat),
            ayah: _ayatsList[index],
            onLongPress: onLongPress,
            selectionMode: selectionMode);
      },
    );
  }
}