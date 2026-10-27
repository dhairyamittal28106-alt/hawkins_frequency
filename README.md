# The Hawkins Frequency

A Stranger Things-inspired Flutter experience with a retro CRT look and interactive "other dimension" tools. The screens include a dimension-switch scene, a camera-based psychic-focus experience, a sensor-driven rift detector, and a Christmas-lights chat. Camera, face-detection, motion-sensor, and audio packages power the effects.

## Run locally

Install Flutter 3.10 or newer, then run:

    flutter pub get
    flutter run

Allow camera and sensor permissions when prompted. Some features depend on device hardware and may not work in an emulator.

## Project layout

- `lib/dimension_switch_screen.dart`: main dimension-switch experience
- `lib/psychic_focus_screen.dart`: camera and face-detection interaction
- `lib/rift_detector_screen.dart`: sensor-based compass/rift display
- `lib/christmas_lights_chat_screen.dart`: light-sequence interaction
- `assets/audio/`: bundled sound effects

The interface and audio are a fan-made prototype and are not affiliated with the Stranger Things series or its rights holders.
