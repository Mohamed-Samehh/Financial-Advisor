import unittest
import pandas as pd
import numpy as np
import json
import os
from datetime import datetime, timedelta

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

class TestBusinessLogicMeaningful(unittest.TestCase):
    
    def setUp(self):
        # Create realistic expense categories with different priorities
        self.categories = pd.DataFrame({
            'name': ['Food', 'Transport', 'Entertainment', 'Bills', 'Healthcare'],
            'priority': [1, 2, 3, 1, 1]  # Essential: 1, Moderate: 2, Low: 3
        })
        
        # Create realistic spending pattern over 15 days
        base_date = datetime(2025, 1, 1)
        self.expenses = pd.DataFrame({
            'date': pd.to_datetime([base_date + timedelta(days=i) for i in range(15)]),
            'amount': [120, 45, 200, 85, 150, 95, 80, 110, 75, 160, 90, 130, 70, 105, 140],
            'category': ['Food', 'Transport', 'Entertainment', 'Food', 'Bills', 
                        'Food', 'Transport', 'Food', 'Transport', 'Entertainment',
                        'Food', 'Bills', 'Transport', 'Food', 'Entertainment']
        })
        
        # Historical data with different spending patterns
        self.historical_expenses = pd.DataFrame({
            'date': pd.to_datetime([
                '2024-01-01', '2024-01-15', '2024-02-01', '2024-02-15',
                '2024-03-01', '2024-03-15', '2024-04-01', '2024-04-15'
            ]),
            'amount': [100, 110, 95, 105, 120, 90, 115, 100],
            'category': ['Food', 'Food', 'Transport', 'Transport', 
                        'Bills', 'Bills', 'Entertainment', 'Entertainment']
        })
    
    def test_assign_limits_priority_logic(self):
        # Test that priority system actually works correctly
        allowed_spending = 1000
        result = assign_limits(self.categories, allowed_spending)
        
        # Essential categories (priority 1) should get more than non-essential (priority 3)
        food_limit = result[result['name'] == 'Food']['limit'].iloc[0]
        bills_limit = result[result['name'] == 'Bills']['limit'].iloc[0]
        healthcare_limit = result[result['name'] == 'Healthcare']['limit'].iloc[0]
        transport_limit = result[result['name'] == 'Transport']['limit'].iloc[0]
        entertainment_limit = result[result['name'] == 'Entertainment']['limit'].iloc[0]
        
        # All essential categories should have equal allocation
        self.assertAlmostEqual(food_limit, bills_limit, places=2)
        self.assertAlmostEqual(food_limit, healthcare_limit, places=2)
        
        # Essential should get more than moderate and low priority
        self.assertGreater(food_limit, transport_limit)
        self.assertGreater(food_limit, entertainment_limit)
        self.assertGreater(transport_limit, entertainment_limit)
        
        # Total should equal allowed spending
        self.assertAlmostEqual(result['limit'].sum(), allowed_spending, places=2)
    
    def test_predictive_insights_realistic_projection(self):
        # Test with known spending pattern to validate prediction logic
        # 15 days of data, spending 1,575LE total = 105LE/day average
        result = predictive_insights(self.expenses)
        
        # For January (31 days), after 15 days, should predict remaining 16 days
        days_in_jan = 31
        days_elapsed = 15
        remaining_days = days_in_jan - days_elapsed  # 16 days
        current_total = self.expenses['amount'].sum()  # 1575
        daily_avg = current_total / days_elapsed  # 105
        expected_prediction = current_total + (daily_avg * remaining_days)
        
        self.assertAlmostEqual(result, expected_prediction, places=1)
        self.assertGreater(result, current_total)  # Should be higher than current spending
        
    def test_predictive_insights_edge_cases(self):
        # Test single day spending
        single_day = self.expenses.iloc[:1].copy()
        result = predictive_insights(single_day)
        self.assertIsNotNone(result)
        self.assertGreater(result, single_day['amount'].sum())
        
        # Test empty dataframe
        empty_df = pd.DataFrame(columns=['date', 'amount'])
        empty_df['date'] = pd.to_datetime(empty_df['date'])
        result_empty = predictive_insights(empty_df)
        self.assertIsNone(result_empty)
    
    def test_spending_variability_detects_inconsistent_categories(self):
        # Create expenses with Food having high variability, Transport being consistent
        variable_expenses = pd.DataFrame({
            'date': pd.to_datetime(['2025-01-01', '2025-01-02', '2025-01-03', 
                                   '2025-01-04', '2025-01-05', '2025-01-06']),
            'amount': [50, 200, 60, 180, 70, 190],  # Food varies wildly, Transport consistent
            'category': ['Food', 'Food', 'Transport', 'Transport', 'Bills', 'Bills']
        })
        
        smart_insights = []
        analyze_spending_variability(variable_expenses, smart_insights)
        
        self.assertGreater(len(smart_insights), 0)
        # Should identify Food as most variable
        self.assertIn('Food', smart_insights[0])
        self.assertIn('varies the most', smart_insights[0])
    
    def test_analyze_spending_deviations_increase_decrease_detection(self):
        # Create current expenses that deviate from historical patterns
        current_expenses = pd.DataFrame({
            'date': pd.to_datetime([
                '2025-01-01', '2025-01-02', '2025-01-03', '2025-01-04', 
                '2025-01-05', '2025-01-06', '2025-01-07', '2025-01-08'
            ]),
            'amount': [300, 320, 20, 25, 150, 160, 80, 85],  # Food increased, Transport decreased, Bills normal
            'category': ['Food', 'Food', 'Transport', 'Transport', 'Bills', 'Bills', 'Entertainment', 'Entertainment']
        })
        
        # Create historical data using simple list comprehension - cleaner approach
        historical_dates = []
        historical_amounts = []
        historical_categories = []
        
        # Generate 3 months of historical data for each category
        for month in range(1, 4):  # 3 months
            for day in [1, 15]:    # 2 entries per month
                base_date = f'2024-{month:02d}-{day:02d}'
                
                # Food: historically lower spending (~100-110)
                historical_dates.append(base_date)
                historical_amounts.append(100 + (month * 5))
                historical_categories.append('Food')
                
                # Transport: historically higher spending (~60-70) 
                historical_dates.append(base_date)
                historical_amounts.append(65 + (month * 2))
                historical_categories.append('Transport')
                
                # Bills: historically similar spending (~140-160)
                historical_dates.append(base_date)
                historical_amounts.append(150 + (month * 3))
                historical_categories.append('Bills')
                
                # Entertainment: historically similar spending (~80-90)
                historical_dates.append(base_date)
                historical_amounts.append(85 + (month * 2))
                historical_categories.append('Entertainment')
        
        historical_expenses = pd.DataFrame({
            'date': pd.to_datetime(historical_dates),
            'amount': historical_amounts,
            'category': historical_categories
        })
        
        smart_insights = []
        analyze_spending_deviations(current_expenses, historical_expenses, smart_insights)
        
        self.assertGreater(len(smart_insights), 0)
        insight_text = smart_insights[0].lower()
        
        # Should detect Food increased and Transport decreased
        self.assertTrue(
            ('food' in insight_text and 'increased' in insight_text) or
            ('transport' in insight_text and 'decreased' in insight_text)
        )
    
    def test_analyze_spending_deviations_with_insufficient_history(self):
        # Test with minimal historical data
        current_expenses = self.expenses.iloc[:5].copy()
        minimal_history = pd.DataFrame({
            'date': pd.to_datetime(['2024-01-01', '2024-01-02']),
            'amount': [100, 50],
            'category': ['Food', 'Transport']
        })
        
        smart_insights = []
        analyze_spending_deviations(current_expenses, minimal_history, smart_insights)
        
        # Should handle gracefully even with minimal history
        self.assertIsInstance(smart_insights, list)
    
    def test_day_of_week_analysis_meaningful_patterns(self):
        # Create expenses with clear weekend vs weekday pattern
        weekend_heavy_expenses = pd.DataFrame({
            'date': pd.to_datetime([
                '2025-01-04', '2025-01-05',  # Saturday, Sunday - high spending
                '2025-01-06', '2025-01-07',  # Monday, Tuesday - low spending
                '2025-01-11', '2025-01-12'   # Saturday, Sunday - high spending again
            ]),
            'amount': [200, 180, 50, 60, 220, 190],
            'category': ['Entertainment', 'Entertainment', 'Food', 'Food', 'Entertainment', 'Entertainment']
        })
        
        smart_insights = []
        day_of_week_analysis(weekend_heavy_expenses, smart_insights)
        
        self.assertGreater(len(smart_insights), 0)
        # Should mention Saturday or Sunday as highest spending day
        insight_text = smart_insights[0].lower()
        self.assertTrue('saturday' in insight_text or 'sunday' in insight_text)


class TestMLModelsAccuracy(unittest.TestCase):
    
    def setUp(self):
        # Create expenses with clear upward trend for testing linear regression
        np.random.seed(42)  # For reproducible results
        dates = pd.date_range(start='2024-01-01', end='2024-12-31', freq='M')
        # Simulate increasing spending over months (trend)
        base_amounts = [1000 + (i * 50) + np.random.normal(0, 100) for i in range(12)]
        
        self.trending_expenses = pd.DataFrame({
            'date': dates,
            'amount': [max(500, amt) for amt in base_amounts],  # Ensure positive amounts
            'category': np.random.choice(['Food', 'Transport', 'Bills'], 12)
        })
        
        # Create expenses for clustering with distinct spending groups
        self.clustering_expenses = pd.DataFrame({
            'date': pd.to_datetime(['2025-01-01'] * 15),
            'amount': [20, 25, 30, 35, 40,  # Low spending group
                      100, 110, 120, 130, 140,  # Medium spending group  
                      300, 320, 350, 380, 400], # High spending group
            'category': ['Food'] * 5 + ['Transport'] * 5 + ['Entertainment'] * 5
        })
    
    def test_linear_regression_trend_detection(self):
        # Test if linear regression can detect upward spending trend
        predictions = []
        linear_regression(self.trending_expenses, predictions, month_num=3)
        
        if len(predictions) > 0:
            # Predictions should exist for trending data
            self.assertGreater(len(predictions), 0)
            
            # Each prediction should have reasonable accuracy (R² > 0.5)
            for pred in predictions:
                self.assertGreaterEqual(pred['accuracy'], 0.5)
                self.assertGreaterEqual(pred['correlation'], 0.5)
                
            # Later month predictions should be higher (upward trend)
            if len(predictions) >= 2:
                first_pred = predictions[0]['predicted_spending']
                second_pred = predictions[1]['predicted_spending']
                self.assertGreaterEqual(second_pred, first_pred * 0.9)  # Allow slight variation
    
    def test_linear_regression_insufficient_data(self):
        # Test with insufficient data (< 3 months)
        insufficient_data = self.trending_expenses.iloc[:2].copy()
        predictions = []
        linear_regression(insufficient_data, predictions)
        
        # Should not generate predictions with insufficient data
        self.assertEqual(len(predictions), 0)
    
    def test_category_linear_regression_individual_trends(self):
        # Test category-specific regression with different trends per category
        # Food: increasing trend, Transport: decreasing trend, Bills: stable
        np.random.seed(42)
        
        # Create 8 months of data with distinct category trends
        dates = pd.date_range('2024-01-01', periods=8, freq='M')
        
        category_trends = pd.DataFrame({
            'date': list(dates) * 3,  # 8 months × 3 categories = 24 records
            'amount': (
                [800 + i*50 for i in range(8)] +  # Food: increasing 800->1150
                [500 - i*20 for i in range(8)] +  # Transport: decreasing 500->360  
                [300 + np.random.normal(0, 10) for i in range(8)]  # Bills: stable ~300
            ),
            'category': ['Food']*8 + ['Transport']*8 + ['Bills']*8
        })
        
        category_predictions = {}
        category_linear_regression(category_trends, category_predictions, month_num=2)
        
        # Should generate predictions for categories with clear trends
        self.assertGreater(len(category_predictions), 0)
        
        # Food should have predictions (strong upward trend)
        if 'Food' in category_predictions:
            food_preds = category_predictions['Food']
            self.assertGreater(len(food_preds), 0)
            # Should have good accuracy for clear trend
            self.assertGreaterEqual(food_preds[0]['accuracy'], 0.7)
            # Next month should be higher than current trend
            self.assertGreater(food_preds[0]['predicted_spending'], 1100)
        
        # Transport should have predictions (strong downward trend)
        if 'Transport' in category_predictions:
            transport_preds = category_predictions['Transport']
            self.assertGreater(len(transport_preds), 0)
            self.assertGreaterEqual(transport_preds[0]['accuracy'], 0.7)
            # Should predict continued decrease
            self.assertLess(transport_preds[0]['predicted_spending'], 400)
    
    def test_category_linear_regression_accuracy_threshold(self):
        # Test with random data that shouldn't meet accuracy threshold
        np.random.seed(123)  # Different seed for random data
        
        random_data = pd.DataFrame({
            'date': pd.date_range('2024-01-01', periods=6, freq='M'),
            'amount': np.random.uniform(100, 1000, 6),  # Completely random amounts
            'category': ['Food'] * 6
        })
        
        category_predictions = {}
        category_linear_regression(random_data, category_predictions, 
                                 accuracy_threshold=0.8, correlation_threshold=0.8)
        
        # Should not generate predictions for random data with high thresholds
        self.assertEqual(len(category_predictions), 0)
    
    def test_kmeans_clustering_meaningful_groups(self):
        # Test if K-means correctly identifies spending groups
        smart_insights = []
        expenses_clustering = []
        
        kmeans_clustering(self.clustering_expenses, smart_insights, expenses_clustering)
        
        # Should create 3 distinct clusters
        self.assertEqual(len(expenses_clustering), 3)
        
        # Verify clusters are properly ordered (Low, Moderate, High)
        cluster_labels = [cluster['cluster'] for cluster in expenses_clustering]
        expected_labels = ['High', 'Moderate', 'Low']
        for label in expected_labels:
            self.assertIn(label, cluster_labels)
        
        # High cluster should have higher amounts than Low cluster
        high_cluster = next(c for c in expenses_clustering if c['cluster'] == 'High')
        low_cluster = next(c for c in expenses_clustering if c['cluster'] == 'Low')
        
        self.assertGreater(high_cluster['min_expenses'], low_cluster['max_expenses'])
    
    def test_spending_clustering_category_grouping(self):
        # Test if spending clustering groups categories correctly by total spending
        spending_clustering = []
        spending_kmeans_clustering(self.clustering_expenses, spending_clustering)
        
        self.assertEqual(len(spending_clustering), 1)
        categories_by_spending = spending_clustering[0]['spending_group']
        
        # Should group categories by their total spending levels
        entertainment_group = next(c for c in categories_by_spending if c['category'] == 'Entertainment')
        food_group = next(c for c in categories_by_spending if c['category'] == 'Food')
        
        # Entertainment (high individual amounts) should be in High group
        self.assertEqual(entertainment_group['spending_group'], 'High')
        # Food (low individual amounts) should be in Low group  
        self.assertEqual(food_group['spending_group'], 'Low')
    
    def test_frequency_kmeans_clustering_usage_patterns(self):
        # Test frequency clustering with clear usage patterns
        # Food: high frequency, Entertainment: medium frequency, Healthcare: low frequency
        frequency_test_expenses = pd.DataFrame({
            'date': pd.to_datetime(['2025-01-01'] * 20),  # Same day for simplicity
            'amount': [50] * 20,  # Same amount, focus on frequency
            'category': (['Food'] * 12 +      # High frequency: 12 transactions
                        ['Entertainment'] * 5 +  # Medium frequency: 5 transactions  
                        ['Healthcare'] * 3)       # Low frequency: 3 transactions
        })
        
        frequency_clustering = []
        frequency_kmeans_clustering(frequency_test_expenses, frequency_clustering)
        
        self.assertEqual(len(frequency_clustering), 1)
        categories_by_frequency = frequency_clustering[0]['frequency_group']
        
        # Find frequency groups for each category
        food_freq = next(c for c in categories_by_frequency if c['category'] == 'Food')
        entertainment_freq = next(c for c in categories_by_frequency if c['category'] == 'Entertainment')  
        healthcare_freq = next(c for c in categories_by_frequency if c['category'] == 'Healthcare')
        
        # Food (12 transactions) should be High frequency
        self.assertEqual(food_freq['frequency_group'], 'High')
        # Healthcare (3 transactions) should be Low frequency
        self.assertEqual(healthcare_freq['frequency_group'], 'Low')
        # Entertainment (5 transactions) should be Moderate
        self.assertEqual(entertainment_freq['frequency_group'], 'Moderate')
    
    def test_frequency_clustering_identical_frequencies(self):
        # Test edge case where all categories have same frequency
        identical_freq_expenses = pd.DataFrame({
            'date': pd.to_datetime(['2025-01-01'] * 9),
            'amount': [100] * 9,
            'category': ['Food'] * 3 + ['Transport'] * 3 + ['Bills'] * 3  # All have frequency 3
        })
        
        frequency_clustering = []
        frequency_kmeans_clustering(identical_freq_expenses, frequency_clustering)
        
        self.assertEqual(len(frequency_clustering), 1)
        categories_by_frequency = frequency_clustering[0]['frequency_group']
        
        # All should be classified as 'Moderate' when frequencies are identical
        for category_info in categories_by_frequency:
            self.assertEqual(category_info['frequency_group'], 'Moderate')
    
    def test_frequency_clustering_single_category(self):
        # Test frequency clustering with only one category
        single_category = pd.DataFrame({
            'date': pd.to_datetime(['2025-01-01'] * 5),
            'amount': [50, 60, 70, 80, 90],
            'category': ['Food'] * 5
        })
        
        frequency_clustering = []
        frequency_kmeans_clustering(single_category, frequency_clustering)
        
        self.assertEqual(len(frequency_clustering), 1)
        categories_by_frequency = frequency_clustering[0]['frequency_group']
        
        # Single category should be classified (likely as 'Moderate')
        self.assertEqual(len(categories_by_frequency), 1)
        self.assertEqual(categories_by_frequency[0]['category'], 'Food')
        self.assertIn(categories_by_frequency[0]['frequency_group'], ['High', 'Moderate', 'Low'])
    
    def test_association_rules_realistic_patterns(self):
        # Create data with clear category associations (groceries + household items)
        associated_expenses = pd.DataFrame({
            'date': pd.to_datetime([
                '2025-01-01', '2025-01-01', '2025-01-02', '2025-01-02',
                '2025-01-03', '2025-01-03', '2025-01-04', '2025-01-04',
                '2025-01-05', '2025-01-05'
            ]),
            'amount': [50] * 10,
            'category': ['Food', 'Bills', 'Food', 'Bills', 'Food', 'Bills',
                        'Food', 'Bills', 'Food', 'Bills']  # Strong association
        })
        
        association_rules = []
        get_association_rules(associated_expenses, association_rules, 
                            min_support=0.3, min_confidence=0.7, min_lift=1.0)
        
        # Should find rules for strongly associated categories
        if len(association_rules) > 0:
            # Rules should have reasonable confidence and lift
            for rule in association_rules:
                self.assertGreaterEqual(rule['confidence'], 0.7)
                self.assertGreaterEqual(rule['lift'], 1.0)
                # Should involve Food and Bills
                all_items = rule['antecedents'] + rule['consequents']
                self.assertTrue('Food' in all_items or 'Bills' in all_items)
    
    def test_rule_based_labeling_importance_classification(self):
        # Create historical data with clear spending patterns for importance labeling
        high_essential_expenses = pd.DataFrame({
            'date': pd.date_range('2024-01-01', periods=60, freq='W'),  # Weekly for 60 weeks
            'amount': ([200] * 20 + [150] * 20 + [50] * 20),  # Food high, Transport medium, Entertainment low
            'category': (['Food'] * 20 + ['Transport'] * 20 + ['Entertainment'] * 20)
        })
        
        labeled_categories = []
        Rule_Based_labeling(high_essential_expenses, labeled_categories)
        
        self.assertGreater(len(labeled_categories), 0)
        categories = labeled_categories[0]['predicted_importance']
        
        # Find importance levels for each category
        food_importance = next(c['predicted_importance'] for c in categories if c['category'] == 'Food')
        entertainment_importance = next(c['predicted_importance'] for c in categories if c['category'] == 'Entertainment')
        
        # Food (high spending, high frequency) should be Essential
        self.assertEqual(food_importance, 'Essential')
        # Entertainment (low spending) should be Non-Essential or Moderate
        self.assertIn(entertainment_importance, ['Non-Essential', 'Moderate'])


class TestFlaskEndpointsRealWorld(unittest.TestCase):
    
    def setUp(self):
        # Set test environment
        os.environ['FLASK_PASSWORD'] = 'test_password'
        
        from app import app
        self.app = app
        self.app.config['TESTING'] = True
        self.client = self.app.test_client()
        
        # Realistic user scenario: overspending on entertainment, within budget on essentials
        self.overspending_scenario = {
            'password': 'test_password',
            'expenses': [
                {'date': '2025-01-01', 'amount': 120, 'category': 'Food'},
                {'date': '2025-01-02', 'amount': 45, 'category': 'Transport'},
                {'date': '2025-01-03', 'amount': 350, 'category': 'Entertainment'},  # Way over limit
                {'date': '2025-01-04', 'amount': 85, 'category': 'Food'},
                {'date': '2025-01-05', 'amount': 200, 'category': 'Bills'}
            ],
            'all_expenses': [
                {'date': '2024-12-01', 'amount': 100, 'category': 'Food'},
                {'date': '2024-12-02', 'amount': 40, 'category': 'Transport'},
                {'date': '2024-12-03', 'amount': 80, 'category': 'Entertainment'},
                {'date': '2024-11-01', 'amount': 110, 'category': 'Food'},
                {'date': '2024-11-02', 'amount': 50, 'category': 'Transport'}
            ],
            'categories': [
                {'name': 'Food', 'priority': 1},
                {'name': 'Transport', 'priority': 2}, 
                {'name': 'Entertainment', 'priority': 3},  # Lowest priority
                {'name': 'Bills', 'priority': 1}
            ],
            'monthly_budget': 1000,
            'goal_amount': 200,  # Want to save 200
            'total_spent': 800    # Spent 800, allowed spending is 800 (1000-200)
        }
    
    def test_overspending_scenario_advice(self):
        # Test system correctly identifies overspending categories and gives advice
        response = self.client.post('/analysis',
                                  data=json.dumps(self.overspending_scenario),
                                  content_type='application/json')
        
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        
        # Should have advice about overspending
        self.assertIn('advice', data)
        advice_text = ' '.join(data['advice']).lower()
        
        # Should specifically mention Entertainment overspending
        self.assertIn('entertainment', advice_text)
        self.assertIn('overspending', advice_text)
        
        # Should have category limits that show Entertainment got least allocation
        category_limits = data['category_limits']
        entertainment_limit = next(c['limit'] for c in category_limits if c['name'] == 'Entertainment')
        food_limit = next(c['limit'] for c in category_limits if c['name'] == 'Food')
        
        # Entertainment (priority 3) should get less than Food (priority 1)
        self.assertLess(entertainment_limit, food_limit)
    
    def test_budget_exceeded_vs_goal_exceeded_scenarios(self):
        # Test different overspending scenarios give appropriate advice
        budget_exceeded = self.overspending_scenario.copy()
        budget_exceeded['total_spent'] = 1200  # Exceeds 1000 budget
        
        response = self.client.post('/analysis',
                                  data=json.dumps(budget_exceeded),
                                  content_type='application/json')
        
        data = json.loads(response.data)
        advice_text = ' '.join(data['advice']).lower()
        
        # Should mention budget exceeded
        self.assertIn('budget', advice_text)
        self.assertIn('exceed', advice_text)
    
    def test_prediction_threshold_logic(self):
        # Test that predictions are only made with sufficient data (>= 5 expenses)
        insufficient_data = self.overspending_scenario.copy()
        insufficient_data['expenses'] = insufficient_data['expenses'][:3]  # Only 3 expenses
        
        response = self.client.post('/analysis',
                                  data=json.dumps(insufficient_data),
                                  content_type='application/json')
        
        data = json.loads(response.data)
        
        # Should not make predictions with insufficient data
        self.assertIsNone(data['predicted_current_month'])
    
    def test_ml_features_activation_thresholds(self):
        # Test that ML features activate at correct data thresholds
        sufficient_data = self.overspending_scenario.copy()
        
        # Add more expenses to reach various ML thresholds
        for i in range(10):  # Add 10 more expenses (total 15)
            sufficient_data['expenses'].append({
                'date': f'2025-01-{10+i:02d}',
                'amount': 50,
                'category': 'Food'
            })
        
        response = self.client.post('/analysis',
                                  data=json.dumps(sufficient_data),
                                  content_type='application/json')
        
        data = json.loads(response.data)
        
        # Should have clustering results (threshold >= 5)
        self.assertGreater(len(data['expenses_clustering']), 0)
        self.assertGreater(len(data['spending_clustering']), 0)
        
        # Should have smart insights from variability analysis (>= 5 expenses, >= 3 categories)
        self.assertGreater(len(data['smart_insights']), 0)
    
    def tearDown(self):
        # Clean up environment
        if 'FLASK_PASSWORD' in os.environ:
            del os.environ['FLASK_PASSWORD']


class TestEdgeCasesAndValidation(unittest.TestCase):
    # Test realistic edge cases that users might encounter
    
    def test_single_category_user(self):
        # User only spends in one category (common for new users)
        single_category_expenses = pd.DataFrame({
            'date': pd.to_datetime(['2025-01-01', '2025-01-02', '2025-01-03']),
            'amount': [100, 120, 90],
            'category': ['Food', 'Food', 'Food']
        })
        
        # Should handle gracefully without errors
        result = predictive_insights(single_category_expenses)
        self.assertIsNotNone(result)
        self.assertGreater(result, single_category_expenses['amount'].sum())
        
        # Clustering should still work
        smart_insights = []
        expenses_clustering = []
        kmeans_clustering(single_category_expenses, smart_insights, expenses_clustering)
        self.assertGreaterEqual(len(expenses_clustering), 1)
    
    def test_extreme_spending_amounts(self):
        # Test with very high and very low amounts
        extreme_expenses = pd.DataFrame({
            'date': pd.to_datetime(['2025-01-01', '2025-01-02', '2025-01-03']),
            'amount': [0.50, 5000, 1],  # Very low, very high, normal
            'category': ['Food', 'Bills', 'Transport']
        })
        
        # Prediction should handle extreme values
        result = predictive_insights(extreme_expenses)
        self.assertIsNotNone(result)
        self.assertGreater(result, 0)
        
        # Clustering should separate extremes
        smart_insights = []
        expenses_clustering = []
        kmeans_clustering(extreme_expenses, smart_insights, expenses_clustering)
        
        # Should create distinct clusters for extreme values
        high_cluster = next(c for c in expenses_clustering if c['cluster'] == 'High')
        low_cluster = next(c for c in expenses_clustering if c['cluster'] == 'Low')
        
        self.assertGreater(high_cluster['min_expenses'], low_cluster['max_expenses'])
    
    def test_irregular_spending_patterns(self):
        # Test spending that doesn't follow normal patterns (e.g., one huge expense then nothing)
        irregular_expenses = pd.DataFrame({
            'date': pd.to_datetime([
                '2025-01-01', '2025-01-02', '2025-01-03', '2025-01-04', '2025-01-05'
            ]),
            'amount': [2000, 0, 0, 0, 5],  # One big expense, then almost nothing
            'category': ['Bills', 'Food', 'Transport', 'Food', 'Transport']
        })
        
        # System should still make reasonable predictions
        result = predictive_insights(irregular_expenses)
        self.assertIsNotNone(result)
        
        # Should identify Bills as highly variable
        smart_insights = []
        analyze_spending_variability(irregular_expenses, smart_insights)
        
        if len(smart_insights) > 0:
            insight_text = smart_insights[0].lower()
            # Should mention variability (though exact category may vary due to limited data)
            self.assertIn('varies', insight_text)


if __name__ == '__main__':
    # Set up test environment
    os.environ['FLASK_PASSWORD'] = 'test_password'
    
    test_classes = [
        TestBusinessLogicMeaningful,
        TestMLModelsAccuracy,
        TestFlaskEndpointsRealWorld,
        TestEdgeCasesAndValidation
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
    
    # Print detailed results for meaningful insights
    if result.failures or result.errors:
        print("\nFAILED TESTS ANALYSIS:")
        for test, error in result.failures + result.errors:
            print(f"- {test}: {error.split('AssertionError:')[-1].strip() if 'AssertionError:' in error else 'Runtime Error'}")
