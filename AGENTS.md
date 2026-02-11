# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a Flutter plugin (`flutter_v2ray_client`) that provides V2Ray/Xray VPN client functionality. It supports Android (free) and iOS/Windows/Linux/macOS (premium). The plugin handles V2Ray share link parsing (vmess, vless, trojan, shadowsocks, socks) and native VPN tunneling.

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run tests
flutter test

# Run a specific test file
flutter test test/flutter_v2ray_client_test.dart

# Lint/analyze code
flutter analyze

# Format code
flutter format .

# Run example app (from project root)
cd example && flutter run

# Build Android AAR (for native development)
cd android && ./gradlew assembleDebug
```

## Code Architecture

### Layer Structure

```
lib/
├── flutter_v2ray.dart              # Main V2ray class - public API entry point
├── flutter_v2ray_platform_interface.dart  # Abstract platform interface
├── flutter_v2ray_method_channel.dart      # Method channel implementation
├── model/
│   └── v2ray_status.dart           # Connection status model
└── url/
    ├── url.dart                    # V2RayURL base class with config generation
    ├── vmess.dart                  # VmessURL parser
    ├── vless.dart                  # VlessURL parser  
    ├── trojan.dart                 # TrojanURL parser
    ├── shadowsocks.dart            # ShadowSocksURL parser
    └── socks.dart                  # SocksURL parser
```

### Key Patterns

1. **Platform Interface Pattern**: The plugin uses Flutter's federated plugin architecture with `FlutterV2rayPlatform` as the abstract interface and `MethodChannelFlutterV2ray` as the default implementation.

2. **URL Parsing Strategy**: Each protocol (vmess, vless, etc.) extends `V2RayURL` base class and implements `outbound1` getter. The base class handles transport settings (`populateTransportSettings`) and TLS settings (`populateTlsSettings`).

3. **Native Communication**: Uses Flutter's MethodChannel (`flutter_v2ray_client`) for commands and EventChannel (`flutter_v2ray_client/status`) for real-time status updates.

### Android Native Structure

```
android/src/main/java/dev/amirzr/flutter_v2ray_client/
├── FlutterV2rayPlugin.java         # Plugin registration and method handling
└── v2ray/
    ├── V2rayController.java        # Main V2Ray control logic
    ├── V2rayReceiver.java          # Broadcast receiver
    ├── core/V2rayCoreManager.java  # Xray core management
    ├── services/
    │   ├── V2rayVPNService.java    # VPN mode service
    │   └── V2rayProxyOnlyService.java  # Proxy-only mode service
    ├── interfaces/V2rayServicesListener.java
    └── utils/
        ├── AppConfigs.java
        ├── Utilities.java
        ├── V2rayConfig.java
        └── LogcatManager.java
```

## Code Style Requirements

- **Documentation**: All public members require API docs (`public_member_api_docs` lint rule)
- **Strings**: Use single quotes (`'`) not double quotes
- **Constructors**: Prefer `const` constructors where possible
- **Variables**: Prefer `final` for local variables and fields
- **Naming**: 
  - Classes: `PascalCase` (e.g., `V2rayService`)
  - Methods/variables: `camelCase` (e.g., `startV2Ray`)
  - Constants: `SCREAMING_SNAKE_CASE` (e.g., `DEFAULT_TIMEOUT`)

## Commit Message Format

Use conventional commit style:
```
feat: add new V2Ray connection method
fix: resolve memory leak in Android VPN service
docs: update API documentation
test: add unit tests for URL parser
```

## Testing

Tests are in `test/flutter_v2ray_client_test.dart`. The project uses `flutter_test` with widget binding initialization required for plugin tests. When adding URL parser tests, use base64-encoded test configs for vmess and decoded URI format for vless/trojan/shadowsocks/socks.
