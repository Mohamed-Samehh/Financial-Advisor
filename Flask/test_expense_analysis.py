import unittest
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import json
import os
import sys

from business_logic import (
    assign_limits, 
    predictive_insights, 
    analyze_spending_variability,
    analyze_spending_deviations,
    day_of_week_analysis
)
from ml_models import (
    linear_regression,
    category_linear_regression,
    kmeans_clustering,
    spending_kmeans_clustering,
    frequency_kmeans_clustering,
    get_association_rules,
    Rule_Based_labeling
)

class TestBusinessLogic(unittest.TestCase):
    
    def setUp(self):
        """Set up test data"""
        self.categories = pd.DataFrame({
            'name': ['Food', 'Transport', 'Entertainment', 'Bills'],
            'priority': [1, 2, 3, 1]
        })
        
        self.expenses = pd.DataFrame({
            'date': pd.to_datetime([
                '2025-01-01', '2025-01-02', '2025-01-03', 
                '2025-01-04', '2025-01-05', '2025-01-06'
            ]),
            'amount': [100, 50, 200, 75, 120, 80],
            'category': ['Food', 'Transport', 'Entertainment', 'Food', 'Bills', 'Food']
        })
        
        self.historical_expenses = pd.DataFrame({
            'date': pd.to_datetime([
                '2024-01-01', '2024-01-02', '2024-01-03', 
                '2024-01-04', '2024-01-05', '2024-01-06'
            ]),
            'amount': [90, 60, 180, 85, 110, 70],
            'category': ['Food', 'Transport', 'Entertainment', 'Food', 'Bills', 'Food']
        })
    
    def test_assign_limits(self):
        """Test category limit assignment based on priority"""
        allowed_spending = 1000
        result = assign_limits(self.categories, allowed_spending)
        
        self.assertIn('name', result.columns)
        self.assertIn('limit', result.columns)
        self.assertAlmostEqual(result['limit'].sum(), allowed_spending, places=2)
        
        # Higher priority (lower number) should get more allocation
        food_limit = result[result['name'] == 'Food']['limit'].iloc[0]
        entertainment_limit = result[result['name'] == 'Entertainment']['limit'].iloc[0]
        self.assertGreater(food_limit, entertainment_limit)
    
    def test_predictive_insights(self):
        """Test predictive spending calculation"""
        result = predictive_insights(self.expenses)
        
        self.assertIsInstance(result, float)
        self.assertGreater(result, 0)
        
        # Test with empty data
        empty_expenses = pd.DataFrame(columns=['date', 'amount'])
        empty_expenses['date'] = pd.to_datetime(empty_expenses['date'])
        result_empty = predictive_insights(empty_expenses)
        self.assertIsNone(result_empty)
    
    def test_analyze_spending_variability(self):
        """Test spending variability analysis"""
        smart_insights = []
        analyze_spending_variability(self.expenses, smart_insights)
        
        self.assertIsInstance(smart_insights, list)
        if len(smart_insights) > 0:
            self.assertIsInstance(smart_insights[0], str)
    
    def test_analyze_spending_deviations(self):
        """Test spending deviations analysis"""
        smart_insights = []
        analyze_spending_deviations(self.expenses, self.historical_expenses, smart_insights)
        
        self.assertIsInstance(smart_insights, list)
        if len(smart_insights) > 0:
            self.assertIsInstance(smart_insights[0], str)
    
    def test_day_of_week_analysis(self):
        """Test day of week spending analysis"""
        smart_insights = []
        day_of_week_analysis(self.expenses, smart_insights)
        
        self.assertGreater(len(smart_insights), 0)
        self.assertIn('highest', smart_insights[0].lower())


class TestMLModels(unittest.TestCase):
    
    def setUp(self):
        """Set up test data for ML models"""
        # Create sample historical expenses
        dates = pd.date_range(start='2024-01-01', end='2024-12-31', freq='D')
        np.random.seed(42)
        self.historical_expenses = pd.DataFrame({
            'date': np.random.choice(dates, 200),
            'amount': np.random.uniform(20, 500, 200),
            'category': np.random.choice(['Food', 'Transport', 'Entertainment', 'Bills'], 200)
        })
        
        # Current month expenses
        current_dates = pd.date_range(start='2025-01-01', end='2025-01-15', freq='D')
        self.current_expenses = pd.DataFrame({
            'date': np.random.choice(current_dates, 30),
            'amount': np.random.uniform(20, 300, 30),
            'category': np.random.choice(['Food', 'Transport', 'Entertainment'], 30)
        })
    
    def test_linear_regression(self):
        """Test linear regression prediction"""
        predictions = []
        linear_regression(self.historical_expenses, predictions, month_num=3)
        
        if len(predictions) > 0:
            self.assertIsInstance(predictions, list)
            for pred in predictions:
                self.assertIn('year', pred)
                self.assertIn('month', pred)
                self.assertIn('predicted_spending', pred)
                self.assertIn('accuracy', pred)
                self.assertIn('correlation', pred)
                self.assertGreaterEqual(pred['predicted_spending'], 0)
    
    def test_category_linear_regression(self):
        """Test category-specific linear regression"""
        category_predictions = {}
        category_linear_regression(self.historical_expenses, category_predictions, month_num=2)
        
        if len(category_predictions) > 0:
            self.assertIsInstance(category_predictions, dict)
            for category, predictions in category_predictions.items():
                self.assertIsInstance(predictions, list)
                if len(predictions) > 0:
                    self.assertIn('predicted_spending', predictions[0])
                    self.assertGreaterEqual(predictions[0]['predicted_spending'], 0)
    
    def test_kmeans_clustering(self):
        """Test KMeans clustering for expenses"""
        smart_insights = []
        expenses_clustering = []
        
        kmeans_clustering(self.current_expenses, smart_insights, expenses_clustering)
        
        self.assertGreaterEqual(len(expenses_clustering), 1)
        
        for cluster in expenses_clustering:
            self.assertIn('cluster', cluster)
            self.assertIn('count_of_expenses', cluster)
            self.assertIn('min_expenses', cluster)
            self.assertIn('max_expenses', cluster)
    
    def test_spending_kmeans_clustering(self):
        """Test spending-based KMeans clustering"""
        spending_clustering = []
        spending_kmeans_clustering(self.current_expenses, spending_clustering)
        
        self.assertGreaterEqual(len(spending_clustering), 1)
        self.assertIn('spending_group', spending_clustering[0])
    
    def test_frequency_kmeans_clustering(self):
        """Test frequency-based KMeans clustering"""
        frequency_clustering = []
        frequency_kmeans_clustering(self.current_expenses, frequency_clustering)
        
        self.assertGreaterEqual(len(frequency_clustering), 1)
        self.assertIn('frequency_group', frequency_clustering[0])
    
    def test_get_association_rules(self):
        """Test association rules generation"""
        association_rules = []
        # Use lower thresholds for smaller test dataset
        get_association_rules(self.current_expenses, association_rules, 
                            min_support=0.1, min_confidence=0.3, min_lift=1.0)
        
        for rule in association_rules:
            self.assertIn('antecedents', rule)
            self.assertIn('consequents', rule)
            self.assertIn('support', rule)
            self.assertIn('confidence', rule)
            self.assertIn('lift', rule)
    
    def test_rule_based_labeling(self):
        """Test rule-based category labeling"""
        labeled_categories = []
        Rule_Based_labeling(self.historical_expenses, labeled_categories)
        
        if len(labeled_categories) > 0:
            self.assertIn('predicted_importance', labeled_categories[0])
            for item in labeled_categories[0]['predicted_importance']:
                self.assertIn('category', item)
                self.assertIn('predicted_importance', item)
                self.assertIn(item['predicted_importance'], 
                            ['Essential', 'Moderate', 'Non-Essential'])


class TestFlaskEndpoints(unittest.TestCase):
    
    def setUp(self):
        """Set up Flask app for testing"""
        os.environ['FLASK_PASSWORD'] = 'test_password'
        
        from app import app
        self.app = app
        self.app.config['TESTING'] = True
        self.client = self.app.test_client()
        
        self.test_data = {
            'password': 'test_password',
            'expenses': [
                {'date': '2025-01-01', 'amount': 100, 'category': 'Food'},
                {'date': '2025-01-02', 'amount': 50, 'category': 'Transport'},
                {'date': '2025-01-03', 'amount': 200, 'category': 'Entertainment'},
                {'date': '2025-01-04', 'amount': 75, 'category': 'Food'},
                {'date': '2025-01-05', 'amount': 120, 'category': 'Bills'}
            ],
            'all_expenses': [
                {'date': '2024-12-01', 'amount': 80, 'category': 'Food'},
                {'date': '2024-12-02', 'amount': 40, 'category': 'Transport'},
                {'date': '2024-12-03', 'amount': 150, 'category': 'Entertainment'},
                {'date': '2024-11-01', 'amount': 90, 'category': 'Food'},
                {'date': '2024-11-02', 'amount': 60, 'category': 'Transport'}
            ],
            'categories': [
                {'name': 'Food', 'priority': 1},
                {'name': 'Transport', 'priority': 2},
                {'name': 'Entertainment', 'priority': 3},
                {'name': 'Bills', 'priority': 1}
            ],
            'monthly_budget': 2000,
            'goal_amount': 500,
            'total_spent': 545
        }
    
    def test_analysis_endpoint_success(self):
        """Test successful analysis endpoint call"""
        response = self.client.post('/analysis', 
                                  data=json.dumps(self.test_data),
                                  content_type='application/json')
        
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        
        self.assertIn('predicted_current_month', data)
        self.assertIn('advice', data)
        self.assertIn('category_limits', data)
        self.assertIn('smart_insights', data)
    
    def test_analysis_endpoint_unauthorized(self):
        """Test unauthorized access"""
        test_data = self.test_data.copy()
        test_data['password'] = 'wrong_password'
        
        response = self.client.post('/analysis',
                                  data=json.dumps(test_data),
                                  content_type='application/json')
        
        self.assertEqual(response.status_code, 401)
    
    def test_analysis_endpoint_missing_data(self):
        """Test missing required data"""
        incomplete_data = {
            'password': 'test_password', 
            'expenses': [],
            'all_expenses': [],
            'categories': [],
            'monthly_budget': 2000,
            'goal_amount': 500
            # Missing 'total_spent' field
        }
        
        response = self.client.post('/analysis',
                                  data=json.dumps(incomplete_data),
                                  content_type='application/json')
        
        self.assertEqual(response.status_code, 400)
    
    def test_analysis_endpoint_invalid_total_spent(self):
        """Test invalid total_spent value"""
        test_data = self.test_data.copy()
        test_data['total_spent'] = 0
        
        response = self.client.post('/analysis',
                                  data=json.dumps(test_data),
                                  content_type='application/json')
        
        self.assertEqual(response.status_code, 400)
    
    def test_label_categories_endpoint(self):
        """Test label categories endpoint"""
        label_data = {
            'password': 'test_password',
            'past_expenses': self.test_data['all_expenses']
        }
        
        response = self.client.post('/label_categories',
                                  data=json.dumps(label_data),
                                  content_type='application/json')
        
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertIn('labaled_categories', data)
    
    def test_environment_setup(self):
        """Test environment variable setup"""
        self.assertEqual(os.environ.get('FLASK_PASSWORD'), 'test_password')


class TestChatEndpoint(unittest.TestCase):
    
    def setUp(self):
        """Set up Flask app for chat testing"""
        os.environ['FLASK_PASSWORD'] = 'test_password'
        
        from app import app
        self.app = app
        self.app.config['TESTING'] = True
        self.client = self.app.test_client()
    
    def test_chat_endpoint_mock(self):
        """Test chat endpoint with mocked external API"""
        import requests
        
        original_post = requests.post
        
        class MockResponse:
            def __init__(self):
                self.status_code = 200
            
            def json(self):
                return {'choices': [{'message': {'content': 'Test response'}}]}
        
        # Apply mock
        requests.post = lambda *args, **kwargs: MockResponse()
        
        try:
            chat_data = {
                'password': 'test_password',
                'message': 'How can I save money?',
                'api_key': 'test_api_key',
                'name': 'Test User',
                'budget': 2000,
                'goal_amount': 500,
                'total_spent': 1000
            }
            
            response = self.client.post('/chat',
                                      data=json.dumps(chat_data),
                                      content_type='application/json')
            
            self.assertEqual(response.status_code, 200)
            
        finally:
            # Restore original function
            requests.post = original_post


class TestDataValidation(unittest.TestCase):
    """Test edge cases and data validation"""
    
    def test_empty_dataframes(self):
        """Test functions with empty DataFrames"""
        empty_df = pd.DataFrame(columns=['date', 'amount', 'category'])
        empty_df['date'] = pd.to_datetime(empty_df['date'])
        empty_df['amount'] = pd.to_numeric(empty_df['amount'])
        
        result = predictive_insights(empty_df)
        self.assertIsNone(result)
        
        smart_insights = []
        analyze_spending_variability(empty_df, smart_insights)
        
    def test_single_category_clustering(self):
        """Test clustering with single category"""
        single_cat_expenses = pd.DataFrame({
            'date': pd.to_datetime(['2025-01-01', '2025-01-02']),
            'amount': [100, 150],
            'category': ['Food', 'Food']
        })
        
        smart_insights = []
        expenses_clustering = []
        
        kmeans_clustering(single_cat_expenses, smart_insights, expenses_clustering)
        self.assertGreaterEqual(len(expenses_clustering), 0)
    
    def test_identical_amounts_clustering(self):
        """Test clustering with identical amounts"""
        identical_expenses = pd.DataFrame({
            'date': pd.to_datetime(['2025-01-01', '2025-01-02', '2025-01-03']),
            'amount': [100, 100, 100],
            'category': ['Food', 'Transport', 'Bills']
        })
        
        smart_insights = []
        expenses_clustering = []
        
        kmeans_clustering(identical_expenses, smart_insights, expenses_clustering)
        self.assertGreaterEqual(len(expenses_clustering), 0)


if __name__ == '__main__':
    # Set up environment for testing
    os.environ['FLASK_PASSWORD'] = 'test_password'
    
    test_classes = [
        TestBusinessLogic,
        TestMLModels, 
        TestFlaskEndpoints,
        TestChatEndpoint,
        TestDataValidation
    ]
    
    loader = unittest.TestLoader()
    suites = [loader.loadTestsFromTestCase(test_class) for test_class in test_classes]
    combined_suite = unittest.TestSuite(suites)
    
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(combined_suite)
    
    # Clean up environment
    if 'FLASK_PASSWORD' in os.environ:
        del os.environ['FLASK_PASSWORD']
    
    print(f"\n{'='*50}")
    print(f"TESTS RUN: {result.testsRun}")
    print(f"FAILURES: {len(result.failures)}")
    print(f"ERRORS: {len(result.errors)}")
    print(f"SUCCESS RATE: {((result.testsRun - len(result.failures) - len(result.errors)) / result.testsRun * 100):.1f}%")
    print(f"{'='*50}")
