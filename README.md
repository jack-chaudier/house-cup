# House Cup 🏆

A comprehensive iOS app for managing school house point systems, inspired by traditional school house competitions. Built with SwiftUI and Firebase, House Cup enables schools to track student achievements, manage rewards, and foster healthy competition between houses.

## Features

### For Students 🎓
- **View House Standings**: Real-time leaderboard showing house rankings
- **Track Personal Progress**: View point history and achievements
- **Points Shop**: Spend earned points on rewards and privileges
- **Announcements**: Stay updated with school-wide and house-specific news
- **Profile Management**: Customize profile and view statistics

### For Teachers 👨‍🏫
- **Award Points**: Recognize student achievements across multiple categories
- **Class Management**: Organize and manage assigned classes
- **Create Announcements**: Communicate with students effectively
- **Request Shop Items**: Propose new rewards for the points shop
- **Track Student Progress**: Monitor individual and class performance

### For Administrators 👩‍💼
- **User Management**: Approve new users and manage roles
- **House Management**: Create and configure houses by grade level
- **Points Overview**: Monitor all point transactions
- **Shop Administration**: Approve and manage shop items
- **Analytics & Reports**: Access comprehensive data insights
- **System-wide Announcements**: Broadcast important messages

## Tech Stack

- **Frontend**: SwiftUI (iOS 15+)
- **Backend**: Firebase (Firestore, Authentication)
- **Authentication**: Google Sign-In
- **Architecture**: MVVM with Combine framework
- **Styling**: Custom theme system with dynamic colors

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Firebase account
- Google Cloud Console project (for Sign-In)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/house-cup.git
cd house-cup
```

2. Install dependencies:
```bash
# If using CocoaPods
pod install

# If using Swift Package Manager
# Dependencies will be resolved automatically in Xcode
```

3. Firebase Setup:
   - Create a new Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Authentication with Google Sign-In provider
   - Create a Firestore database
   - Download `GoogleService-Info.plist` and add it to the project
   - Enable the following Firestore collections:
     - `users`
     - `houses`
     - `pointAwards`
     - `shopItems`
     - `announcements`
     - `classes`
     - `shopRequests`
     - `purchaseHistory`

4. Configure Google Sign-In:
   - Set up OAuth 2.0 credentials in Google Cloud Console
   - Add your iOS app's bundle identifier
   - Configure URL schemes in Info.plist

5. Open `house-cup.xcodeproj` in Xcode and build

## Project Structure

```
house-cup/
├── Auth/
│   ├── AuthManager.swift       # Authentication logic
│   └── SignInView.swift        # Sign-in UI
├── Models/
│   ├── AppUser.swift          # User model with roles
│   ├── House.swift            # House configuration
│   ├── PointAward.swift       # Point transaction records
│   ├── ShopItem.swift         # Rewards catalog
│   └── ...                    # Other data models
├── Views/
│   ├── Admin/                 # Administrator views
│   ├── Teacher/               # Teacher views
│   ├── Student/               # Student views
│   └── Shared/                # Common components
├── Theme/
│   └── Theme.swift            # App-wide styling
└── Extensions/                # Swift extensions
```

## Data Models

### User Roles
- **Admin**: Full system access and management capabilities
- **Teacher**: Award points, manage classes, create announcements
- **Student**: View points, shop for rewards, track progress
- **Pending**: Awaiting role assignment

### House System
- Houses are organized by grade levels (9-12)
- Each house has a unique color, mascot, and motto
- Points accumulate throughout the academic year
- Dynamic theming based on student's house

### Point Categories
- Academic Achievement
- Good Behavior
- Leadership
- Community Service
- Athletics
- Arts
- Other

## Key Features Implementation

### Dynamic Theming
The app automatically adapts its accent color based on the user's house affiliation, creating a personalized experience for each student.

### Role-Based Access Control
Different UI components and features are displayed based on the authenticated user's role, ensuring appropriate access levels.

### Real-time Updates
Firebase Firestore provides real-time synchronization, ensuring all users see the latest point standings and announcements.

### Approval Workflows
Shop items follow an approval process: teachers create requests, administrators review and approve items before they become available to students.

## Security Considerations

- Authentication required for all app features
- Role-based access control at UI and database levels
- Firestore security rules enforce data access permissions
- No sensitive data stored locally
- Secure Google OAuth flow for authentication

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by traditional school house point systems
- Built with SwiftUI and Firebase
- Uses Google Sign-In for secure authentication

## Support

For issues, questions, or contributions, please open an issue on GitHub or contact the development team.

---

Made with ❤️ for schools looking to gamify student achievement and build house spirit.