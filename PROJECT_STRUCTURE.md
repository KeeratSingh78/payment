# SurakshaPay Project Structure

## 📁 Complete Project Overview

```
surakshapay/
├── 📱 Flutter Mobile App
│   ├── lib/
│   │   ├── config/
│   │   │   ├── supabase_config.dart      # Supabase connection settings
│   │   │   └── app_config.dart           # App-wide configuration
│   │   ├── models/
│   │   │   ├── user_model.dart           # User and Contact data models
│   │   │   └── transaction_model.dart    # Transaction and Fraud models
│   │   ├── services/
│   │   │   ├── supabase_service.dart     # Database operations
│   │   │   ├── voice_service.dart        # Speech recognition & TTS
│   │   │   └── fraud_detection_service.dart # Fraud detection logic
│   │   ├── providers/
│   │   │   └── app_providers.dart        # State management (Riverpod)
│   │   ├── screens/
│   │   │   ├── splash_screen.dart        # App launch screen
│   │   │   ├── login_screen.dart         # User authentication
│   │   │   ├── registration_screen.dart  # New user registration
│   │   │   ├── home_dashboard.dart       # Main app interface
│   │   │   ├── send_money_screen.dart    # Send money flow
│   │   │   ├── receive_money_screen.dart # Receive money flow
│   │   │   ├── transaction_history_screen.dart # Transaction list
│   │   │   └── settings_screen.dart      # User preferences
│   │   ├── widgets/
│   │   │   ├── numeric_keypad.dart       # PIN entry keypad
│   │   │   ├── voice_button.dart         # Voice command button
│   │   │   └── transaction_card.dart     # Transaction display card
│   │   └── main.dart                     # App entry point
│   ├── pubspec.yaml                      # Flutter dependencies
│   └── assets/                           # Images, fonts, sounds
│
├── 🐍 Python Microservices
│   ├── fraud_detection_service.py        # Flask API for fraud detection
│   ├── streamlit_dashboard.py            # Real-time monitoring dashboard
│   └── requirements.txt                  # Python dependencies
│
├── 🗄️ Database
│   └── database_schema.sql               # PostgreSQL schema and functions
│
├── 📚 Documentation
│   ├── README.md                         # Main project documentation
│   ├── PROJECT_STRUCTURE.md             # This file
│   └── setup.py                         # Automated setup script
│
└── 🚀 Deployment
    ├── run_windows.bat                   # Windows startup script
    └── run_unix.sh                      # Unix/Linux startup script
```

## 🔧 Key Components Breakdown

### Flutter App Architecture

#### 1. **Configuration Layer** (`lib/config/`)
- **supabase_config.dart**: Database connection settings
- **app_config.dart**: App-wide constants and settings

#### 2. **Data Models** (`lib/models/`)
- **user_model.dart**: User profiles, contacts, authentication
- **transaction_model.dart**: Transactions, fraud logs, voice commands

#### 3. **Business Logic** (`lib/services/`)
- **supabase_service.dart**: All database operations
- **voice_service.dart**: Speech-to-text and text-to-speech
- **fraud_detection_service.dart**: Client-side fraud detection

#### 4. **State Management** (`lib/providers/`)
- **app_providers.dart**: Riverpod providers for state management
  - UserProvider: User authentication and profile
  - TransactionsProvider: Transaction management
  - ContactsProvider: Contact list management
  - FraudLogsProvider: Fraud alert management
  - AppSettingsProvider: User preferences

#### 5. **User Interface** (`lib/screens/`)
- **splash_screen.dart**: App launch with animations
- **login_screen.dart**: Phone + PIN authentication
- **registration_screen.dart**: Multi-step user registration
- **home_dashboard.dart**: Main app interface with voice assistant
- **send_money_screen.dart**: Send money with voice commands
- **receive_money_screen.dart**: QR code and UPI ID display
- **transaction_history_screen.dart**: Transaction list view
- **settings_screen.dart**: User preferences and security

#### 6. **Reusable Components** (`lib/widgets/`)
- **numeric_keypad.dart**: Custom PIN entry keypad
- **voice_button.dart**: Animated voice command button
- **transaction_card.dart**: Transaction display component

### Python Microservices

#### 1. **Fraud Detection Service** (`fraud_detection_service.py`)
- **Flask API** for real-time fraud detection
- **Multi-language keyword detection** (Hindi, English, Bengali, Tamil, Telugu)
- **Transaction pattern analysis**
- **Voice command processing**
- **RESTful endpoints**:
  - `POST /detect-fraud`: Main fraud detection
  - `POST /process-voice`: Voice command processing
  - `GET /health`: Service health check

#### 2. **Streamlit Dashboard** (`streamlit_dashboard.py`)
- **Real-time monitoring** of all app activity
- **Interactive visualizations** with Plotly
- **Multi-tab interface**:
  - Users: User management and balance distribution
  - Transactions: Transaction analysis and trends
  - Fraud Alerts: Security monitoring and alerts
  - Voice Commands: Voice interaction analytics

### Database Schema

#### 1. **Core Tables**
- **users**: User profiles, PINs, balances, UPI IDs
- **contacts**: User contact lists with frequent contacts
- **transactions**: Payment history with sender/receiver info
- **fraud_logs**: Security alerts and incident tracking
- **voice_commands**: Voice interaction logs and analysis
- **app_settings**: User preferences and configurations

#### 2. **Advanced Features**
- **Automatic timestamps** with triggers
- **Fraud detection functions** in PostgreSQL
- **Transaction history views** with user names
- **Real-time subscriptions** for live updates

## 🚀 Development Workflow

### 1. **Setup Process**
```bash
# Run automated setup
python setup.py

# Or manual setup
flutter pub get
pip install -r requirements.txt
```

### 2. **Database Setup**
1. Create Supabase project
2. Run `database_schema.sql` in SQL Editor
3. Update configuration in `lib/config/supabase_config.dart`

### 3. **Running the Application**
```bash
# Start all services
./run_unix.sh  # or run_windows.bat

# Or individually
python fraud_detection_service.py
streamlit run streamlit_dashboard.py
flutter run
```

### 4. **Development Features**
- **Hot reload** for Flutter development
- **Real-time updates** in Streamlit dashboard
- **API testing** with fraud detection service
- **Voice command testing** with multiple languages

## 🔒 Security Architecture

### 1. **Authentication Flow**
- Phone number + PIN authentication
- Duress PIN system for emergency situations
- Trusted contact notifications
- Session management with Supabase

### 2. **Fraud Detection Pipeline**
- **Client-side**: Basic validation and pattern checking
- **Server-side**: Advanced AI-powered analysis
- **Real-time**: Continuous monitoring and alerting
- **Multi-layer**: Voice, transaction, and behavioral analysis

### 3. **Data Protection**
- **Encrypted PINs** with secure hashing
- **Secure API communication** with HTTPS
- **Privacy-focused** voice command processing
- **Audit trails** for all transactions and security events

## 📊 Monitoring & Analytics

### 1. **Real-time Metrics**
- User activity and balances
- Transaction volume and patterns
- Fraud detection alerts
- Voice command usage

### 2. **Visualizations**
- Interactive charts with Plotly
- Real-time data updates
- Multi-dimensional analysis
- Export capabilities

### 3. **Alerting System**
- Critical fraud alerts
- System health monitoring
- Performance metrics
- User behavior analysis

## 🌐 Multi-language Support

### 1. **Supported Languages**
- **Hindi (hi-IN)**: Primary language
- **English (en-US)**: Secondary language
- **Bengali (bn-IN)**: Regional support
- **Tamil (ta-IN)**: Regional support
- **Telugu (te-IN)**: Regional support

### 2. **Voice Command Processing**
- **Speech-to-text** in multiple languages
- **Text-to-speech** with regional accents
- **NLP processing** for intent extraction
- **Context-aware** responses

### 3. **UI Localization**
- **Dynamic language switching**
- **Cultural adaptation** of interfaces
- **Voice-guided navigation**
- **Accessibility features**

## 🧪 Testing Strategy

### 1. **Unit Testing**
- Individual component testing
- Service layer validation
- Model testing
- Provider testing

### 2. **Integration Testing**
- API integration testing
- Database operation testing
- Voice service testing
- Fraud detection testing

### 3. **End-to-End Testing**
- Complete user flows
- Voice command scenarios
- Fraud detection scenarios
- Multi-language testing

## 📱 Platform Support

### 1. **Mobile Platforms**
- **Android**: Full feature support
- **iOS**: Full feature support
- **Responsive design** for different screen sizes

### 2. **Web Dashboard**
- **Streamlit** for monitoring
- **Real-time updates**
- **Cross-platform compatibility**

### 3. **API Services**
- **RESTful APIs** for fraud detection
- **WebSocket support** for real-time updates
- **Microservice architecture**

This comprehensive structure ensures a scalable, secure, and maintainable payment application with advanced voice capabilities and fraud detection features.

