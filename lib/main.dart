import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Multi-layer Pie Chart")),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: MultiLayerPieChart(data: demoData),
      ),
    );
  }
}

class DataModel {
  final int volume;
  final double percentageChange;
  final String title;
  final Color color;
  final Color textColor;
  final double textSize;

  DataModel({
    required this.volume,
    required this.percentageChange,
    required this.title,
    required this.color,
    this.textColor = Colors.white,
    this.textSize = 9,
  });
}

class MultiLayerPieChart extends StatelessWidget {
  final List<DataModel> data;

  const MultiLayerPieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);

        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: PieChartPainter(data)),
        );
      },
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<DataModel> data;

  PieChartPainter(this.data);

  final double sliceGap = pi / 90;
  final double ringGap = 3;

  // @override
  // void paint(Canvas canvas, Size size) {
  //   final center = Offset(size.width / 2, size.height / 2);
  //   final maxRadius = size.width / 2;

  //   final ringWidth = maxRadius / 3;

  //   final layer1 = data.sublist(0, 5);
  //   final layer2 = data.sublist(5, 10);
  //   final layer3 = data.sublist(10, 15);

  //   double firstInnerRadius = 0;

  //   drawLayer(canvas, center, firstInnerRadius, ringWidth - ringGap, layer1);

  //   drawLayer(canvas, center, ringWidth, ringWidth * 2 - ringGap, layer2);

  //   drawLayer(canvas, center, ringWidth * 2, ringWidth * 3 - ringGap, layer3);

  //   final centerPaint = Paint()..color = Colors.white;
  //   canvas.drawCircle(center, firstInnerRadius + ringWidth * 0.4, centerPaint);
  // }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final layer1 = data.sublist(0, 5);
    final layer2 = data.sublist(5, 11);
    final layer3 = data.sublist(11, 15);

    // center circle radius
    final centerRadius = maxRadius * 0.15;

    // calculate ring width
    final availableRadius = maxRadius - centerRadius - (ringGap * 4);
    final ringWidth = availableRadius / 3;

    final layer1Inner = centerRadius + ringGap;
    final layer1Outer = layer1Inner + ringWidth;

    final layer2Inner = layer1Outer + ringGap;
    final layer2Outer = layer2Inner + ringWidth;

    final layer3Inner = layer2Outer + ringGap;
    final layer3Outer = layer3Inner + ringWidth;

    drawLayer(canvas, center, layer1Inner, layer1Outer, layer1);
    drawLayer(canvas, center, layer2Inner, layer2Outer, layer2);
    drawLayer(canvas, center, layer3Inner, layer3Outer, layer3);

    // draw center circle
    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, centerRadius, centerPaint);
  }

  void drawLayer(
    Canvas canvas,
    Offset center,
    double innerRadius,
    double outerRadius,
    List<DataModel> items,
  ) {
    final total = items.fold<int>(0, (s, e) => s + e.volume);

    double startAngle = -pi / 2;

    for (final item in items) {
      final sweepAngle = (item.volume / total) * 2 * pi;
      final drawSweep = sweepAngle - sliceGap;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
      final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

      final path = Path();

      path.arcTo(outerRect, startAngle + sliceGap / 2, drawSweep, false);

      path.arcTo(
        innerRect,
        startAngle + sliceGap / 2 + drawSweep,
        -drawSweep,
        false,
      );

      path.close();

      canvas.drawPath(path, paint);

      final midAngle = startAngle + sweepAngle / 2;

      drawArcText(
        canvas,
        center,
        (innerRadius + outerRadius) / 2,
        midAngle,
        sweepAngle,
        item.title,
        item.textColor,
        item.textSize,
      );

      startAngle += sweepAngle;
    }
  }

  void drawArcText(
    Canvas canvas,
    Offset center,
    double radius,
    double midAngle,
    double sweepAngle,
    String text,
    Color textColor,
    double fontSize,
  ) {
    TextStyle style = TextStyle(
      color: textColor,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
    );

    final arcLength = radius * sweepAngle;

    TextPainter measure = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    // shrink font if text does not fit
    if (measure.width > arcLength) {
      fontSize = fontSize * (arcLength / measure.width);
      style = style.copyWith(fontSize: fontSize);
    }

    final chars = text.split("");

    final painters = chars
        .map(
          (c) => TextPainter(
            text: TextSpan(text: c, style: style),
            textDirection: TextDirection.ltr,
          )..layout(),
        )
        .toList();

    final textWidth = painters.fold(0.0, (p, e) => p + e.width);

    final anglePerPixel = sweepAngle / arcLength;

    double startAngle = midAngle - (textWidth * anglePerPixel) / 2;

    for (final tp in painters) {
      final angle = startAngle + (tp.width * anglePerPixel) / 2;

      final offset = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      canvas.save();

      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(angle + pi / 2);

      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

      canvas.restore();

      startAngle += tp.width * anglePerPixel;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

List<DataModel> demoData = [
  DataModel(
    volume: 10,
    percentageChange: 1,
    title: "Bank",
    color: Color(0XFFA7F6C4),
    textColor: Colors.black,
    textSize: 7,
  ),
  DataModel(
    volume: 10,
    percentageChange: 2,
    title: "IT",
    color: Color(0XFFA7F6C4),
    textColor: Colors.black,
    textSize: 7,
  ),
  DataModel(
    volume: 10,
    percentageChange: 3,
    title: "Healthcare",
    color: Color(0XFFFFA3A3),
    textColor: Colors.black,
    textSize: 7,
  ),

  DataModel(
    volume: 10,
    percentageChange: 1,
    title: "FMCG",
    color: Color(0XFFFFA3A3),
    textColor: Colors.black,
    textSize: 7,
  ),
  DataModel(
    volume: 10,
    percentageChange: 2,
    title: "Metal",
    color: Color(0XFFDF4141),
    textSize: 7,
  ),

  DataModel(volume: 13, percentageChange: 2, title: "Metal", color: Colors.red),
  DataModel(
    volume: 12,
    percentageChange: 2,
    title: "Chemicals",
    color: Color(0XFFDF4141),
  ),
  DataModel(volume: 11, percentageChange: 1, title: "Bank", color: Colors.red),
  DataModel(
    volume: 10,
    percentageChange: 3,
    title: "Auto",
    color: Color(0XFF32BE64),
  ),
  DataModel(
    volume: 8,
    percentageChange: 2,
    title: "Healthcare",
    color: Color(0XFF32BE64),
  ),
  DataModel(
    volume: 8,
    percentageChange: 2,
    title: "FMCG",
    color: Color(0XFF1E9646),
  ),
  DataModel(
    volume: 9,
    percentageChange: 1,
    title: "IT",
    color: Color(0XFF0B762F),
  ),
  DataModel(
    volume: 8,
    percentageChange: 2,
    title: "Power",
    color: Color(0XFF822828),
  ),
  DataModel(
    volume: 11,
    percentageChange: 1,
    title: "Oil & Gas",
    color: Color(0XFF822828),
  ),
  DataModel(
    volume: 10,
    percentageChange: 3,
    title: "PSU Bank",
    color: Color(0XFF1E9646),
  ),
  DataModel(
    volume: 12,
    percentageChange: 2,
    title: "Pharma",
    color: Color(0XFF0B762F),
  ),
];
