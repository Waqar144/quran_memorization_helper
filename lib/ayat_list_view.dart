import 'package:flutter/material.dart';
import 'ayat.dart';

class AyatListItem extends StatefulWidget {
  const AyatListItem({
    super.key,
    required this.idx,
    required this.text,
    required this.onTap,
    required this.onLongPress,
    required this.selectionMode,
  });

  final int idx;
  final String text;
  final void Function(int index, bool isSelected) onTap;
  final VoidCallback onLongPress;
  final bool selectionMode;

  @override
  State<AyatListItem> createState() => _AyatListItemState();
}

class _AyatListItemState extends State<AyatListItem> {
  bool _selected = false;

  void _longPress() {
    widget.onLongPress();
  }

  @override
  void didUpdateWidget(covariant AyatListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // entering selection mode
    if (oldWidget.selectionMode == false) {
      _selected = false;
    }
  }

  void _onTap() {
    setState(() {
      _selected = !_selected;
    });
    widget.onTap(widget.idx, _selected);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: widget.selectionMode
          ? Icon(_selected ? Icons.check_box : Icons.check_box_outline_blank)
          : const Padding(padding: EdgeInsets.zero),
      title: Text(
        widget.text,
        softWrap: true,
        textAlign: TextAlign.right,
        style: const TextStyle(
            fontFamily: "Al Mushaf", fontSize: 24, letterSpacing: 0.0),
      ),
      onLongPress: widget.selectionMode ? null : _longPress,
      onTap: widget.selectionMode ? _onTap : null,
    );
  }
}

class AyatListView extends StatelessWidget {
  const AyatListView(
      {super.key,
      required this.paraAyats,
      required this.onTap,
      required this.selectionMode});

  final List<Ayat> paraAyats;
  final void Function(int index, bool isSelected) onTap;
  final ValueNotifier<bool> selectionMode;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(indent: 8, endIndent: 8, color: Colors.grey),
      itemCount: paraAyats.length,
      itemBuilder: (context, index) {
        final ayat = paraAyats.elementAt(index);
        final text = ayat.text;
        return AyatListItem(
            key: ObjectKey(ayat),
            text: text,
            idx: index,
            onTap: onTap,
            onLongPress: selectionMode.toggle,
            selectionMode: selectionMode.value);
      },
    );
  }
}
