# 💰 Financial Advisor Platform

An intelligent financial advisor platform that provides personalized financial recommendations using artificial intelligence and machine learning algorithms. The system analyzes user financial data to offer insights on investments, savings, and financial planning across multiple platforms.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-1.0.0-green.svg)
![Platform](https://img.shields.io/badge/platform-Web%20%7C%20Mobile%20%7C%20API-brightgreen.svg)

## 🚀 Features

- **Intelligent Expense Analysis**: Advanced ML algorithms for spending pattern recognition
- **Predictive Financial Insights**: Future spending predictions and recommendations
- **Multi-Platform Support**: Web (Angular), Mobile (Flutter), API (Flask), and Backend (Laravel)
- **Spending Categorization**: Automatic transaction categorization with machine learning
- **Budget Management**: Smart budget limits and spending alerts
- **Data Visualization**: Interactive charts and reports for financial tracking
- **Association Rules Mining**: Discover spending patterns and correlations
- **Clustering Analysis**: Group similar spending behaviors

## 🏗️ Architecture

This project follows a multi-platform architecture with the following components:

```
📦 Financial Advisor Platform
├── 🌐 Angular Frontend (Web Application)
├── 📱 Flutter App (Mobile Application)
├── 🔧 Flask API (ML & Analytics Backend)
└── 🗄️ Laravel Backend (Main API & Database)
```

## 🛠️ Technology Stack

### Frontend
- **Angular 18**: Modern web application with TypeScript
- **Flutter**: Cross-platform mobile application
- **Angular Material**: UI component library
- **Chart.js**: Data visualization

### Backend
- **Flask**: Python API for machine learning models
- **Laravel**: PHP framework for main backend services
- **Python**: ML algorithms and data analysis
- **PHP**: Business logic and API endpoints

### Machine Learning
- **Pandas**: Data manipulation and analysis
- **Scikit-learn**: Machine learning algorithms
- **Linear Regression**: Spending prediction models
- **K-Means Clustering**: User behavior segmentation
- **Association Rules**: Pattern mining

### Database & Storage
- **MySQL/PostgreSQL**: Primary database
- **Redis**: Caching (optional)

## 📋 Prerequisites

Before running this project, make sure you have the following installed:

- **Node.js** (v16 or higher)
- **Angular CLI** (v18 or higher)
- **Flutter SDK** (v3.0 or higher)
- **Python** (v3.8 or higher)
- **PHP** (v8.1 or higher)
- **Composer** (PHP package manager)
- **Git**

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/Financial-Advisor.git
cd Financial-Advisor
```

### 2. Setup Flask API (ML Backend)
```bash
cd Flask
pip install -r requirements.txt
python app.py
```
The Flask API will run on `http://localhost:5000`

### 3. Setup Laravel Backend
```bash
cd Laravel
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```
The Laravel API will run on `http://localhost:8000`

### 4. Setup Angular Frontend
```bash
cd Angular
npm install
ng serve
```
The web application will run on `http://localhost:4200`

### 5. Setup Flutter Mobile App
```bash
cd Flutter
flutter pub get
flutter run
```

## 📱 Platform-Specific Setup

### Angular Web Application
```bash
cd Angular
npm install
ng serve --open
```

**Available Scripts:**
- `npm start` - Start development server
- `npm run build` - Build for production
- `npm test` - Run unit tests
- `npm run test:coverage` - Run tests with coverage

### Flutter Mobile Application
```bash
cd Flutter
flutter pub get
flutter run
```

**Available Commands:**
- `flutter run` - Run on connected device
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter test` - Run unit tests

### Flask ML API
```bash
cd Flask
pip install flask pandas scikit-learn python-dotenv
python app.py
```

**API Endpoints:**
- `POST /analysis` - Analyze expenses and get insights

### Laravel Backend
```bash
cd Laravel
composer install
php artisan serve
```

## 🔧 Configuration

### Environment Variables

Create `.env` files in each directory:

**Flask/.env:**
```env
FLASK_PASSWORD=your_secure_password
DEBUG=True
```

**Laravel/.env:**
```env
APP_NAME="Financial Advisor"
APP_ENV=local
APP_KEY=base64:...
APP_DEBUG=true
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=financial_advisor
DB_USERNAME=root
DB_PASSWORD=
```

## 📊 API Documentation

### Flask ML API

#### POST /analysis
Analyzes financial data and returns insights.

**Request:**
```json
{
  "password": "your_password",
  "transactions": [
    {
      "amount": 50.00,
      "category": "Food",
      "date": "2024-01-15",
      "description": "Restaurant"
    }
  ]
}
```

**Response:**
```json
{
  "insights": {...},
  "predictions": {...},
  "recommendations": [...]
}
```

## 🧪 Testing

### Run All Tests
```bash
# Angular tests
cd Angular && npm test

# Flutter tests
cd Flutter && flutter test

# Flask tests
cd Flask && python -m pytest

# Laravel tests
cd Laravel && php artisan test
```

### Coverage Reports
- Angular: `npm run test:coverage`
- Flutter: `flutter test --coverage`

## 📝 Project Structure

```
Financial-Advisor/
├── Angular/                 # Web frontend
│   ├── src/
│   │   ├── app/            # Angular components
│   │   └── assets/         # Static assets
│   ├── package.json
│   └── angular.json
├── Flutter/                # Mobile application
│   ├── lib/
│   │   ├── screens/        # App screens
│   │   └── services/       # API services
│   ├── assets/
│   └── pubspec.yaml
├── Flask/                  # ML API backend
│   ├── app.py             # Main Flask application
│   ├── ml_models.py       # ML algorithms
│   └── business_logic.py  # Business rules
├── Laravel/               # Main backend API
│   ├── app/
│   ├── database/
│   ├── routes/
│   └── composer.json
└── README.md
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines
- Follow the existing code style
- Write tests for new features
- Update documentation as needed
- Use meaningful commit messages

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Your Name** - *Initial work* - [YourGitHub](https://github.com/yourusername)

## 🙏 Acknowledgments

- Angular team for the amazing framework
- Flutter team for cross-platform development
- Flask and Laravel communities
- Scikit-learn for machine learning capabilities

## 📞 Support

If you have any questions or need help, please:

1. Check the [Issues](https://github.com/yourusername/Financial-Advisor/issues) page
2. Create a new issue if your problem isn't already listed
3. Contact the maintainers

## 🔄 Changelog

### Version 1.0.0 (Current)
- Initial release
- Multi-platform architecture
- ML-powered expense analysis
- Budget management features

---

**Made with ❤️ for better financial management**
