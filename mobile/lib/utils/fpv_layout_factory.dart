import 'package:buana_vpad/models/button_layout.dart';
import 'package:buana_vpad/models/controller_layout.dart';
import 'package:buana_vpad/models/joystick_layout.dart';
import 'package:buana_vpad/enums/button_shape.dart';
import 'package:buana_vpad/utils/layout_percentage.dart';
import 'package:uuid/uuid.dart';

/// Creates a predefined FPV Drone Simulator controller layout.
///
/// Mode 2 mapping (most popular):
///   Left joystick  → Throttle (Y-axis, up = full throttle) + Yaw (X-axis)
///   Right joystick → Pitch (Y-axis, up = nose down) + Roll (X-axis)
///
/// Button mapping for simulators (Velocidrone, Liftoff, DRL):
///   ARM    → Button A  (arm/disarm motors)
///   ANGLE  → Button B  (angle/horizon mode)
///   ACRO   → Button X  (acro/rate mode)
///   BEEPER → Button Y  (beeper / lost model)
///   LB     → Left Bumper  (increase expo)
///   RB     → Right Bumper (decrease expo)
///   Start  → Start (pause / menu)
///   Select → Select (reset / back)
class FpvLayoutFactory {
  static const Uuid _uuid = Uuid();

  /// Creates an FPV layout optimized for Mode 2.
  static ControllerLayout createFpvMode2Layout({
    required double screenWidth,
    required double screenHeight,
  }) {
    final layoutId = _uuid.v4();
    final layoutPercentage = LayoutPercentage(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );

    // Zone percentages (landscape orientation)
    const leftStickCenterX = 18.0;
    const rightStickCenterX = 82.0;
    const stickCenterY = 62.0;
    const stickSize = 28.0;

    const faceBtnY = 35.0;
    const faceBtnSize = 10.0;
    const faceBtnSpacing = 12.0;

    const triggerY = 8.0;
    const triggerWidth = 14.0;
    const triggerHeight = 7.0;
    const lTriggerX = 5.0;
    const rTriggerX = 81.0;
    const lbY = 18.0;

    const menuBtnY = 22.0;
    const menuBtnSize = 8.0;

    double absX(double pct) => layoutPercentage.getAbsoluteX(pct);
    double absY(double pct) => layoutPercentage.getAbsoluteY(pct);
    double absSize(double pct) => layoutPercentage.getAbsoluteSize(pct);
    double absW(double pct) => layoutPercentage.getAbsoluteWidth(pct);
    double absH(double pct) => layoutPercentage.getAbsoluteHeight(pct);

    final stickPx = absSize(stickSize);

    return ControllerLayout(
      id: layoutId,
      name: 'FPV Mode 2 🚁',
      width: screenWidth,
      height: screenHeight,
      isEditable: false,
      buttons: {
        // A = ARM
        'A': ButtonLayout(
          id: 'A',
          x: absX(rightStickCenterX),
          y: absY(faceBtnY + faceBtnSpacing),
          width: absSize(faceBtnSize),
          label: 'ARM',
          shape: ButtonShape.circle,
        ),
        // B = Angle mode
        'B': ButtonLayout(
          id: 'B',
          x: absX(rightStickCenterX + faceBtnSpacing),
          y: absY(faceBtnY),
          width: absSize(faceBtnSize),
          label: 'ANG',
          shape: ButtonShape.circle,
        ),
        // X = Acro mode
        'X': ButtonLayout(
          id: 'X',
          x: absX(rightStickCenterX - faceBtnSpacing),
          y: absY(faceBtnY),
          width: absSize(faceBtnSize),
          label: 'ACRO',
          shape: ButtonShape.circle,
        ),
        // Y = Beeper
        'Y': ButtonLayout(
          id: 'Y',
          x: absX(rightStickCenterX),
          y: absY(faceBtnY - faceBtnSpacing),
          width: absSize(faceBtnSize),
          label: 'BEEP',
          shape: ButtonShape.circle,
        ),
        // Shoulder buttons
        'LB': ButtonLayout(
          id: 'LB',
          x: absX(lTriggerX),
          y: absY(lbY),
          width: absW(triggerWidth),
          height: absH(triggerHeight),
          label: 'LB',
          shape: ButtonShape.rectangle,
          cornerRadius: 16,
        ),
        'RB': ButtonLayout(
          id: 'RB',
          x: absX(rTriggerX),
          y: absY(lbY),
          width: absW(triggerWidth),
          height: absH(triggerHeight),
          label: 'RB',
          shape: ButtonShape.rectangle,
          cornerRadius: 16,
        ),
        // Triggers
        'LT': ButtonLayout(
          id: 'LT',
          x: absX(lTriggerX),
          y: absY(triggerY),
          width: absW(triggerWidth),
          height: absH(triggerHeight),
          label: 'LT',
          shape: ButtonShape.rectangle,
          cornerRadius: 16,
        ),
        'RT': ButtonLayout(
          id: 'RT',
          x: absX(rTriggerX),
          y: absY(triggerY),
          width: absW(triggerWidth),
          height: absH(triggerHeight),
          label: 'RT',
          shape: ButtonShape.rectangle,
          cornerRadius: 16,
        ),
        // Menu buttons
        'Start': ButtonLayout(
          id: 'Start',
          x: absX(52.0),
          y: absY(menuBtnY),
          width: absSize(menuBtnSize),
          label: '≡',
          shape: ButtonShape.circle,
        ),
        'Select': ButtonLayout(
          id: 'Select',
          x: absX(40.0),
          y: absY(menuBtnY),
          width: absSize(menuBtnSize),
          label: '⋮',
          shape: ButtonShape.circle,
        ),
      },
      // Left stick: Throttle (Y) + Yaw (X) — Mode 2
      leftJoystick: JoystickLayout(
        x: absX(leftStickCenterX) - stickPx / 2,
        y: absY(stickCenterY) - stickPx / 2,
        outerSize: stickPx,
        innerSize: stickPx * 0.38,
        isDraggable: false,
        isFixed: false,
        deadzone: 0.05,
        hapticEnabled: true,
      ),
      // Right stick: Pitch (Y) + Roll (X) — Mode 2
      rightJoystick: JoystickLayout(
        x: absX(rightStickCenterX) - stickPx / 2,
        y: absY(stickCenterY) - stickPx / 2,
        outerSize: stickPx,
        innerSize: stickPx * 0.38,
        isDraggable: false,
        isFixed: false,
        deadzone: 0.05,
        hapticEnabled: true,
      ),
      dpadLayout: null,
    );
  }
}
