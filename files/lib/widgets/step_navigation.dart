import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import '../../core/constants/app_fonts.dart';

class StepNavigation extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<StepInfo> steps;
  final Function(int) onStepTap;
  final bool allowJumping;

  const StepNavigation({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.steps,
    required this.onStepTap,
    this.allowJumping = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Responsive.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;
          final isAccessible = allowJumping || index <= currentStep;

          return Expanded(
            child: GestureDetector(
              onTap: isAccessible ? () => onStepTap(index) : null,
              child: Container(
                padding: Responsive.symmetric(vertical: 8),
                child: Column(
                  children: [
                    // Step Icon
                    Container(
                      width: Responsive.w(40),
                      height: Responsive.h(40),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF3B82F6)
                            : isCompleted
                                ? const Color(0xFF10B981)
                                : isAccessible
                                    ? const Color(0xFF6B7280).withOpacity(0.2)
                                    : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(Responsive.r(20)),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF3B82F6)
                              : isCompleted
                                  ? const Color(0xFF10B981)
                                  : isAccessible
                                      ? const Color(0xFF6B7280)
                                      : const Color(0xFFE5E7EB),
                          width: 2,
                        ),
                        boxShadow: isActive || isCompleted
                            ? [
                                BoxShadow(
                                  color: (isActive
                                          ? const Color(0xFF3B82F6)
                                          : const Color(0xFF10B981))
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : step.icon,
                        color: isActive || isCompleted
                            ? Colors.white
                            : isAccessible
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF9CA3AF),
                        size: Responsive.sp(20),
                      ),
                    ),
                    SizedBox(height: Responsive.h(4)),
                    // Step Label
                    Text(
                      step.label.tr,
                      style: AppFonts.bodySmall.copyWith(
                        color: isActive
                            ? const Color(0xFF3B82F6)
                            : isCompleted
                                ? const Color(0xFF10B981)
                                : isAccessible
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF),
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Connection Line - Removed Positioned widget as it was causing errors
                    // Connection lines will be handled differently if needed
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class StepInfo {
  final IconData icon;
  final String label;

  StepInfo({
    required this.icon,
    required this.label,
  });
}

// Predefined step configurations
class StudentSteps {
  static List<StepInfo> get addSteps => [
        StepInfo(
          icon: Icons.person_rounded,
          label: 'step_identity',
        ),
        StepInfo(
          icon: Icons.cake_rounded,
          label: 'step_age_birth',
        ),
        StepInfo(
          icon: Icons.badge_rounded,
          label: 'step_name_grade',
        ),
        StepInfo(
          icon: Icons.location_on_rounded,
          label: 'step_address',
        ),
        StepInfo(
          icon: Icons.medical_services_rounded,
          label: 'step_medical',
        ),
        StepInfo(
          icon: Icons.person_add_rounded,
          label: 'step_add_student',
        ),
      ];

  static List<StepInfo> get editSteps => [
        StepInfo(
          icon: Icons.person_rounded,
          label: 'step_identity',
        ),
        StepInfo(
          icon: Icons.cake_rounded,
          label: 'step_age_birth_data',
        ),
        StepInfo(
          icon: Icons.badge_rounded,
          label: 'step_name_grade',
        ),
        StepInfo(
          icon: Icons.location_on_rounded,
          label: 'step_address',
        ),
        StepInfo(
          icon: Icons.medical_services_rounded,
          label: 'step_medical',
        ),
        StepInfo(
          icon: Icons.pregnant_woman_rounded,
          label: 'step_mother',
        ),
        StepInfo(
          icon: Icons.man_rounded,
          label: 'step_father',
        ),
      ];
}
