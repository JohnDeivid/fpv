"""
FPV Drone Simulator Settings Tab
=================================
Provides a GUI panel for configuring the FPV controller mode.
Users can adjust expo curves, deadzone, and view connection info.
"""

from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QGroupBox, QSlider, QPushButton,
    QScrollArea, QFrame
)
from PyQt6.QtCore import Qt, pyqtSignal
from PyQt6.QtGui import QFont


class _DarkGroupBox(QGroupBox):
    def __init__(self, title="", parent=None):
        super().__init__(title, parent)
        self.setStyleSheet("""
            QGroupBox {
                background-color: #1a1a1a;
                border: 2px solid #333333;
                border-radius: 8px;
                margin-top: 12px;
                padding-top: 10px;
                font-weight: bold;
                color: #ffffff;
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                subcontrol-position: top left;
                padding: 0 5px;
                margin-left: 10px;
                background-color: #1a1a1a;
            }
        """)


class FpvSettingsTab(QWidget):
    """Tab for FPV drone simulator controller settings."""

    # Emitted when expo or deadzone changes so the server can be updated
    expo_changed = pyqtSignal(float)
    deadzone_changed = pyqtSignal(float)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._expo = 0.30
        self._deadzone = 0.05
        self._init_ui()
        self._setup_styles()

    # ── UI construction ──────────────────────────────────────────────────────

    def _init_ui(self):
        outer_layout = QVBoxLayout(self)
        outer_layout.setContentsMargins(0, 0, 0, 0)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.Shape.NoFrame)
        outer_layout.addWidget(scroll)

        container = QWidget()
        scroll.setWidget(container)
        layout = QVBoxLayout(container)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(16)

        # ── Header ───────────────────────────────────────────────────────────
        header = QLabel("🚁  FPV Drone Simulator Mode")
        header.setFont(QFont("Segoe UI", 18, QFont.Weight.Bold))
        header.setStyleSheet("color: #FF8800; padding: 8px 0;")
        layout.addWidget(header)

        # ── How to connect info box ───────────────────────────────────────────
        info_box = _DarkGroupBox("How to Connect")
        info_layout = QVBoxLayout(info_box)

        self._add_info_row(info_layout, "1.", "Start the Local Server (Server Control tab).")
        self._add_info_row(info_layout, "2.", "On your phone, open 'My Controllers' and tap ➕.")
        self._add_info_row(info_layout, "3.", "Choose  FPV Drone Simulator 🚁  as the layout type.")
        self._add_info_row(info_layout, "4.", "Tap Connect → enter the PC IP & port.")
        self._add_info_row(info_layout, "5.",
            "In the connect screen, enable FPV Mode so the app uses\n"
            "  /ws/fpv/{id}  instead of /ws/controller/{id}.")
        layout.addWidget(info_box)

        # ── Axis mapping diagram ──────────────────────────────────────────────
        mapping_box = _DarkGroupBox("Mode 2 Axis Mapping")
        mapping_layout = QVBoxLayout(mapping_box)

        self._add_mapping_row(mapping_layout, "Left  stick X", "→  Yaw   (rotate left/right)")
        self._add_mapping_row(mapping_layout, "Left  stick Y", "→  Throttle (up = full power, STICKY)")
        self._add_mapping_row(mapping_layout, "Right stick X", "→  Roll  (bank left/right)")
        self._add_mapping_row(mapping_layout, "Right stick Y", "→  Pitch (nose up/down)")
        mapping_layout.addSpacing(8)
        note = QLabel("⚠  Throttle is sticky — it holds its position when you release the stick.")
        note.setStyleSheet("color: #FFAA00; font-style: italic; font-size: 12px;")
        note.setWordWrap(True)
        mapping_layout.addWidget(note)
        layout.addWidget(mapping_box)

        # ── Expo slider ───────────────────────────────────────────────────────
        expo_box = _DarkGroupBox("Expo Curve")
        expo_layout = QVBoxLayout(expo_box)

        expo_desc = QLabel(
            "Softens stick response near center for finer control.\n"
            "0% = linear (raw), 100% = maximum curve."
        )
        expo_desc.setStyleSheet("color: #999999; font-size: 12px;")
        expo_desc.setWordWrap(True)
        expo_layout.addWidget(expo_desc)
        expo_layout.addSpacing(8)

        expo_row = QHBoxLayout()
        expo_label = QLabel("Expo:")
        expo_label.setFixedWidth(60)
        expo_row.addWidget(expo_label)

        self._expo_slider = QSlider(Qt.Orientation.Horizontal)
        self._expo_slider.setRange(0, 100)
        self._expo_slider.setValue(int(self._expo * 100))
        self._expo_slider.setTickInterval(10)
        self._expo_slider.setTickPosition(QSlider.TickPosition.TicksBelow)
        expo_row.addWidget(self._expo_slider)

        self._expo_value_label = QLabel(f"{int(self._expo * 100)}%")
        self._expo_value_label.setFixedWidth(45)
        self._expo_value_label.setAlignment(Qt.AlignmentFlag.AlignRight)
        expo_row.addWidget(self._expo_value_label)
        expo_layout.addLayout(expo_row)

        self._expo_slider.valueChanged.connect(self._on_expo_changed)
        layout.addWidget(expo_box)

        # ── Deadzone slider ───────────────────────────────────────────────────
        dz_box = _DarkGroupBox("Deadzone")
        dz_layout = QVBoxLayout(dz_box)

        dz_desc = QLabel(
            "Ignores small stick movements near center to eliminate drift.\n"
            "Recommended: 3–8% for touch screens."
        )
        dz_desc.setStyleSheet("color: #999999; font-size: 12px;")
        dz_desc.setWordWrap(True)
        dz_layout.addWidget(dz_desc)
        dz_layout.addSpacing(8)

        dz_row = QHBoxLayout()
        dz_label = QLabel("Deadzone:")
        dz_label.setFixedWidth(60)
        dz_row.addWidget(dz_label)

        self._dz_slider = QSlider(Qt.Orientation.Horizontal)
        self._dz_slider.setRange(0, 30)
        self._dz_slider.setValue(int(self._deadzone * 100))
        self._dz_slider.setTickInterval(5)
        self._dz_slider.setTickPosition(QSlider.TickPosition.TicksBelow)
        dz_row.addWidget(self._dz_slider)

        self._dz_value_label = QLabel(f"{int(self._deadzone * 100)}%")
        self._dz_value_label.setFixedWidth(45)
        self._dz_value_label.setAlignment(Qt.AlignmentFlag.AlignRight)
        dz_row.addWidget(self._dz_value_label)
        dz_layout.addLayout(dz_row)

        self._dz_slider.valueChanged.connect(self._on_deadzone_changed)
        layout.addWidget(dz_box)

        # ── Reset button ──────────────────────────────────────────────────────
        reset_btn = QPushButton("Reset to Defaults")
        reset_btn.setFixedHeight(40)
        reset_btn.clicked.connect(self._reset_defaults)
        layout.addWidget(reset_btn)

        # ── Simulator compatibility ───────────────────────────────────────────
        compat_box = _DarkGroupBox("Simulator Compatibility")
        compat_layout = QVBoxLayout(compat_box)
        sims = [
            ("Velocidrone", "✅", "Fully compatible — use Xbox controller preset"),
            ("Liftoff",     "✅", "Fully compatible — use Xbox controller preset"),
            ("DRL Simulator","✅","Fully compatible — use Xbox controller preset"),
            ("Uncrashed",   "✅", "Fully compatible — use Xbox controller preset"),
            ("Orqa FPV",    "✅", "Fully compatible"),
        ]
        for name, icon, note in sims:
            row = QHBoxLayout()
            icon_lbl = QLabel(icon)
            icon_lbl.setFixedWidth(24)
            name_lbl = QLabel(f"<b>{name}</b>")
            name_lbl.setFixedWidth(130)
            note_lbl = QLabel(note)
            note_lbl.setStyleSheet("color: #999999; font-size: 12px;")
            row.addWidget(icon_lbl)
            row.addWidget(name_lbl)
            row.addWidget(note_lbl)
            row.addStretch()
            compat_layout.addLayout(row)
        layout.addWidget(compat_box)

        layout.addStretch()

    def _add_info_row(self, layout, step: str, text: str):
        row = QHBoxLayout()
        step_lbl = QLabel(step)
        step_lbl.setFixedWidth(20)
        step_lbl.setStyleSheet("color: #FF8800; font-weight: bold;")
        text_lbl = QLabel(text)
        text_lbl.setWordWrap(True)
        text_lbl.setStyleSheet("color: #cccccc; font-size: 13px;")
        row.addWidget(step_lbl)
        row.addWidget(text_lbl)
        row.addStretch()
        layout.addLayout(row)

    def _add_mapping_row(self, layout, axis: str, mapping: str):
        row = QHBoxLayout()
        axis_lbl = QLabel(axis)
        axis_lbl.setFixedWidth(140)
        axis_lbl.setStyleSheet("color: #44AAFF; font-family: monospace; font-size: 13px;")
        map_lbl = QLabel(mapping)
        map_lbl.setStyleSheet("color: #ffffff; font-size: 13px;")
        row.addWidget(axis_lbl)
        row.addWidget(map_lbl)
        row.addStretch()
        layout.addLayout(row)

    # ── Event handlers ───────────────────────────────────────────────────────

    def _on_expo_changed(self, value: int):
        self._expo = value / 100.0
        self._expo_value_label.setText(f"{value}%")
        self.expo_changed.emit(self._expo)

    def _on_deadzone_changed(self, value: int):
        self._deadzone = value / 100.0
        self._dz_value_label.setText(f"{value}%")
        self.deadzone_changed.emit(self._deadzone)

    def _reset_defaults(self):
        self._expo_slider.setValue(30)
        self._dz_slider.setValue(5)

    # ── Style ────────────────────────────────────────────────────────────────

    def _setup_styles(self):
        self.setStyleSheet("""
            QWidget {
                background-color: #121212;
                color: #ffffff;
                font-family: 'Segoe UI', Arial, sans-serif;
            }
            QScrollArea {
                background-color: #121212;
                border: none;
            }
            QSlider::groove:horizontal {
                border: 1px solid #333;
                height: 6px;
                background: #2a2a2a;
                border-radius: 3px;
            }
            QSlider::handle:horizontal {
                background: #FF8800;
                border: none;
                width: 18px;
                height: 18px;
                margin: -6px 0;
                border-radius: 9px;
            }
            QSlider::sub-page:horizontal {
                background: #FF8800;
                border-radius: 3px;
            }
            QPushButton {
                background-color: #2d2d2d;
                color: #ffffff;
                border: 1px solid #444444;
                border-radius: 6px;
                padding: 8px 16px;
                font-size: 13px;
            }
            QPushButton:hover {
                background-color: #3d3d3d;
                border-color: #FF8800;
            }
            QPushButton:pressed {
                background-color: #FF8800;
                color: #000000;
            }
        """)
