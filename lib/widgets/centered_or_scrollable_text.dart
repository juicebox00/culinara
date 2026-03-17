import 'package:flutter/material.dart';

class CenteredOrScrollableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double height;
  final EdgeInsetsGeometry? padding;

  const CenteredOrScrollableText({
    super.key,
    required this.text,
    this.style,
    this.height = 180, // Set to your box height
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: text, style: style ?? DefaultTextStyle.of(context).style);
        final tp = TextPainter(
          text: textSpan,
          maxLines: null,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth - (padding?.horizontal ?? 0));
        final fits = tp.height <= height;

        if (fits) {
          return Container(
            height: height,
            alignment: Alignment.center,
            padding: padding,
            child: Text(text, style: style, textAlign: TextAlign.center),
          );
        } else {
          return Container(
            height: height,
            padding: padding,
            child: SingleChildScrollView(
              child: Text(text, style: style, textAlign: TextAlign.center),
            ),
          );
        }
      },
    );
  }
}
