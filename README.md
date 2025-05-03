# Face KYC Library

A Flutter library for implementing face detection and KYC (Know Your Customer) functionality in mobile applications. This library provides components for real-time face detection, camera handling, and face validation.

## Components

- `main.dart` - Entry point of the application with dark theme configuration
- `face_detection_camera.dart` - Core camera handling and face detection implementation using Google ML Kit
- `face_painter.dart` - Custom painting for face detection overlays
- `coordinates_calc.dart` - Utility for face coordinate calculations
- `home_page.dart` - Main UI implementation
- `image_preview.dart` - Component for previewing captured images

## Features

- Real-time face detection using Google ML Kit
- Camera permission handling
- Support for both iOS and Android platforms
- Custom face detection overlay
- Dark theme UI
- Image capture and preview functionality

## Dependencies

- `camera` - For camera access and control
- `google_mlkit_face_detection` - For face detection capabilities
- `permission_handler` - For managing camera permissions
- `flutter/material.dart` - Flutter's material design components

## Usage

The main component `CameraView` can be used to implement face detection in your Flutter application. It provides callbacks for:
- Face detection events
- Camera feed status
- Camera direction changes
- Image capture
