# Visitor Entry App

A comprehensive Flutter application for managing visitor entries with Firebase backend integration.

## Features

### 🔐 Authentication
- Email/password authentication
- User registration and login
- Secure session management
- Logout functionality

### 👥 Visitor Management
- Add new visitors with detailed information
- Capture visitor photos using camera
- Upload ID proof documents
- Track entry and exit times
- Check-in and check-out functionality

### 📱 User Interface
- Modern, responsive design
- Intuitive navigation
- Real-time data updates
- Search and filter capabilities
- Beautiful gradient backgrounds

### 🗄️ Data Storage
- Firebase Firestore for visitor data
- Firebase Storage for images
- Real-time synchronization
- Offline support

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Firebase
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **State Management**: Provider

## Getting Started

### Prerequisites
- Flutter SDK (3.8.0 or higher)
- Firebase project
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd visitor_entry_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project
   - Enable Authentication, Firestore, and Storage
   - Run `flutterfire configure` to generate configuration files

4. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/
│   └── visitor.dart         # Visitor data model
├── services/
│   ├── auth_service.dart    # Authentication service
│   └── visitor_service.dart # Visitor CRUD operations
└── screens/
    ├── login_screen.dart    # Login/Registration screen
    ├── home_screen.dart     # Main dashboard
    ├── add_visitor_screen.dart # Add visitor form
    └── visitor_list_screen.dart # Visitor list and management
```

## Usage

### Authentication
1. Launch the app
2. Create an account or sign in with existing credentials
3. Access the main dashboard

### Adding Visitors
1. Tap "Add Visitor" from the home screen
2. Fill in visitor details (name, phone, purpose, host)
3. Capture visitor photo (optional)
4. Upload ID proof (optional)
5. Submit the form

### Managing Visitors
1. View all visitors in the "View Visitors" section
2. Filter by status (checked-in/checked-out)
3. Check out visitors when they leave
4. Delete visitor records if needed
5. Search visitors by name

## Firebase Setup

### Authentication
- Enable Email/Password authentication in Firebase Console
- Configure sign-in methods as needed

### Firestore Database
- Create a collection named "visitors"
- Set up security rules for data access

### Storage
- Configure Firebase Storage rules
- Set up folders for visitor_photos and id_proofs

## Security Features

- Secure authentication with Firebase Auth
- Data validation and sanitization
- Image upload security
- Real-time data synchronization
- Offline data persistence

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions, please open an issue in the repository.
