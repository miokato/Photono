# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

- **Build**: Open `Photono.xcodeproj` in Xcode and use `Cmd+B` to build
- **Run**: Use `Cmd+R` in Xcode to run the app in simulator
- **Clean**: Use `Cmd+Shift+K` in Xcode to clean build folder

## Architecture Overview

Photono is a SwiftUI-based iOS app that combines photo viewing and music playing functionality. The app follows a modular architecture with clear separation of concerns:

### Core Structure
- **App Entry Point**: `PhotonoApp.swift` - Main app struct using SwiftUI App protocol
- **Main Navigation**: `MainView.swift` - TabView with Photo and Music tabs
- **Models**: Simple data models wrapping Apple frameworks (PhotoAsset wraps PHAsset)
- **Services**: Actor-based services for async operations (PhotoLibrary, MusicPlayer, AppleMusicAPIClient)
- **Views**: Organized by feature (Photo/, Music/) with shared Components/

### Key Architectural Patterns

**Actor-based Services**: All data services use Swift's actor model for safe concurrency:
- `PhotoLibrary` - Manages PHPhotoLibrary access and image loading
- `MusicPlayer` - Wraps ApplicationMusicPlayer for playback control

**SwiftUI + Async/Await**: Views use modern Swift concurrency with `@State` and `.task` modifiers for async operations.

**Permission Handling**: Both photo and music features implement proper permission flows before accessing system resources.

### Dependencies
- **Photos Framework**: For photo library access and PHAsset management
- **MusicKit**: For Apple Music integration and playback
- **SwiftUI**: Primary UI framework

### Localization
- Uses `Localizable.xcstrings` for string localization
- Japanese locale support implemented in preview code

### File Organization
- Services are single-purpose actors in `Services/`
- Views follow feature-based organization with reusable components
- Extensions and helpers are separated into dedicated folders