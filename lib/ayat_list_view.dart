import 'package:flutter/material.dart';
import 'ayat.dart';
import 'settings.dart';

class AyatListItem extends StatefulWidget {
  const AyatListItem({
    super.key,
    required this.model,
    required this.idx,
    required this.text,
    required this.onLongPress,
    required this.selectionMode,
  });

  final int idx;
  final String text;
  final VoidCallback onLongPress;
  final bool selectionMode;
  final ParaAyatModel model;

  @override
  State<AyatListItem> createState() => _AyatListItemState();
}

class _AyatListItemState extends State<AyatListItem> {
  void _longPress() => widget.onLongPress();
  void _onTap() => setState(() {
        setSelected(!isSelected());
      });

  bool isSelected() => widget.model.isIndexSelected(widget.idx);
  void setSelected(bool selected) =>
      widget.model.setIndexSelected(widget.idx, selected);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: widget.selectionMode
          ? Icon(isSelected() ? Icons.check_box : Icons.check_box_outline_blank)
          : const SizedBox.shrink(),
      title: Text(
        widget.text,
        softWrap: true,
        textAlign: TextAlign.right,
        style: TextStyle(
            fontFamily: "Al Mushaf",
            fontSize: Settings.instance.fontSize.toDouble(),
            letterSpacing: 0.0,
            wordSpacing: 1),
      ),
      onLongPress: widget.selectionMode ? null : _longPress,
      onTap: widget.selectionMode ? _onTap : null,
    );
  }
}

class AyatListView extends StatelessWidget {
  const AyatListView(this._paraAyatModel,
      {super.key, required this.selectionMode});

  final ParaAyatModel _paraAyatModel;
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
            onLongPress: selectionMode.toggle,
            selectionMode: selectionMode.value);
      },
    );
  }
}
