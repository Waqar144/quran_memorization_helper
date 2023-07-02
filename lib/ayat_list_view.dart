import 'package:flutter/material.dart';
import 'ayat.dart';
import 'settings.dart';

class AyatListItem extends StatefulWidget {
  const AyatListItem({
    super.key,
    required this.ayah,
    required this.onLongPress,
    required this.selectionMode,
  });

  final VoidCallback onLongPress;
  final bool selectionMode;
  final Ayat ayah;

  bool _isSelected() => ayah.selected ?? false;
  void toggleSelected() => ayah.selected = !_isSelected();

  @override
  State<AyatListItem> createState() => _AyatListItemState();
}

class _AyatListItemState extends State<AyatListItem> {
  void _longPress() => widget.onLongPress();
  void _onTap() => setState(() {
        widget.toggleSelected();
      });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: widget.selectionMode
          ? Icon(widget._isSelected()
              ? Icons.check_box
              : Icons.check_box_outline_blank)
          : const SizedBox.shrink(),
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
        final ayat = _paraAyatModel.ayahs[index];
        return AyatListItem(
            key: ObjectKey(ayat),
            ayah: ayat,
            onLongPress: selectionMode.toggle,
            selectionMode: selectionMode.value);
      },
    );
  }
}
