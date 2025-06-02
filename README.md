# Financial Advisor (Intelligent Personal Finance Platform)

This is an intelligent financial advisor platform that provides personalized financial recommendations using artificial intelligence and machine learning algorithms. The system analyzes user financial data to offer insights on investments, savings, and financial planning across multiple platforms including web, mobile, and backend services.

## Features

### 🤖 AI-Powered Expense Analysis
- **Machine Learning Models**: Linear regression for expense prediction with 50-90% accuracy
- **Intelligent Clustering**: K-means clustering for spending pattern analysis
- **Smart Insights**: Automatic detection of spending trends, deviations, and variability
- **Association Rules**: Discovery of spending patterns between categories
- **Rule-Based Labeling**: Automatic categorization of expenses as Essential, Moderate, or Non-Essential

### 📊 Advanced Analytics & Predictions
- **Expense Forecasting**: Predict future spending using historical data analysis
- **Category-Specific Predictions**: Individual forecasting for each expense category
- **Spending Pattern Analysis**: Identify high, moderate, and low spending clusters
- **Frequency Analysis**: Track spending frequency patterns across categories
- **Day-of-Week Analysis**: Discover peak spending days and patterns

### 💼 Investment Management
- **Egyptian Bank Certificates**: Compare investment options from 7+ major Egyptian banks
- **Stock Market Integration**: Real-time Egyptian Exchange (EGX) stock data
- **Investment Calculator**: Calculate returns for certificates with various interest rates
- **Comparison Tools**: Side-by-side analysis of multiple investment options
- **AI Investment Advisor**: Personalized investment recommendations using OpenRouter API

### 🎯 Goal Setting & Budget Management
- **Smart Goal Tracking**: Set and monitor financial goals with progress visualization
- **Budget Allocation**: Intelligent budget distribution across expense categories
- **Limit Assignment**: Automatic spending limit recommendations based on priorities
- **Overspending Alerts**: Real-time notifications when approaching budget limits

### 🤖 AI Chatbot Integration
- **OpenRouter API**: Advanced AI-powered financial consultation via multiple LLM providers
- **Investment Analysis**: Detailed analysis of certificates and stocks
- **Personalized Advice**: Context-aware recommendations based on spending patterns
- **Egyptian Market Expertise**: Specialized knowledge of Egyptian financial markets

### 📱 Multi-Platform Support
- **Web Application**: Angular-based responsive web interface
- **Mobile App**: Flutter cross-platform mobile application
- **Backend API**: Laravel RESTful API with MySQL integration
- **ML Engine**: Python Flask service for machine learning operations

## Installation

### Prerequisites
- **Backend**: PHP 8.2+, Laravel 11+, MySQL, Python 3.12+
- **Frontend**: Node.js 18+, Angular 18+
- **Mobile**: Flutter 3.7+, Dart SDK
- **AI Services**: OpenRouter API access

### Setup Instructions

#### 1. Clone the Repository
```bash
git clone https://github.com/Mohamed-Samehh/Financial-Advisor
cd Financial-Advisor
```

#### 2. Laravel Backend Setup
```bash
cd Laravel
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

#### 3. Flask ML Service Setup
```bash
cd Flask
cp .env.example .env
python app.py
```

#### 4. Angular Frontend Setup
```bash
cd Angular
npm install
ng serve
```

#### 5. Flutter Mobile App Setup
```bash
cd Flutter
flutter pub get
flutter run
```

#### 6. Environment Configuration
Update the `.env` files in each directory with:
- Database credentials (MySQL)
- Flask service password (for connecting Flask with Laravel)
- OpenRouter API key (for AI model access)
- EODHD API key (for stocks data)
- Brevo SMTP data (for mails)

## Usage

### Getting Started
1. **Register/Login**: Create your account through web or mobile interface
2. **Add Expenses**: Record your daily expenses with categories and amounts
3. **Set Goals**: Define your financial goals (savings, investments, etc.)
4. **Configure Budget**: Set monthly budget limits for different categories

### AI Analysis Features
- **Expense Analysis**: Upload expense data to get AI-powered insights
- **Investment Exploration**: Browse Egyptian bank certificates and EGX stocks
- **Chatbot Consultation**: Get personalized financial advice through AI chat
- **Pattern Discovery**: Let the system identify your spending patterns automatically

### Investment Tools
- **Certificate Comparison**: Compare rates from NBE, CIB, QNB, Banque Misr, and more
- **Stock Analysis**: Research Egyptian stocks with historical data
- **Return Calculator**: Calculate potential returns for different investment scenarios
- **AI Recommendations**: Get investment advice tailored to your financial profile

## Development

### Project Structure
```
Financial-Advisor/
├── Laravel/          # Backend API (PHP/Laravel)
│   ├── app/
│   ├── database/
│   └── routes/
├── Angular/          # Web Frontend (TypeScript/Angular)
│   ├── src/app/
│   └── public/
├── Flutter/          # Mobile App (Dart/Flutter)
│   ├── lib/
│   └── assets/
└── Flask/            # ML Engine (Python/Flask)
    ├── ml_models.py
    ├── business_logic.py
    └── app.py
```

### Key Technologies

#### Backend Stack
- **Laravel 11**: PHP framework for API development
- **MySQL**: Relational database for data storage
- **Laravel Sanctum**: API authentication
- **Laravel Telescope**: Development debugging

#### ML & AI Stack
- **Python Flask**: Microservice for ML operations
- **Scikit-learn**: Machine learning algorithms (Linear Regression, K-Means)
- **Pandas & NumPy**: Data processing and analysis
- **MLxtend**: Association rules mining
- **OpenRouter API**: Multi-provider LLM access for advanced AI consultation

#### Frontend Stack
- **Angular 18**: Modern web framework with TypeScript
- **Chart.js**: Interactive data visualization
- **Bootstrap 5**: Responsive UI framework
- **FontAwesome**: Icon library

#### Mobile Stack
- **Flutter 3.7**: Cross-platform mobile development
- **FL Chart**: Mobile data visualization
- **Provider**: State management
- **HTTP**: API communication

#### External Integrations
- **Egyptian Exchange (EGX)**: Real-time stock data
- **Major Egyptian Banks**: Certificate data from NBE, CIB, QNB, etc.
- **OpenRouter API**: Access to multiple AI models for advanced financial consultation

### Testing
The project includes comprehensive testing:
- **Unit Tests**: Flask ML models with expense analysis testing
- **Laravel Tests**: Both Unit and Feature tests for API endpoints, controllers, and models
- **Angular Tests**: Jest-based component testing with coverage reporting

