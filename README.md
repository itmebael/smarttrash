# Smart Trashcan Mobile Application - Samar State University

A comprehensive Flutter mobile application for managing smart trashcans across the Samar State University campus. This eco-friendly solution helps maintain cleanliness and efficiency through real-time monitoring, task management, and analytics.

## 🌱 Features

### 🔑 User Roles

#### Admin (Utility Office Staff)
- **Campus Map View**: View all smart trashcans on an interactive Google Maps interface
- **Real-time Monitoring**: Monitor trashcan status (Empty/Half/Full) with color-coded markers
- **Staff Management**: Assign cleaning tasks to staff members
- **Analytics & Reports**: Generate comprehensive reports on trash collection patterns
- **Last Emptied Tracking**: Monitor when each trashcan was last serviced

#### Staff (Janitors/Utility Workers)
- **Task Notifications**: Receive push notifications when trashcans are full
- **Task Management**: View and manage assigned cleaning tasks
- **Status Updates**: Mark trashcans as emptied with timestamp updates
- **QR Code Scanning**: Quick trashcan identification and task completion

### 📱 Core Features

#### 🗺️ Map Integration
- **Google Maps Integration**: Interactive campus map with real-time trashcan locations
- **Color-coded Markers**: 
  - 🟢 Green: Empty trashcans
  - 🟡 Yellow: Half-full trashcans  
  - 🔴 Red: Full trashcans
  - 🔵 Blue: Maintenance required
- **Real-time Updates**: Live status updates from IoT sensors
- **Filter Options**: Filter trashcans by status

#### 📊 Monitoring & Analytics
- **IoT Sensor Integration**: Ultrasonic and weight sensors connected via ESP32/Arduino
- **Real-time Status**: Continuous monitoring of fill levels
- **Usage Statistics**: Track which areas fill faster and peak usage times
- **Predictive Analytics**: AI-powered predictions for maintenance needs

#### 🔔 Notification System
- **Push Notifications**: Instant alerts for full trashcans
- **Task Reminders**: Automated reminders for overdue tasks
- **Admin Alerts**: Notifications for trashcans not emptied within specified time
- **Customizable Settings**: User-configurable notification preferences

#### 📋 Task Management
- **Assignment System**: Admins can assign specific trashcans to staff
- **Progress Tracking**: Real-time task status updates
- **Completion Confirmation**: Staff can mark tasks as completed
- **Priority Levels**: High, Medium, Low, and Urgent task priorities

#### 📈 Reports & Analytics
- **Daily/Weekly/Monthly Reports**: Comprehensive collection statistics
- **Usage Patterns**: Identify high-traffic areas and peak times
- **Staff Performance**: Track cleaning efficiency and completion rates
- **Export Functionality**: Download reports in various formats

#### 🔍 Additional Features
- **QR Code Integration**: Quick trashcan identification and task confirmation
- **Offline Support**: Basic functionality available without internet
- **Dark Mode**: Eco-friendly dark theme option
- **Accessibility**: Voice-over support and high contrast options

## 🛠️ Technical Stack

### Frontend
- **Flutter**: Cross-platform mobile development
- **Dart**: Programming language
- **Riverpod**: State management
- **Go Router**: Navigation
- **Google Maps**: Map integration
- **Material Design 3**: Modern UI components

### Backend & Services
- **Firebase**: Authentication, Firestore database, Cloud Messaging
- **Google Maps API**: Location services and mapping
- **RESTful API**: Custom backend for data management
- **Push Notifications**: Firebase Cloud Messaging

### IoT Integration
- **ESP32/Arduino**: Microcontroller for sensor data
- **Ultrasonic Sensors**: Fill level detection
- **Weight Sensors**: Capacity monitoring
- **WiFi Connectivity**: Real-time data transmission

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code
- Google Maps API Key
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ssu/smart-trashcan-app.git
   cd smart-trashcan-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project
   - Add Android/iOS apps to the project
   - Download and place configuration files:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`

4. **Configure Google Maps**
   - Get a Google Maps API key
   - Update `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_GOOGLE_MAPS_API_KEY" />
     ```

5. **Run the application**
   ```bash
   flutter run
   ```

## 📱 Screenshots

### Dashboard
- Clean, eco-friendly interface with real-time statistics
- Quick action buttons for common tasks
- Status overview with color-coded indicators

### Map View
- Interactive Google Maps with trashcan markers
- Filter options for different statuses
- Real-time location tracking

### Task Management
- Assigned tasks with priority indicators
- Progress tracking and completion status
- Due date reminders and notifications

## 🎨 Design Philosophy

The application follows an **eco-friendly design philosophy** with:
- **Green Color Scheme**: Primary colors inspired by nature
- **Clean Interface**: Minimalist design reducing visual clutter
- **Sustainable UX**: Efficient workflows reducing time and energy
- **Accessibility**: Inclusive design for all users

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:
```env
GOOGLE_MAPS_API_KEY=your_api_key_here
FIREBASE_PROJECT_ID=your_project_id
API_BASE_URL=https://api.smarttrashcan-ssu.com
```

### Firebase Rules
Configure Firestore security rules for your use case:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /trashcans/{trashcanId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## 📊 Data Models

### User Model
```dart
class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role; // admin, staff
  final DateTime createdAt;
  // ... other fields
}
```

### Trashcan Model
```dart
class TrashcanModel {
  final String id;
  final String name;
  final LatLng coordinates;
  final TrashcanStatus status; // empty, half, full, maintenance
  final double fillLevel;
  final DateTime lastEmptiedAt;
  // ... other fields
}
```

### Task Model
```dart
class TaskModel {
  final String id;
  final String title;
  final String trashcanId;
  final String assignedStaffId;
  final TaskStatus status; // pending, inProgress, completed
  final TaskPriority priority; // low, medium, high, urgent
  // ... other fields
}
```

## 🚀 Deployment

### Android
1. Generate a signed APK:
   ```bash
   flutter build apk --release
   ```

2. Or build an App Bundle:
   ```bash
   flutter build appbundle --release
   ```

### iOS
1. Build for iOS:
   ```bash
   flutter build ios --release
   ```

2. Archive and upload via Xcode

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Development Team**: Samar State University IT Department
- **Project Lead**: [Your Name]
- **UI/UX Design**: [Designer Name]
- **IoT Integration**: [Hardware Team]

## 📞 Support

For support and questions:
- Email: smarttrashcan@ssu.edu.ph
- Phone: +63-XXX-XXX-XXXX
- Office: Utility Office, Samar State University

## 🔮 Future Enhancements

- **AI-Powered Predictions**: Machine learning for fill level forecasting
- **Gamification**: Leaderboards and rewards for staff efficiency
- **Voice Commands**: Hands-free operation for staff
- **AR Integration**: Augmented reality for trashcan identification
- **Multi-language Support**: Local language support
- **Advanced Analytics**: Predictive maintenance and optimization

---

**Made with ❤️ for a cleaner Samar State University**
