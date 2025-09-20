# SurakshaPay - Secure Voice-Enabled Payment App

A Flutter-based payment application with voice commands, fraud detection, and regional language support, designed to make digital payments accessible to everyone.

## 🚀 Features

### Core Features
- **Voice Commands**: Complete app navigation and transaction processing through voice
- **Multi-language Support**: Hindi, English, Bengali, Tamil, Telugu
- **Fraud Detection**: AI-powered real-time fraud detection and prevention
- **Duress PIN**: Emergency security feature for threatening situations
- **QR Code Payments**: Send and receive money via QR codes
- **Real-time Dashboard**: Streamlit-based bank simulator for monitoring

### Security Features
- **PIN Authentication**: 4-digit PIN + Duress PIN system
- **Fraud Monitoring**: Real-time transaction analysis
- **Trusted Contact Alerts**: Emergency notifications
- **Voice Pattern Analysis**: Suspicious command detection

## 🛠️ Tech Stack

### Frontend (Mobile App)
- **Flutter** (Dart) - Cross-platform mobile development
- **Supabase Flutter SDK** - Backend integration
- **Speech-to-Text** - Google Speech API / Vosk
- **Text-to-Speech** - Flutter TTS
- **QR Code** - QR generation and scanning

### Backend
- **Supabase** - PostgreSQL database, authentication, real-time subscriptions
- **Python Flask** - Fraud detection microservice
- **Streamlit** - Bank simulator dashboard

### AI & Analytics
- **Python NLP** - Voice command processing
- **Pattern Recognition** - Fraud detection algorithms
- **Real-time Analytics** - Transaction monitoring

## 📱 App Flow

### 1. Splash Screen
- Logo + tagline: "Secure Payments Made Simple"
- Auto-check: If user logged in → Home; otherwise → Login

### 2. Registration Flow
- User enters: Name, Phone Number, Trusted Contact
- Sets PIN + Duress PIN
- Stored securely in Supabase

### 3. Login Flow
- Phone Number + PIN (voice/text)
- Main PIN → Home Screen
- Duress PIN → Fake success + Silent alert

### 4. Home Screen
- Balance display
- Send Money | Receive Money buttons
- Recent Transactions
- Floating Voice Assistant Button

### 5. Send Money Flow
- Voice: "Ramesh ko 500 bhej do"
- NLP extracts: {receiver: "Ramesh", amount: 500}
- Confirmation in same language
- PIN verification
- Transaction processing

### 6. Receive Money Flow
- Voice: "Mera QR code dikhado"
- QR code + UPI ID display
- Real-time balance updates

### 7. Fraud Detection
- Background microservice monitoring
- Gambling/betting keyword detection
- Suspicious transaction patterns
- Real-time alerts

## 🗄️ Database Schema

### Tables
- **users**: User profiles, PINs, balances
- **contacts**: User contact lists
- **transactions**: Payment history
- **fraud_logs**: Security alerts and incidents
- **voice_commands**: Voice interaction logs
- **app_settings**: User preferences

### Key Features
- Automatic timestamp updates
- Fraud pattern detection functions
- Transaction history views
- Real-time subscriptions

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK (3.0+)
- Python 3.8+
- Supabase account
- Android Studio / Xcode

### 1. Flutter App Setup

```bash
# Clone the repository
git clone <repository-url>
cd surakshapay

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
```

### 2. Database Setup

```bash
# Connect to your Supabase project
# Run the SQL schema from database_schema.sql
# This will create all necessary tables and functions
```

### 3. Python Microservices

```bash
# Install Python dependencies
pip install -r requirements.txt

# Start Fraud Detection Service
python fraud_detection_service.py

# Start Streamlit Dashboard (in another terminal)
streamlit run streamlit_dashboard.py
```

### 4. Environment Configuration

Update the Supabase configuration in `lib/config/supabase_config.dart`:
```dart
static const String url = 'YOUR_SUPABASE_URL';
static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
```

## 🎯 Voice Commands

### Supported Commands (Hindi/English)
- **Send Money**: "Ramesh ko 500 bhej do" / "Send 500 to Ramesh"
- **Receive Money**: "Mera QR code dikhado" / "Show my QR code"
- **Check Balance**: "Balance dikhao" / "Show balance"
- **Transaction History**: "History dikhao" / "Show history"
- **Help**: "Madad chahiye" / "I need help"

### Language Support
- Hindi (hi-IN) - Primary
- English (en-US)
- Bengali (bn-IN)
- Tamil (ta-IN)
- Telugu (te-IN)

## 🛡️ Security Features

### Fraud Detection
- **Gambling Keywords**: Multi-language detection
- **Transaction Patterns**: Rapid successive transactions
- **Amount Analysis**: Suspicious amount patterns
- **Voice Analysis**: Command pattern recognition
- **Time-based**: Unusual hour transactions

### Duress PIN System
- **Normal PIN**: Regular app access
- **Duress PIN**: Fake success + Silent alert
- **Trusted Contact**: Automatic emergency notification
- **Police Alert**: Critical situation handling

## 📊 Monitoring Dashboard

### Real-time Metrics
- Total users and balances
- Transaction volume and types
- Fraud alerts and severity
- Voice command analytics

### Visualizations
- Transaction trends over time
- Fraud type distribution
- User balance distribution
- Language usage patterns

## 🔧 Development

### Project Structure
```
lib/
├── config/          # App configuration
├── models/          # Data models
├── services/        # Business logic
├── providers/       # State management
├── screens/         # UI screens
├── widgets/         # Reusable components
└── main.dart        # App entry point

python/
├── fraud_detection_service.py  # Fraud detection API
└── streamlit_dashboard.py      # Monitoring dashboard
```

### Key Components
- **VoiceService**: Speech recognition and TTS
- **FraudDetectionService**: Real-time fraud analysis
- **SupabaseService**: Database operations
- **NavigationProvider**: App state management

## 🧪 Testing

### Voice Commands Testing
1. Test voice recognition accuracy
2. Verify multi-language support
3. Check fraud detection responses
4. Validate duress PIN behavior

### Transaction Testing
1. Test send/receive money flows
2. Verify QR code generation
3. Check balance updates
4. Test fraud detection triggers

### Security Testing
1. Test duress PIN scenarios
2. Verify fraud alert generation
3. Check trusted contact notifications
4. Test voice pattern analysis

## 📱 Demo Flow

### Complete Demo Scenario
1. **User Registration**: Create account with voice
2. **Voice Login**: "Login karo" + speak phone number
3. **Send Money**: "Ramesh ko 500 bhej do"
4. **Fraud Detection**: Test with gambling keywords
5. **Duress PIN**: Enter emergency PIN
6. **Dashboard**: Monitor all activity in real-time

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- Google Speech API for voice recognition
- Streamlit for the monitoring dashboard

## 📞 Support

For support and questions:
- Email: keerat.jeet@bcah.christuniversity.in
- Phone: 7800153125
---

**SurakshaPay** - Making secure payments accessible to everyone through voice commands and AI-powered fraud detection. 🛡️💬

