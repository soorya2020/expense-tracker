import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/categories.dart';
import '../data/settings.dart';
import 'widgets.dart';

const _icons = {
  'food': Icons.restaurant_rounded,
  'groceries': Icons.shopping_basket_rounded,
  'travel': Icons.directions_car_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'fuel': Icons.local_gas_station_rounded,
  'bills': Icons.receipt_long_rounded,
  'health': Icons.medical_services_rounded,
  'other': Icons.more_horiz_rounded,
};

/// Rounded square with the category's icon (or first letter for your own), "?" when there is none.
class CatTile extends StatelessWidget {
  const CatTile(this.cat, {super.key, this.size = 36, this.faded = false});
  final Cat? cat;
  final double size;
  final bool faded;
  @override
  Widget build(BuildContext context) {
    final c = cat?.color ?? untaggedColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: faded ? c.withValues(alpha: .35) : c, borderRadius: BorderRadius.circular(size * .32)),
      child: _icons[cat?.id] != null
          ? Icon(_icons[cat!.id], color: Colors.white, size: size * .5)
          : Text(
              cat == null ? '?' : cat!.label.characters.first.toUpperCase(),
              style: T.bodyBold.copyWith(color: Colors.white, fontSize: size * .4, fontWeight: FontWeight.w900),
            ),
    );
  }
}

/// Small chip with the category name. "auto" marks a guess; no category asks you to pick.
class CatTag extends StatelessWidget {
  const CatTag(this.cat, {super.key, this.auto = false, this.onTap});
  final Cat? cat;
  final bool auto;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final none = cat == null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: none ? p.extraSoft : p.surface, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (!none) ...[
            Container(width: 7, height: 7, decoration: BoxDecoration(color: cat!.color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          Text(
            none ? 'Pick a category' : cat!.label,
            style: T.label.copyWith(color: none ? const Color(0xFF9A6200) : p.ink, fontSize: 11, fontWeight: FontWeight.w800),
          ),
          if (auto) Text('  auto', style: T.label.copyWith(color: p.muted, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

/// A row of category pills. Tapping the selected one clears it.
class CatPills extends StatelessWidget {
  const CatPills({super.key, required this.settings, required this.selected, required this.onPick, this.onNew});
  final Settings settings;
  final String? selected;
  final ValueChanged<String?> onPick;
  final VoidCallback? onNew;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final c in allCats(settings))
          Pill(c.label, dot: c.color, color: c.color, selected: c.id == selected, onTap: () => onPick(c.id == selected ? null : c.id)),
        if (onNew != null) Pill('+ New', outlined: true, onTap: onNew),
      ]);
}

/// Asks for a name and makes a new category. Returns its id.
Future<String?> newCatDialog(BuildContext context, Settings s) async {
  final p = context.p;
  final c = TextEditingController();
  final name = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('New category', style: T.title.copyWith(color: p.ink, fontSize: 22)),
        const SizedBox(height: 14),
        TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Pets, Kids, Gifts'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        const SizedBox(height: 14),
        BigButton('Add', onTap: () => Navigator.pop(ctx, c.text)),
      ]),
    ),
  );
  if (name == null || name.trim().isEmpty) return null;
  return (await addCustomCat(s, name)).id;
}

/// Bottom sheet to pick a category, with "Always tag [merchant] as …".
Future<({String? id, bool always})?> pickCat(
  BuildContext context,
  Settings s, {
  required String title,
  String? subtitle,
  String? selected,
  String? merchant,
  String? button,
}) {
  final p = context.p;
  return showModalBottomSheet<({String? id, bool always})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _CatSheet(s: s, title: title, subtitle: subtitle, selected: selected, merchant: merchant, button: button),
  );
}

class _CatSheet extends StatefulWidget {
  const _CatSheet({required this.s, required this.title, this.subtitle, this.selected, this.merchant, this.button});
  final Settings s;
  final String title;
  final String? subtitle, selected, merchant, button;
  @override
  State<_CatSheet> createState() => _CatSheetState();
}

class _CatSheetState extends State<_CatSheet> {
  late String? id = widget.selected;
  bool always = true;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final cat = catById(widget.s, id);
    final m = widget.merchant?.trim();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title, style: T.title.copyWith(color: p.ink, fontSize: 22)),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(widget.subtitle!, style: T.label.copyWith(color: p.muted)),
          ],
          const SizedBox(height: 16),
          CatPills(
            settings: widget.s,
            selected: id,
            onPick: (v) => setState(() => id = v),
            onNew: () async {
              final n = await newCatDialog(context, widget.s);
              if (n != null) setState(() => id = n);
            },
          ),
          if (m != null && m.isNotEmpty && cat != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Text('Always tag $m as ${cat.label}', style: T.body.copyWith(color: p.ink, fontSize: 14))),
              Switch(value: always, onChanged: (v) => setState(() => always = v)),
            ]),
          ],
          const SizedBox(height: 12),
          BigButton(
            widget.button ?? (cat == null ? 'Leave untagged' : 'Use ${cat.label}'),
            onTap: () => Navigator.pop(context, (id: id, always: always && m != null && m.isNotEmpty && id != null)),
          ),
        ]),
      ),
    );
  }
}
