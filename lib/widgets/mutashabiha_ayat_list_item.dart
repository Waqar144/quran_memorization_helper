import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/utils/colors.dart';
import 'package:quran_memorization_helper/utils/utils.dart';

class _AyatListItemWithMetadata extends StatelessWidget {
  final MutashabihaAyat ayah;
  final VoidCallback? onLongPress;

  const _AyatListItemWithMetadata(this.ayah, {this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final widget = RichText(
      text: TextSpan(
        children: textSpansForAyah(ayah),
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontFamily: getQuranFont(),
          fontSize: Settings.instance.fontSize.toDouble(),
          letterSpacing: 0,
          wordSpacing: Settings.wordSpacing,
          height: Settings.instance.mushaf == Mushaf.Indopak16Line ? 1.7 : null,
        ),
      ),
      softWrap: true,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
    );
    if (onLongPress != null) {
      return GestureDetector(onLongPress: onLongPress, child: widget);
    }
    return widget;
  }
}

class MutashabihaAyatListItem extends StatelessWidget {
  final Mutashabiha mutashabiha;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onGoto;
  final Function(int) onGotoMutashabiha;

  const MutashabihaAyatListItem({
    super.key,
    required this.mutashabiha,
    required this.onGotoMutashabiha,
    this.onLongPress,
    this.onTap,
    this.onGoto,
  });

  List<Widget> _buildMatches(BuildContext context) {
    final theme = Theme.of(context);
    List<Widget> widgets = [];
    final isIndoPk = isIndoPak(Settings.instance.mushaf);
    widgets.add(const Divider(height: 2));
    for (final m in mutashabiha.matches) {
      widgets.add(
        ListTile(
          title: RichText(
            text: TextSpan(
              children: textSpansForAyah(m),
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontFamily: getQuranFont(),
                fontSize: Settings.instance.fontSize.toDouble(),
                letterSpacing: 0,
                wordSpacing: Settings.wordSpacing,
                height: isIndoPk ? 1.7 : null,
              ),
            ),
            softWrap: true,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          subtitle: Row(
            children: [
              Text(
                "${surahNameForIdx(m.surahIdx)}:${m.surahAyahIndexesString()} - ${paraText()}: ${m.paraNumber()}",
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () {
                  onGotoMutashabiha(m.ayahIdx);
                },
              ),
            ],
          ),
        ),
      );
      widgets.add(const Divider(height: 1));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _AyatListItemWithMetadata(
        mutashabiha.src,
        onLongPress: onLongPress,
      ),
      subtitle: Row(
        children: [
          Text(
            "${surahNameForIdx(mutashabiha.src.surahIdx)}:${mutashabiha.src.surahAyahIndexesString()} - ${paraText()}: ${mutashabiha.src.paraNumber()}",
          ),
          if (onGoto != null)
            IconButton(onPressed: onGoto, icon: const Icon(Icons.shortcut)),
        ],
      ),
      children: _buildMatches(context),
    );
  }
}
