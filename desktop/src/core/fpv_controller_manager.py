"""
FPV Drone Simulator Controller Manager
=======================================
Maps BuanaVPad joystick data to vgamepad (Xbox 360 virtual controller)
with the correct axis mapping for FPV simulators (Velocidrone, Liftoff, DRL).

Mode 2 mapping (most popular):
  Left stick  X → Yaw   (left/right rotation)
  Left stick  Y → Throttle (up = full throttle, no auto-center)
  Right stick X → Roll  (bank left/right)
  Right stick Y → Pitch (nose up/down — inverted convention in RC)

Xbox 360 axis mapping used by simulators:
  Left  stick X  → vgamepad left_joystick_float  x_value_float  → Yaw
  Left  stick Y  → vgamepad left_joystick_float  y_value_float  → Throttle
  Right stick X  → vgamepad right_joystick_float x_value_float  → Roll
  Right stick Y  → vgamepad right_joystick_float y_value_float  → Pitch

Expo curve: softens the center of each axis for finer micro-corrections
  without limiting the full range at the edges.
"""

import math
import vgamepad as vg
from typing import Dict, Optional
from src.utils.server_events import server_events


def apply_expo(value: float, expo: float) -> float:
    """Apply an exponential curve to a joystick axis value.

    Args:
        value: Normalized axis value in [-1.0, 1.0].
        expo:  Expo factor in [0.0, 1.0].
               0.0 = linear (no expo), 1.0 = maximum curve.

    Returns:
        Curved value in [-1.0, 1.0] with the same sign as `value`.
    """
    if expo <= 0.0:
        return value
    expo = min(expo, 1.0)
    sign = 1.0 if value >= 0 else -1.0
    abs_val = abs(value)
    # Blend linear and cubic based on expo factor
    curved = (1.0 - expo) * abs_val + expo * (abs_val ** 3)
    return sign * curved


def apply_deadzone(value: float, deadzone: float) -> float:
    """Re-scales `value` so that movement below `deadzone` is ignored and the
    remainder is linearly stretched back to the full [-1, 1] range."""
    if abs(value) < deadzone:
        return 0.0
    sign = 1.0 if value > 0 else -1.0
    return sign * (abs(value) - deadzone) / (1.0 - deadzone)


class FpvControllerManager:
    """Manages virtual Xbox 360 controllers with FPV-specific axis mapping."""

    # Default FPV settings — can be changed at runtime via the GUI
    DEFAULT_EXPO = 0.30         # 30% expo on all axes
    DEFAULT_DEADZONE = 0.05    # 5% deadzone

    def __init__(self):
        self.controllers: Dict[str, dict] = {}
        self.max_clients = 4

        # Per-client settings (could be extended to per-device config later)
        self.expo = self.DEFAULT_EXPO
        self.deadzone = self.DEFAULT_DEADZONE

        # Throttle state per device: in FPV Mode 2 the throttle doesn't
        # auto-center — we remember the last sent value.
        self._throttle: Dict[str, float] = {}

    # ── Connection management ────────────────────────────────────────────────

    async def add_client(self, device_id: str, device_name: str) -> Optional[dict]:
        if len(self.controllers) >= self.max_clients:
            raise Exception("Maximum controllers reached")
        if device_id in self.controllers:
            raise Exception("Device already connected")

        gamepad = vg.VX360Gamepad()
        client = {"gamepad": gamepad, "name": device_name}
        controller_info = {
            "device_name": device_name,
            "device_id": device_id,
            "connected": True,
        }
        self.controllers[device_id] = client
        self._throttle[device_id] = -1.0   # Start at minimum throttle
        print(f"[FPV] Client connected: {device_name} ({device_id})")
        server_events.emit_client_connected(device_id, device_name)
        server_events.emit_controller_update(controller_info=controller_info)
        return client

    async def remove_client(self, device_id: str):
        if device_id in self.controllers:
            client = self.controllers[device_id]
            print(f"[FPV] Client disconnected: {client['name']} ({device_id})")
            controller_info = {
                "device_name": client["name"],
                "device_id": device_id,
                "connected": False,
            }
            server_events.emit_controller_update(controller_info=controller_info)
            server_events.emit_client_disconnected(device_id, client["name"])
            del self.controllers[device_id]
            self._throttle.pop(device_id, None)

    # ── Input processing ─────────────────────────────────────────────────────

    async def handle_input(self, device_id: str, data: dict):
        if device_id not in self.controllers:
            return

        gamepad: vg.VX360Gamepad = self.controllers[device_id]["gamepad"]

        try:
            server_events.emit_controller_input(device_id, data)

            # ── Left stick: Throttle (Y) + Yaw (X) ──────────────────────
            left_joy = data.get("leftJoystickState", {})
            raw_yaw = float(left_joy.get("dx", 0.0))
            raw_throttle = float(left_joy.get("dy", 0.0))

            # Throttle: app Y is positive downward, so -dy = up = more throttle
            # We do NOT auto-center throttle — keep last value when stick idle
            if left_joy.get("isPressed", False) or abs(raw_throttle) > self.deadzone:
                throttle = apply_deadzone(-raw_throttle, self.deadzone)
                throttle = apply_expo(throttle, self.expo)
                self._throttle[device_id] = throttle
            # else: keep the stored throttle value (sticky throttle)

            yaw = apply_deadzone(raw_yaw, self.deadzone)
            yaw = apply_expo(yaw, self.expo)

            # vgamepad Y axis: +1 = up (stick pushed forward). We map:
            #   throttle +1 = full throttle (stick up)  → y_float = +1
            gamepad.left_joystick_float(
                x_value_float=yaw,
                y_value_float=self._throttle[device_id],
            )

            # ── Right stick: Roll (X) + Pitch (Y) ───────────────────────
            right_joy = data.get("rightJoystickState", {})
            raw_roll = float(right_joy.get("dx", 0.0))
            raw_pitch = float(right_joy.get("dy", 0.0))

            roll = apply_deadzone(raw_roll, self.deadzone)
            roll = apply_expo(roll, self.expo)

            # Pitch: RC convention — stick up = nose up = negative pitch in
            # screen coords.  vgamepad up = +1, so we pass -dy.
            pitch_raw = apply_deadzone(-raw_pitch, self.deadzone)
            pitch = apply_expo(pitch_raw, self.expo)

            gamepad.right_joystick_float(
                x_value_float=roll,
                y_value_float=pitch,
            )

            # ── Buttons ──────────────────────────────────────────────────
            button_states = data.get("buttonStates", {})
            for button_id, state in button_states.items():
                self._handle_button(gamepad, button_id, state)

            # ── DPad (optional, not typically used in FPV sims) ──────────
            dpad = data.get("dpadState", {})
            if dpad:
                self._handle_dpad(gamepad, dpad)

            gamepad.update()

        except Exception as e:
            print(f"[FPV] Error processing input: {e}")
            raise

    # ── Button mapping ───────────────────────────────────────────────────────

    def _handle_button(self, gamepad: vg.VX360Gamepad, button_id: str, state: dict):
        # Strip layout prefix (e.g. "uuid_A" → "A")
        actual_id = button_id.split("_")[-1]

        button_map = {
            "A":      vg.XUSB_BUTTON.XUSB_GAMEPAD_A,
            "B":      vg.XUSB_BUTTON.XUSB_GAMEPAD_B,
            "X":      vg.XUSB_BUTTON.XUSB_GAMEPAD_X,
            "Y":      vg.XUSB_BUTTON.XUSB_GAMEPAD_Y,
            "LB":     vg.XUSB_BUTTON.XUSB_GAMEPAD_LEFT_SHOULDER,
            "RB":     vg.XUSB_BUTTON.XUSB_GAMEPAD_RIGHT_SHOULDER,
            "Start":  vg.XUSB_BUTTON.XUSB_GAMEPAD_START,
            "Select": vg.XUSB_BUTTON.XUSB_GAMEPAD_BACK,
        }

        if actual_id in button_map:
            if state.get("isPressed"):
                gamepad.press_button(button=button_map[actual_id])
            else:
                gamepad.release_button(button=button_map[actual_id])
        elif actual_id == "LT":
            gamepad.left_trigger_float(value_float=state.get("value", 0.0))
        elif actual_id == "RT":
            gamepad.right_trigger_float(value_float=state.get("value", 0.0))

    def _handle_dpad(self, gamepad: vg.VX360Gamepad, dpad_state: dict):
        directions = {
            "upPressed":    vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_UP,
            "downPressed":  vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_DOWN,
            "leftPressed":  vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_LEFT,
            "rightPressed": vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_RIGHT,
        }
        for key, btn in directions.items():
            if dpad_state.get(key):
                gamepad.press_button(button=btn)
            else:
                gamepad.release_button(button=btn)

    # ── Runtime configuration ────────────────────────────────────────────────

    def set_expo(self, expo: float):
        """Set expo curve for all axes (0.0 = linear, 1.0 = max curve)."""
        self.expo = max(0.0, min(1.0, expo))

    def set_deadzone(self, deadzone: float):
        """Set deadzone for all axes (0.0 = none, 0.3 = 30%)."""
        self.deadzone = max(0.0, min(0.5, deadzone))

    def reset_throttle(self, device_id: str):
        """Reset throttle to minimum for a device (e.g. on reconnect)."""
        if device_id in self._throttle:
            self._throttle[device_id] = -1.0
