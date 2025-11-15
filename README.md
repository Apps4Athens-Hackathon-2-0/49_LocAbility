# LocAbility

**Athens Accessibility Map - Empowering citizens with accessible mobility**

Petros Dhespollari @Copyright 2025

---

## 🌟 About LocAbility

LocAbility is a native iOS application that enables citizens to discover, record, and evaluate accessibility points across Athens. Through an interactive map, users can view ramps, elevators, step-free entrances, and obstacle-free pathways. With photos or voice input, they can add new accessibility spots. Apple on-device AI classifies each point automatically and privately.

### Why LocAbility Exists

Daily mobility in the Municipality of Athens is challenging for people with disabilities, elderly citizens, parents with strollers, and anyone who depends on safe and accessible paths. Athens lacks a unified, reliable, and continuously updated accessibility map. LocAbility introduces the first live, citizen-powered accessibility map that reflects the real, day-to-day experience of moving across Athens.

### Who Is It For?

- ♿ People with disabilities (PWD)
- 👴 Elderly residents
- 👶 Parents with strollers
- 🤝 Caregivers and families
- 👥 Citizens who want to contribute
- 🏛️ The Municipality of Athens for data-driven urban planning

---

## ✨ Key Features

### 🗺️ Interactive Accessibility Map
- View accessibility points on an interactive map using MapKit
- Filter by type: wheelchair-friendly, stroller-friendly, ramps, elevators
- Real-time location tracking
- Get directions to accessible features

### ➕ Add Accessibility Spots
- **Photo Capture**: Take or upload photos of accessibility features
- **Voice Input**: Record voice descriptions using Speech framework
- **On-Device AI**: Automatic classification using Vision and Core ML
- **Privacy First**: All AI processing happens on your device

### 📊 Neighborhood Accessibility Score
- Each neighborhood receives an accessibility score (0-100)
- Based on quantity, quality, and variety of accessible features
- Helps users identify safe and comfortable areas

### ♿ Full Accessibility Support
- VoiceOver compatible with proper ARIA labels
- Dynamic Type support for text scaling
- High contrast mode option
- Haptic feedback for important actions
- Keyboard navigation support

---

## 🛠️ Technical Stack

### Frameworks & Technologies
- **SwiftUI**: Modern declarative UI framework
- **MapKit**: Interactive maps with custom annotations
- **CoreLocation**: Location services and geofencing
- **AVFoundation**: Audio recording and playback
- **Speech**: On-device speech recognition
- **Vision**: Image analysis and feature detection
- **Core ML**: On-device machine learning classification
- **PhotosUI**: Modern photo picker

### Architecture
- **MVVM Pattern**: Clean separation of concerns
- **ObservableObject**: Reactive state management
- **Combine**: Reactive programming for data flow
- **Swift Concurrency**: async/await for clean asynchronous code

### Accessibility Features
- Full VoiceOver support with descriptive labels
- Dynamic Type for text scaling
- Semantic HTML structure
- WCAG 2.1 AAA compliance
- High contrast mode
- Reduced motion support

---

## 📱 Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- iPhone or iPad with location services

---

## 🤖 On-Device AI Features

### Speech Recognition
- Converts voice descriptions to text
- Processes entirely on-device for privacy
- Supports multiple languages
- Real-time transcription

### Vision Framework
- Detects accessibility features in photos
- Identifies ramps, elevators, and entrances
- Rectangle detection for structural elements
- Privacy-preserving image analysis

### Natural Language Processing
- Keyword-based classification
- Intent recognition for spot types
- Sentiment analysis for descriptions
- On-device processing only

### Core ML Integration
- Ready for custom trained models
- Placeholder for accessibility feature classifier
- Can be extended with:
  - Image classification models
  - Text classification models
  - Custom Core ML models

---

## 🌍 Data Sources

### Initial Dataset
- **OpenStreetMap (OSM)**: Existing accessible features
- **Municipality of Athens**: Open municipal datasets
- **Disability Advocacy Groups**: Open access datasets
- **Manual Seeding**: Initial coverage by project team
- **Crowdsourcing**: Citizen-generated data (main source)

### Privacy & Data Handling
- All AI processing happens on-device
- No voice recordings or photos sent to servers
- Location data anonymized when shared
- User privacy is paramount

---

## ♿ Accessibility Compliance

### VoiceOver Support
- All UI elements have descriptive labels
- Proper heading hierarchy
- Grouped elements for better navigation
- Dynamic content updates announced

### Visual Accessibility
- High contrast mode option
- Large text support (Dynamic Type)
- Clear color contrast ratios
- Visual focus indicators

### Motor Accessibility
- Large touch targets (minimum 44x44pt)
- No time-based interactions
- Alternative input methods
- Haptic feedback for confirmation

### Cognitive Accessibility
- Clear, simple language
- Consistent navigation
- Progress indicators
- Undo/cancel options

---

## 🧪 Testing

### Running Tests
```bash
# Run all tests
xcodebuild test -scheme LocAbility -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -scheme LocAbility -only-testing:LocAbilityTests/AccessibilityTests
```

### Accessibility Testing
1. Enable VoiceOver (Settings > Accessibility > VoiceOver)
2. Navigate through the app using VoiceOver gestures
3. Test with Dynamic Type at different sizes
4. Verify all interactive elements are accessible

---

## 📊 How It Works - MVP Flow

1. **User opens the map** to view nearby accessibility points
2. **User taps 'Add Spot'** and submits a photo or voice note
3. **AI classifies the spot** (ramp, elevator, accessible entrance)
4. **The spot appears on the map** and contributes to neighborhood scoring
5. **Users filter areas** based on their specific mobility needs

---

## 🎯 Future Enhancements

- [ ] Backend API integration for data sync
- [ ] User authentication and profiles
- [ ] Social features (comments, ratings, verification)
- [ ] Offline mode with cached data
- [ ] Apple Watch companion app
- [ ] Route planning with accessibility preferences
- [ ] Integration with public transit data
- [ ] Gamification (badges, achievements)
- [ ] Community moderation system
- [ ] Multi-language support (Greek, English, etc.)

---

## 🤝 Contributing

LocAbility is built to empower the community. Contributions are welcome!

### How to Contribute
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Code Standards
- Follow Swift API Design Guidelines
- Add accessibility labels to all UI elements
- Write descriptive commit messages
- Include documentation for public APIs

---

## 📄 License

Copyright © 2025 Petros Dhespollari. All rights reserved.

---

## 🙏 Acknowledgments

- OpenStreetMap contributors
- Municipality of Athens
- Disability advocacy groups
- iOS accessibility community
- All citizens contributing to making Athens more accessible

---

## 📞 Contact & Support

For questions, suggestions, or support:
- Create an issue on GitHub
- Contact: info@peterdsp.dev

---

## 💙 Impact

LocAbility empowers the citizens of Athens to move with dignity, autonomy, and safety. It supports people with disabilities, senior citizens, and parents while giving the Municipality real, actionable insights to guide improvements. Through crowdsourcing and on-device AI, LocAbility transforms Athens into a more inclusive, human-centered, and accessible city for everyone.

**Together, we make Athens accessible for all.**

---

Made with ❤️ for Athens | Petros Dhespollari @Copyright 2025
