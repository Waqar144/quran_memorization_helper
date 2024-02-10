import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/models/settings.dart';

class _AyatListItemWithMetadata extends StatelessWidget {
  final MutashabihaAyat _ayah;
  final VoidCallback? onTap;
  final Widget? leading;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final ValueNotifier<bool> _leadingNotifier = ValueNotifier(false);

  _AyatListItemWithMetadata(this._ayah,
      {this.onTap,
      this.leading,
      this.onLongPress,
      this.selectionMode = false}) {
    _leadingNotifier.value = _ayah.selected ?? false;
  }

  Widget? _getLeadingWidget() {
    if (selectionMode && leading != null) {
      return ValueListenableBuilder(
        valueListenable: _leadingNotifier,
        builder: (ctx, value, _) {
          return Icon(value ? Icons.check_box : Icons.check_box_outline_blank);
        },
      );
    } else {
      return leading;
    }
  }

  void _toggleSelected() {
    _ayah.selected = !(_ayah.selected ?? false);
    _leadingNotifier.value = _ayah.selected!;
  }

  void _longPress() {
    if (onLongPress != null) {
      onLongPress!();
      _toggleSelected();
    }
  }

  VoidCallback? _getOnTapHandler() {
    if (selectionMode) {
      return _toggleSelected;
    }
    return onTap;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _getLeadingWidget(),
      title: Text(
        _ayah.text,
        softWrap: true,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: TextStyle(
            fontFamily: "Al Mushaf",
            fontSize: Settings.instance.fontSize.toDouble(),
            letterSpacing: 0.0,
            wordSpacing: Settings.instance.wordSpacing.toDouble()),
      ),
      subtitle: Text(
          "${surahNameForIdx(_ayah.surahIdx)}:${_ayah.surahAyahIndexesString()} - Para: ${_ayah.paraIdx + 1}"),
      onTap: _getOnTapHandler(),
      onLongPress: _longPress,
    );
  }
}

class MutashabihaAyatListItem extends StatelessWidget {
  final Mutashabiha mutashabiha;
  final ValueNotifier<bool> _showMatches = ValueNotifier(false);
  final VoidCallback? onLongPress;
  final bool selectionMode;

  MutashabihaAyatListItem(
      {super.key,
      required this.mutashabiha,
      this.onLongPress,
      this.selectionMode = false});

  void _onTap() {
    if (selectionMode) {
    } else {
      _showMatches.value = !_showMatches.value;
    }
  }

  Widget _buildMatches(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          border: Border.all(color: theme.colorScheme.inversePrimary, width: 1),
          boxShadow: [
            BoxShadow(
                color: theme.shadowColor,
                blurRadius: 4,
                offset: const Offset(4, 2)),
          ],
        ),
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          separatorBuilder: (ctx, index) => const Divider(height: 1),
          itemCount: mutashabiha.matches.length,
          itemBuilder: (ctx, index) {
            return _AyatListItemWithMetadata(mutashabiha.matches[index]);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AyatListItemWithMetadata(
          mutashabiha.src,
          onTap: _onTap,
          onLongPress: onLongPress,
          selectionMode: selectionMode,
          leading: ValueListenableBuilder(
            valueListenable: _showMatches,
            builder: (ctx, value, _) {
              return Icon(value ? Icons.expand_more : Icons.chevron_right);
            },
          ),
        ),
        ValueListenableBuilder(
          valueListenable: _showMatches,
          builder: (ctx, value, _) {
            if (!value) {
              return const SizedBox.shrink();
            }
            return _buildMatches(Theme.of(context));
          },
        )
      ],
    );
  }
}
