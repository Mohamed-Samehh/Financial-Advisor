# 💰 Financial Advisor Platform - Student Portfolio Project

A comprehensive financial analysis platform demonstrating **full-stack development skills** with **machine learning integration**. This project showcases proficiency in multiple technologies and modern software architecture patterns.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Angular](https://img.shields.io/badge/Angular-18-red.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Python](https://img.shields.io/badge/Python-3.8+-green.svg)
![Laravel](https://img.shields.io/badge/Laravel-PHP-orange.svg)

## 🎯 Project Overview

This platform demonstrates advanced programming concepts including:
- **Machine Learning**: Predictive modeling for financial insights
- **Multi-platform Development**: Web, mobile, and API services
- **Microservices Architecture**: Separated concerns with Flask ML API and Laravel backend
- **Modern Frontend**: Angular 18 with TypeScript and Flutter for mobile

## 🏗️ System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Angular Web   │    │  Flutter Mobile │    │  Laravel API    │
│   Frontend      │    │  Application    │    │  (Main Backend) │
│   (Port 4200)   │    │                 │    │  (Port 8000)    │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────┴───────┐
                    │   Flask ML API      │
                    │ (Python/Scikit)     │
                    │   (Port 5000)       │
                    └─────────────────────┘
```

## 🧠 Machine Learning Implementation

### Core ML Algorithms Implemented

#### 1. **Linear Regression for Spending Prediction**
```python
def linear_regression(distinct_all_expenses, predictions, month_num=12):
    # Feature engineering: Extract temporal features
    distinct_all_expenses['month'] = distinct_all_expenses['date'].dt.month
    distinct_all_expenses['year'] = distinct_all_expenses['date'].dt.year
    
    # Aggregate monthly spending patterns
    monthly_spending = distinct_all_expenses.groupby(['year', 'month'])['amount'].sum()
    
    # Scale features for better convergence
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    # Train linear regression model
    model = LinearRegression()
    model.fit(X_scaled, y)
```

#### 2. **K-Means Clustering for User Segmentation**
```python
def kmeans_clustering(df, n_clusters=3):
    # Feature selection for clustering
    features = ['total_amount', 'transaction_count', 'avg_transaction']
    
    # Standardize features
    scaler = StandardScaler()
    scaled_features = scaler.fit_transform(df[features])
    
    # Apply K-Means clustering
    kmeans = KMeans(n_clusters=n_clusters, random_state=42)
    clusters = kmeans.fit_predict(scaled_features)
```

#### 3. **Association Rules Mining**
```python
def get_association_rules(df, min_support=0.1):
    # Market basket analysis for spending patterns
    basket = df.groupby(['user_id', 'category'])['amount'].sum().unstack()
    basket_sets = basket.notnull().astype('int')
    
    # Generate frequent itemsets
    frequent_itemsets = apriori(basket_sets, min_support=min_support)
    return frequent_itemsets
```

## 💻 Frontend Development

### Angular Architecture (TypeScript)

#### Component-Based Design
```typescript
@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule, ChartModule],
  templateUrl: './dashboard.component.html'
})
export class DashboardComponent implements OnInit {
  // Reactive programming with RxJS
  expenses$ = this.apiService.getExpenses().pipe(
    map(data => this.processExpenseData(data)),
    catchError(error => this.handleError(error))
  );

  // Dependency injection
  constructor(
    private apiService: ApiService,
    private router: Router
  ) {}
}
```

#### State Management & Services
```typescript
@Injectable({ providedIn: 'root' })
export class ApiService {
  private baseUrl = 'http://localhost:8000/api';

  // HTTP interceptors for authentication
  getExpenses(): Observable<Expense[]> {
    return this.http.get<Expense[]>(`${this.baseUrl}/expenses`)
      .pipe(retry(3), catchError(this.handleError));
  }
}
```

### Flutter Mobile Development (Dart)

#### Provider Pattern Implementation
```dart
class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String email, String password) async {
    // Authentication logic with state management
    try {
      final response = await ApiService.login(email, password);
      _token = response['token'];
      _isAuthenticated = true;
      notifyListeners(); // Notify UI of state changes
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

#### Responsive UI Design
```dart
class ResponsiveDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return DesktopDashboard(); // Wide screen layout
        } else {
          return MobileDashboard();  // Mobile layout
        }
      },
    );
  }
}
```

## 🔧 Backend Development

### Laravel API (PHP)

#### RESTful API Design
```php
// Route definition with middleware
Route::middleware('auth:api')->group(function () {
    Route::get('/expenses', [ExpenseController::class, 'index']);
    Route::post('/expenses', [ExpenseController::class, 'store']);
    Route::post('/analyze', [AnalysisController::class, 'analyze']);
});

// Controller with dependency injection
class ExpenseController extends Controller {
    public function __construct(
        private ExpenseService $expenseService,
        private ValidationService $validator
    ) {}

    public function index(Request $request): JsonResponse {
        $expenses = $this->expenseService->getUserExpenses(
            $request->user()->id,
            $request->query('filters', [])
        );
        
        return response()->json([
            'data' => ExpenseResource::collection($expenses),
            'meta' => $this->getPaginationMeta($expenses)
        ]);
    }
}
```

#### Database Design with Eloquent ORM
```php
// Model with relationships
class Expense extends Model {
    protected $fillable = ['amount', 'category', 'description', 'date'];
    
    protected $casts = [
        'date' => 'datetime',
        'amount' => 'decimal:2'
    ];

    // Relationship definitions
    public function user(): BelongsTo {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo {
        return $this->belongsTo(Category::class);
    }

    // Query scopes for reusable logic
    public function scopeByDateRange($query, $start, $end) {
        return $query->whereBetween('date', [$start, $end]);
    }
}
```

### Flask ML API (Python)

#### API Integration with Laravel Backend
```python
@app.route('/analysis', methods=['POST'])
def analyze_expenses():
    data = request.json
    
    # Data validation and security
    if data.get('password') != FLASK_PASSWORD:
        return jsonify({'error': 'Unauthorized'}), 401
    
    # Convert to DataFrame for ML processing
    df = pd.DataFrame(data['expenses'])
    df['date'] = pd.to_datetime(df['date'])
    
    # Run multiple ML algorithms
    results = {
        'linear_predictions': linear_regression(df, month_num=6),
        'user_clusters': kmeans_clustering(df),
        'spending_patterns': get_association_rules(df),
        'insights': generate_insights(df)
    }
    
    return jsonify(results)
```

## 📊 Key Technical Features Implemented

### 1. **Authentication & Security**
- JWT token-based authentication
- Password hashing with bcrypt
- API rate limiting
- CORS configuration

### 2. **Data Processing Pipeline**
```python
def process_financial_data(raw_data):
    # Data cleaning and validation
    cleaned_data = validate_and_clean(raw_data)
    
    # Feature engineering
    features = extract_features(cleaned_data)
    
    # ML model application
    predictions = apply_ml_models(features)
    
    # Business logic application
    insights = apply_business_rules(predictions)
    
    return insights
```

### 3. **Real-time Data Visualization**
- Chart.js integration for interactive charts
- Real-time data updates with WebSockets
- Responsive design for multiple screen sizes

### 4. **Testing Implementation**
```typescript
// Angular unit testing with Jest
describe('ExpenseService', () => {
  let service: ExpenseService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [ExpenseService]
    });
  });

  it('should fetch expenses', () => {
    const mockExpenses = [{ id: 1, amount: 100 }];
    
    service.getExpenses().subscribe(expenses => {
      expect(expenses).toEqual(mockExpenses);
    });
  });
});
```

## 🚀 Setup & Running the Project

### Prerequisites
```bash
# Required tools
Node.js (v16+)
Python (v3.8+)
PHP (v8.1+)
Flutter SDK (v3.0+)
```

### Quick Start
```bash
# 1. Clone repository
git clone https://github.com/yourusername/Financial-Advisor.git
cd Financial-Advisor

# 2. Backend APIs
cd Laravel && composer install && php artisan serve &
cd ../Flask && pip install -r requirements.txt && python app.py &

# 3. Frontend applications
cd ../Angular && npm install && ng serve &
cd ../Flutter && flutter pub get && flutter run
```

## 📈 Technical Achievements

- **Full-Stack Integration**: Seamless communication between 4 different technologies
- **Machine Learning Pipeline**: From data preprocessing to model deployment
- **Responsive Design**: Mobile-first approach with Flutter and Angular
- **API Design**: RESTful services with proper HTTP status codes and error handling
- **Code Quality**: TypeScript for type safety, PHP 8 features, Python type hints
- **Testing**: Unit tests across all platforms
- **Performance**: Optimized queries, lazy loading, and efficient algorithms

## 🎓 Learning Outcomes

This project demonstrates proficiency in:
- **Object-Oriented Programming** (PHP, TypeScript, Dart)
- **Functional Programming** concepts (Python, JavaScript)
- **Design Patterns** (MVC, Provider, Repository, Factory)
- **Database Design** (Normalization, relationships, indexing)
- **API Development** (RESTful design, authentication, validation)
- **Machine Learning** (Supervised/unsupervised learning, data preprocessing)
- **Mobile Development** (Flutter, responsive design, state management)
- **Web Development** (Angular, TypeScript, modern JavaScript)

---

**Built with ❤️ to demonstrate full-stack development skills**

### Version 1.0.0 (Current)
- Initial release
- Multi-platform architecture
- ML-powered expense analysis
- Budget management features

---

**Made with ❤️ for better financial management**
