import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/models/settings.dart';

class _AyatListItemWithMetadata extends StatelessWidget {
  final MutashabihaAyat ayah;
  final VoidCallback? onTap;
  final Widget? leading;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool isSelected;

  const _AyatListItemWithMetadata(
    this.ayah, {
    this.onTap,
    this.leading,
    this.onLongPress,
    this.isSelected = false,
    this.selectionMode = false,
  });

  Widget? _getLeadingWidget() {
    if (selectionMode && leading != null) {
      return Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank);
    } else {
      return leading;
    }
  }

  void _longPress() {
    if (onLongPress != null) {
      onLongPress!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _getLeadingWidget(),
      title: Text(
        ayah.text,
        softWrap: true,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
            fontFamily: "Al Mushaf",
            fontSize: Settings.fontSize,
            letterSpacing: 0.0,
            wordSpacing: Settings.wordSpacing),
      ),
      subtitle: Text(
          "${surahNameForIdx(ayah.surahIdx)}:${ayah.surahAyahIndexesString()} - Para: ${ayah.paraIdx + 1}"),
      onTap: onTap,
      onLongPress: _longPress,
    );
  }
}

class MutashabihaAyatListItem extends StatelessWidget {
  final Mutashabiha mutashabiha;
  final ValueNotifier<bool> _showMatches = ValueNotifier(false);
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final bool selectionMode;
  final bool isSelected;

  MutashabihaAyatListItem(
      {super.key,
      required this.mutashabiha,
      this.onLongPress,
      this.onTap,
      this.isSelected = false,
      this.selectionMode = false});

  void _onTap() {
    if (selectionMode) {
      assert(onTap != null);
      onTap!();
    } else {
      _showMatches.value = !_showMatches.value;
    }
  }

  Widget _buildMatches(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
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
          isSelected: isSelected,
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
