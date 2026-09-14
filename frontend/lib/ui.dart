import 'package:flutter/material.dart';
import 'model.dart';

/// Age-specific surfaces; older children keep the detailed layouts.
class AgeStyle extends InheritedWidget {
  final bool older;
  const AgeStyle({super.key, required this.older, required super.child});
  static bool isOlder(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AgeStyle>()?.older ?? false;
  static Color surface(BuildContext context, Color color) {
    if (!isOlder(context)) return color;
    if (color == peach) return const Color(0xFFE5E1FA);
    if (color == yellow) return const Color(0xFFE5EAFE);
    if (color == mint) return const Color(0xFFDFF1F4);
    if (color == sky) return const Color(0xFFDDE9FF);
    if (color == lilac) return const Color(0xFFEAE1FC);
    return color;
  }

  @override
  bool updateShouldNotify(AgeStyle oldWidget) => older != oldWidget.older;
}

Text tx(
  String text, {
  double size = 16,
  Color color = ink,
  FontWeight weight = FontWeight.w700,
  TextAlign? align,
}) => Text(
  text,
  textAlign: align,
  style: TextStyle(
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: 1.35,
  ),
);
Widget gap([double n = 16]) => SizedBox(height: n);

class SoftCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  const SoftCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Material(
    color: AgeStyle.surface(context, color),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(26),
      side: const BorderSide(color: Colors.white, width: 3),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  const PrimaryButton(
    this.label, {
    super.key,
    this.onTap,
    this.color = coral,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AgeStyle.isOlder(context) && color == coral
            ? blue
            : color,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Text(label, textAlign: TextAlign.center)),
          if (icon != null) ...[
            const SizedBox(width: 10),
            Icon(icon, size: 20),
          ],
        ],
      ),
    ),
  );
}

class Mascot extends StatelessWidget {
  final double size;
  const Mascot({super.key, this.size = 150});
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/mascot.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, e, s) => SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text('⭐', style: TextStyle(fontSize: size * .65)),
      ),
    ),
  );
}

class Tag extends StatelessWidget {
  final String text;
  final Color color;
  const Tag(this.text, {super.key, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: tx(text, size: 11, weight: FontWeight.w800),
  );
}

class PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback back;
  final Widget? trailing;
  const PageHeader(this.title, {super.key, required this.back, this.trailing});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        onPressed: back,
        icon: const Icon(Icons.arrow_back_rounded, size: 21),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: ink,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: tx(title, size: 19, weight: FontWeight.w900)),
      ?trailing,
    ],
  );
}

class Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool secret;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  const Field(
    this.label,
    this.controller, {
    super.key,
    this.secret = false,
    this.keyboard,
    this.validator,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      obscureText: secret,
      keyboardType: keyboard,
      validator: validator,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE9E5E2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE9E5E2)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  final String title, link;
  final VoidCallback? onTap;
  const SectionHeading(this.title, {super.key, this.link = '', this.onTap});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: tx(title, size: 18, weight: FontWeight.w900)),
      if (link.isNotEmpty)
        TextButton(
          onPressed: onTap,
          child: tx(link, size: 12, color: muted),
        ),
    ],
  );
}

class ScreenBody extends StatelessWidget {
  final List<Widget> children;
  const ScreenBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
    children: children,
  );
}

void notice(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
