import 'package:flutter/material.dart';
import 'ayat.dart';

class AyatListItem extends StatefulWidget {
  const AyatListItem({
    super.key,
    required this.model,
    required this.idx,
    required this.text,
    required this.onTap,
    required this.onLongPress,
    required this.selectionMode,
  });

  bool isSelected() => model.isIndexSelected(idx);
  void setSelected(bool selected) => model.setIndexSelected(idx, selected);

  final int idx;
  final String text;
  final void Function(int index, bool isSelected) onTap;
  final VoidCallback onLongPress;
  final bool selectionMode;
  final ParaAyatModel model;

  @override
  State<AyatListItem> createState() => _AyatListItemState();
}

class _AyatListItemState extends State<AyatListItem> {
  late bool _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.isSelected();
  }

  void _longPress() {
    widget.onLongPress();
  }

  void _onTap() {
    widget.setSelected(!_selected);
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
          : const SizedBox.shrink(),
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
  const AyatListView(this._paraAyatModel,
      {super.key, required this.onTap, required this.selectionMode});

  final ParaAyatModel _paraAyatModel;
  final void Function(int index, bool isSelected) onTap;
  final ValueNotifier<bool> selectionMode;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(indent: 8, endIndent: 8, color: Colors.grey, height: 2),
      itemCount: _paraAyatModel.ayahs.length,
      itemBuilder: (context, index) {
        final ayat = _paraAyatModel.ayahs.elementAt(index);
        final text = ayat.text;
        return AyatListItem(
            key: ObjectKey(ayat),
            model: _paraAyatModel,
            text: text,
            idx: index,
            onTap: onTap,
            onLongPress: selectionMode.toggle,
            selectionMode: selectionMode.value);
      },
    );
  }
}
