# Points App Overview

## Purpose
Points is a productivity and habit tracking app that uses a gamified points-based system to help users manage their daily tasks and routines.

## Core Features
- **Task Management**: Create and track both routines (recurring habits) and one-time tasks
- **Points System**: Assign point values to activities to measure daily progress
- **Completion Tracking**: Set targets and track completion counts with interactive controls
- **Visual Progress**: Monitor daily achievement with an animated progress bar
- **Critical Tasks**: Flag high-priority items for special attention
- **Templates**: Save frequent tasks as templates for quick reuse

## Technical Architecture
- Built with SwiftUI and CoreData
- Singleton design pattern with central TaskControllers
- Persistent storage of tasks, dates, and completion data
- Custom UI controls with gesture recognition
- Theme system supporting light/dark modes

## User Interface
- **Main Screen**: Task list with progress bar and date navigation
- **Task Cards**: Interactive cells with completion counters and swipe gestures
- **Action Bar**: Quick access buttons for common actions
- **Custom Forms**: Specialized input for task creation and editing
- **Custom Numeric Keyboard**: Tailored input for point values and counts

## Gamification Elements
- Daily point targets and visual progress tracking
- Reward points for meeting completion targets
- Visual feedback for task completion
- Performance statistics and trends

The app focuses on providing an engaging and interactive experience for tracking daily activities, with gamification elements designed to motivate consistent usage and habit formation.