# LocAbility

**Athens Accessibility Map - Empowering citizens with accessible mobility**

Petros Dhespollari © 2025

---

## 🌟 About LocAbility

LocAbility is a native iOS application that enables citizens to discover, record, and evaluate accessibility points across Athens. Through an interactive map, users can view ramps, elevators, step-free entrances, and obstacle-free pathways. With photos or voice input, they can add new accessibility spots. Apple on-device AI classifies each point automatically and privately.

The app complements and builds upon existing digital initiatives of the Municipality of Athens, such as the **Athens GIS portal** (https://gis.cityofathens.gr) and the **Smart Neighborhood services** (https://www.cityofathens.gr/psifiakes-ypiresies-exypnis-geitonias/), bringing their vision directly into the hands of residents.

### Why LocAbility Exists

Daily mobility in Athens is challenging for people with disabilities, elderly citizens, parents with strollers, and anyone who depends on safe and accessible paths. Athens lacks a unified, reliable, and continuously updated accessibility map. LocAbility introduces the first live, citizen-powered accessibility map that reflects the real, day-to-day experience of moving around the city.

The project aligns with the mission of **Apps4Athens** (https://apps4athens.gr/ai/en/) to foster AI-powered civic innovation.

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
- Extends existing resources like **AccessibleRoutes Athens** (https://accessibleroutes.thisisathens.org) with real-time, citizen-generated insights  

### ➕ Add Accessibility Spots

- **Photo Capture**: Take or upload photos of accessibility features  
- **Voice Input**: Record voice descriptions using Speech framework  
- **On-Device AI**: Automatic classification using Vision and Core ML  
- **Privacy First**: All AI processing happens on-device  

### 📊 Neighborhood Accessibility Score

- Each neighborhood receives a score (0–100)  
- Based on quantity, quality, and variety of accessible features  
- Helps users identify friendly, safe, and walkable areas  

### ♿ Full Accessibility Support

- VoiceOver compatibility  
- Dynamic Type support  
- High contrast mode  
- Haptic feedback  
- Keyboard navigation  

---

## 🛠️ Technical Stack

### Frameworks & Technologies

- **SwiftUI**  
- **MapKit**  
- **CoreLocation**  
- **AVFoundation**  
- **Speech**  
- **Vision**  
- **Core ML**  
- **PhotosUI**  

### Architecture

- MVVM  
- ObservableObject  
- Combine  
- Swift Concurrency (async/await)  

### Accessibility Features

- WCAG 2.1 AAA–oriented design  
- Dynamic Type  
- Proper semantic grouping  
- VoiceOver announcements  
- High contrast support  
- Reduced motion support  

---

## 📱 Requirements

- iOS 17.0+  
- Xcode 15.0+  
- Swift 5.9+  
- iPhone or iPad with location services  

---

## 🤖 On-Device AI Features

### Speech Recognition  
- Converts voice descriptions to text  
- On-device only  
- Multi-language support  
- Real-time transcription  

### Vision Framework  
- Detects accessibility features in images  
- Identifies ramps, elevators, entrances  
- Rectangle detection  
- Private by design  

### Natural Language Processing  
- Keyword-based classification  
- Intent recognition  
- Sentiment analysis  
- On-device only  

### Core ML Integration  
- Extensible classifier models  
- Ready for custom image/text models  

---

## 🌍 Data Sources

### Initial Dataset

LocAbility integrates with and enhances official and open datasets:

- **OpenStreetMap (OSM)**  
- **Athens GIS Portal**: https://gis.cityofathens.gr  
- **AccessibleRoutes Athens**: https://accessibleroutes.thisisathens.org  
- **Smart Neighborhood Services**: https://www.cityofathens.gr/psifiakes-ypiresies-exypnis-geitonias/  
- **Municipality of Athens open datasets**  
- Disability advocacy groups  
- Manual seeding by project team  
- **Crowdsourcing**: citizen-generated data (main source)  

### Privacy & Data Handling

- Photos processed on-device only  
- No server storage  
- Location data anonymized  
- Privacy-first design  

---

## ♿ Accessibility Compliance

### VoiceOver

- Descriptive labels  
- Heading hierarchy  
- Grouped navigation  
- Live updates announced  

### Visual Accessibility

- High contrast mode  
- Large text support  
- Proper contrast ratios  
- Visible focus indicators  

### Motor Accessibility

- Large touch targets  
- No time-based interactions  
- Haptic confirmations  

### Cognitive Accessibility

- Clear, consistent flow  
- Simple language  
- Progress indicators  
- Undo/cancel everywhere  

---

## 🧪 Testing

### Run Tests

```bash
# Run all tests
xcodebuild test -scheme LocAbility -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -scheme LocAbility -only-testing:LocAbilityTests/AccessibilityTests
