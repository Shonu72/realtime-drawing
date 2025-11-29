# Realtime Drawing Frontend (Flutter)

Multiplayer whiteboard frontend built with Flutter for web, Android, iOS, and desktop.

## Features

- 🎨 Real-time collaborative drawing
- 📱 Multi-platform support (Web, Android, iOS, Desktop)
- 🖊️ Multiple drawing tools (Pencil, Brush, Highlighter, Eraser)
- 👥 Live cursor tracking
- 💬 Real-time chat
- 🔄 Undo/Redo functionality
- 📐 Infinite canvas with pan & zoom
- 🎭 Multiple layers support
- 📤 Export to PNG, SVG, PDF

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Dart 3.0+

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Generate Hive adapters (if needed):
```bash
flutter pub run build_runner build
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
frontend/lib/
├── main.dart
├── core/
│   ├── theme/          # App theme and colors
│   ├── constants/      # App constants
│   └── utils/          # Utility functions
├── features/
│   ├── board/          # Board/drawing features
│   ├── auth/           # Authentication
│   ├── chat/           # Chat feature
│   └── workspace/      # Workspace management
├── services/
│   ├── socket_service.dart
│   ├── stroke_service.dart
│   └── storage_service.dart
└── widgets/
    ├── drawing_canvas.dart
    └── tool_palette.dart
```

## Configuration

Update the backend URL in `lib/core/constants/api_constants.dart`:

```dart
const String API_BASE_URL = 'http://localhost:3000';
const String SOCKET_URL = 'http://localhost:3000';
```

