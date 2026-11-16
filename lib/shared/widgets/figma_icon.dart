import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/widgets.dart';

/// Renders a locally exported Figma SVG at its source dimensions.
class FigmaIcon extends StatelessWidget {
  const FigmaIcon(this.asset, {this.semanticsLabel, super.key});

  final String asset;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(asset, semanticsLabel: semanticsLabel);
}
