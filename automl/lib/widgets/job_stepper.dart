import 'package:flutter/material.dart';

class StepData {
  final IconData icon;
  final Color activeGradientStart;
  final Color activeGradientEnd;

  const StepData({
    required this.icon,
    required this.activeGradientStart,
    required this.activeGradientEnd,
  });
}

class JobStepper extends StatelessWidget {
  final List<StepData> steps;
  final int currentIndex;
  final Color lineColor;
  final double iconSize;
  final double circleRadius;

  const JobStepper({
    super.key,
    required this.steps,
    required this.currentIndex,
    this.lineColor = Colors.white24,
    this.iconSize = 24,
    this.circleRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _buildStepCircle(steps[i], i),
          if (i < steps.length - 1)
            Expanded(child: Container(height: 2, color: lineColor)),
        ],
      ],
    );
  }

  Widget _buildStepCircle(StepData step, int index) {
    final bool isActive = index == currentIndex;
    final bool isCompleted = index < currentIndex;

    return Container(
      width: circleRadius * 2,
      height: circleRadius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? null : Colors.white12,
        gradient: isActive
            ? LinearGradient(
          colors: [step.activeGradientStart, step.activeGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
      ),
      child: Center(
        child: Icon(
          isCompleted ? Icons.check : step.icon,
          color: isActive || isCompleted ? Colors.white : Colors.white60,
          size: iconSize,
        ),
      ),
    );
  }
}