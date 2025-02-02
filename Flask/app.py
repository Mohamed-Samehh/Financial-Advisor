from flask import Flask, request, jsonify
import pandas as pd
from sklearn.cluster import KMeans
from mlxtend.frequent_patterns import apriori
from itertools import combinations
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
from sklearn.preprocessing import StandardScaler, LabelEncoder

app = Flask(__name__)

FLASK_PASSWORD = "Y7!mK4@vW9#qRp$2" # Require a password as a layer of security

# Assign limits to categories based on priority
def assign_limits(categories, allowed_spending):
    categories['weight'] = (categories['priority'].count() + 1) - categories['priority']
    categories['limit'] = (categories['weight'] / categories['weight'].sum()) * allowed_spending
    return categories[['name', 'limit']]


# Predict total spending for the current month using daily average
def predictive_insights(expenses):
    total_days_in_month = expenses['date'].dt.daysinmonth.max()
    days_elapsed = (expenses['date'].max() - expenses['date'].min()).days + 1

    if days_elapsed > 0:
        average_daily_spending = expenses['amount'].sum() / days_elapsed
        remaining_days = total_days_in_month - days_elapsed
        predicted_remaining_spending = average_daily_spending * remaining_days
        predicted_total_spending = expenses['amount'].sum() + predicted_remaining_spending
        return round(predicted_total_spending, 2)
    return None


# Generate weights with exponential decay
def generate_weights(length, decay_factor=0.9):
    return [decay_factor ** (length - i - 1) for i in range(length)]


# Predict spending using weighted average
def weighted_average(distinct_all_expenses, expenses, predicted_current_month):
    distinct_all_expenses['month'] = distinct_all_expenses['date'].dt.month
    distinct_all_expenses['year'] = distinct_all_expenses['date'].dt.year

    current_year = expenses['date'].max().year
    current_month = expenses['date'].max().month

    monthly_spending = distinct_all_expenses.groupby(['year', 'month'])['amount'].sum().reset_index()

    if predicted_current_month is not None:
        monthly_spending = pd.concat([
            monthly_spending,
            pd.DataFrame({'year': [current_year], 'month': [current_month], 'amount': [predicted_current_month]})
        ], ignore_index=True)

    if len(monthly_spending) >= 2:
        weights = generate_weights(len(monthly_spending))
        weighted_avg = (monthly_spending['amount'] * weights).sum() / sum(weights)
        return round(weighted_avg, 2)

    return None


# Behavioral clustering using KMeans to identify spending patterns
def kmeans_clustering(expenses, smart_insights):
    scaler = StandardScaler()
    expenses['normalized_amount'] = scaler.fit_transform(expenses[['amount']])

    kmeans = KMeans(n_clusters=3, random_state=42)
    clusters = kmeans.fit_predict(expenses[['normalized_amount']])
    expenses['cluster'] = clusters

    cluster_averages = expenses.groupby('cluster')['normalized_amount'].mean()
    highest_spending_cluster = cluster_averages.idxmax()

    highest_cluster_data = expenses[expenses['cluster'] == highest_spending_cluster]

    category_counts = highest_cluster_data['category'].value_counts()

    top_categories = category_counts.head(4).index.tolist()

    if top_categories:
        combined_categories = ', '.join(top_categories)
        smart_insights.append(f"Consider monitoring expenses in {combined_categories}, as they show a high spending pattern.")


# Generate association rules to identify category relationships
def get_association_rules(expenses, association_rules, min_support=0.5, min_confidence=0.8, min_lift=1.5):
    basket = expenses.groupby(['date', 'category'])['category'].count().unstack().fillna(0)
    basket = basket.map(lambda x: 1 if x > 0 else 0)
    basket = basket.astype(bool)

    frequent_itemsets = apriori(basket, min_support=min_support, use_colnames=True)
    support_dict = frequent_itemsets.set_index('itemsets')['support'].to_dict()

    for itemset in frequent_itemsets['itemsets']:
        if len(itemset) >= 2:
            for antecedent in combinations(itemset, len(itemset) - 1):
                antecedent = frozenset(antecedent)
                consequent = itemset - antecedent

                if antecedent in support_dict and itemset in support_dict:
                    confidence = support_dict[itemset] / support_dict[antecedent]
                    lift = confidence / support_dict[consequent] if consequent in support_dict else None

                    if confidence >= min_confidence and (lift is None or lift >= min_lift):
                        association_rules.append({
                            'antecedents': list(antecedent),
                            'consequents': list(consequent),
                            'support': support_dict[itemset],
                            'confidence': confidence,
                            'lift': lift
                        })


# Random forest classification to classify category importance
def importance_random_forest_classification(all_expenses, importance_classification, accuracy_threshold=0.75):
    all_expenses['category_encoded'] = LabelEncoder().fit_transform(all_expenses['category'])
    all_expenses['year'] = all_expenses['date'].dt.year
    all_expenses['month'] = all_expenses['date'].dt.month

    category_stats = all_expenses.groupby('category').agg(
        total_spent=('amount', 'sum'),
        frequency=('category', 'count'),
        consistency=('amount', 'std')
    )

    conditions = [
        (category_stats['total_spent'] > category_stats['total_spent'].quantile(0.75)) & 
        (category_stats['consistency'] < category_stats['consistency'].quantile(0.25)),
        (category_stats['frequency'] > category_stats['frequency'].quantile(0.75)),
        (category_stats['total_spent'].between(category_stats['total_spent'].quantile(0.25), category_stats['total_spent'].quantile(0.75))) &
        (category_stats['frequency'].between(category_stats['frequency'].quantile(0.25), category_stats['frequency'].quantile(0.75)))
    ]

    labels = ['Essential', 'Essential', 'Moderate', 'Non-Essential']

    category_stats['importance'] = 'Non-Essential'
    for i in range(len(conditions)):
        category_stats.loc[conditions[i], 'importance'] = labels[i]

    features = all_expenses[['amount', 'category_encoded']]
    target = all_expenses['category'].map(category_stats['importance'])

    if len(features) >= 5:
        X_train, X_test, y_train, y_test = train_test_split(features, target, test_size=0.2, random_state=42)

        rf = RandomForestClassifier(n_estimators=100, max_depth=None, random_state=42)
        rf.fit(X_train, y_train)
        predictions = rf.predict(X_test)

        accuracy = accuracy_score(y_test, predictions)

        if accuracy >= accuracy_threshold:
            predictions_all = rf.predict(features)
            category_importance = pd.DataFrame({
                'category': all_expenses['category'],
                'predicted_importance': predictions_all
            }).drop_duplicates().sort_values('predicted_importance', ascending=False)

            importance_classification.append({
                'predicted_importance': [
                    {'category': row[0], 'predicted_importance': row[1]}
                    for row in category_importance[['category', 'predicted_importance']].values.tolist()
                ],
                'accuracy': accuracy
            })


# Random forest classification to classify category spending frequency
def spending_random_forest_classification(expenses, spending_classification, accuracy_threshold=0.4):
    expenses['category_encoded'] = LabelEncoder().fit_transform(expenses['category'])
    expenses['month'] = expenses['date'].dt.month
    expenses['year'] = expenses['date'].dt.year

    frequency = expenses.groupby('category').size()

    labels = ['High', 'Moderate', 'Low']
    frequency_classification = pd.cut(frequency, bins=[0, frequency.quantile(0.5), frequency.quantile(0.75), frequency.max()], labels=labels)

    expenses['spending_frequency'] = expenses['category'].map(frequency_classification)

    features = expenses[['amount', 'category_encoded']]
    target = expenses['spending_frequency']

    if len(features) >= 5:
        X_train, X_test, y_train, y_test = train_test_split(features, target, test_size=0.2, random_state=42)

        rf = RandomForestClassifier(n_estimators=100, max_depth=None, random_state=42)
        rf.fit(X_train, y_train)
        predictions = rf.predict(X_test)

        accuracy = accuracy_score(y_test, predictions)

        if accuracy >= accuracy_threshold:
            predictions_all = rf.predict(features)
            category_frequency = pd.DataFrame({
                'category': expenses['category'],
                'predicted_frequency': predictions_all
            }).drop_duplicates().sort_values('predicted_frequency', ascending=False)

            spending_classification.append({
                'predicted_frequency': [
                    {'category': row[0], 'predicted_frequency': row[1]}
                    for row in category_frequency[['category', 'predicted_frequency']].values.tolist()
                ],
                'accuracy': accuracy
            })


# Analyze category spending variability
def analyze_spending_variability(expenses, smart_insights):
    category_expense_counts = expenses['category'].value_counts()
    valid_categories = category_expense_counts[category_expense_counts >= 2].index

    if len(valid_categories) >= 2:
        category_variability = (
            expenses[expenses['category'].isin(valid_categories)]
            .groupby('category')['amount']
            .std()
            .sort_values(ascending=False)
        )

        if not category_variability.empty:
            most_variable_category = category_variability.idxmax()
            if pd.notna(most_variable_category):
                smart_insights.append(f"Spending in '{most_variable_category}' varies the most. Keep an eye on it!")


# Analyze deviations in category spending trends
# Momken ne5aleha a5er shahr bas law gebt a5er shahr etdafa3 fel "distinct_all_expenses"
def analyze_spending_deviations(expenses, distinct_all_expenses, smart_insights):
        category_average = distinct_all_expenses.groupby('category')['amount'].mean()
        current_month_average = expenses.groupby('category')['amount'].mean()

        deviations = (current_month_average - category_average).sort_values(ascending=False)

        if not deviations.empty:
            largest_increase_category = deviations.idxmax()
            largest_decrease_category = deviations.idxmin()

            if deviations[largest_increase_category] > 0 and deviations[largest_decrease_category] < 0:
                smart_insights.append(
                    f"Spending in the '{largest_increase_category}' category increased while the '{largest_decrease_category}' category decreased significantly compared to your usual spending."
                )
            else:
                if deviations[largest_increase_category] > 0:
                    smart_insights.append(
                        f"Spending in the '{largest_increase_category}' category increased significantly compared to your usual spending."
                    )
                if deviations[largest_decrease_category] < 0:
                    smart_insights.append(
                        f"Spending in the '{largest_decrease_category}' category decreased significantly compared to your usual spending."
                    )


# Day-of-week spending analysis to identify peak spending days
def day_of_week_analysis(expenses, smart_insights):
    expenses['day_of_week'] = expenses['date'].dt.day_name()

    weekday_counts = expenses['day_of_week'].value_counts().reindex(
        ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'], fill_value=0
    )

    weekday_spending = expenses.groupby('day_of_week')['amount'].mean().reindex(
        ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    )

    if len(weekday_counts[weekday_counts > 0]) >= 2:
        peak_count_day = weekday_counts.idxmax()
        peak_spending_day = weekday_spending.idxmax()
        smart_insights.append(f"You have the highest number of expenses on {peak_count_day}s, and the highest spending on {peak_spending_day}s. Plan ahead!")


@app.route('/analysis', methods=['POST'])
def analyze_expenses():
    data = request.json

    if data.get('password') != FLASK_PASSWORD:
        return jsonify({'error': 'Unauthorized'}), 401

    if not all(key in data for key in ['expenses', 'all_expenses', 'categories', 'monthly_budget', 'goal_amount', 'total_spent']):
        return jsonify({'error': 'Missing required data'}), 400

    if data['total_spent'] <= 0:
        return jsonify({'error': 'Total spent should be greater than 0'}), 400

    expenses = pd.DataFrame(data['expenses'])
    all_expenses = pd.DataFrame(data['all_expenses'])
    categories = pd.DataFrame(data['categories'])
    monthly_budget = data['monthly_budget']
    goal_amount = data['goal_amount']
    total_spent = data['total_spent']
    expenses['date'] = pd.to_datetime(expenses['date'])
    all_expenses['date'] = pd.to_datetime(all_expenses['date'])
    allowed_spending = monthly_budget - goal_amount

    
    # Remove current month's expenses from all expenses
    expenses_copy = expenses.copy() # Creating a copy of 'expenses' to avoid modifying the original DataFrame (Error)
    current_year = expenses_copy['date'].max().year
    current_month = expenses_copy['date'].max().month
    distinct_all_expenses = all_expenses[~((all_expenses['date'].dt.year == current_year) & 
                                        (all_expenses['date'].dt.month == current_month))].copy()
    distinct_all_expenses['month'] = distinct_all_expenses['date'].dt.month
    

    # Assign limits to categories
    expenses['priority'] = expenses['category'].map(dict(zip(categories['name'], categories['priority']))).fillna(-1)
    category_limits = assign_limits(categories, allowed_spending)
    category_totals = expenses.groupby('category')['amount'].sum().reset_index()
    category_totals = category_totals.merge(category_limits, left_on='category', right_on='name', how='left')

    advice = []
    smart_insights = []
    association_rules = []
    spending_classification = []
    

    predicted_current_month = predictive_insights(expenses) if len(expenses) >= 5 else None

    if goal_amount > 0:
        if total_spent > monthly_budget:
            advice.append("You've exceeded your monthly budget!")

        elif total_spent > allowed_spending:
            advice.append("You've spent more than your goal allows.")

            if predicted_current_month is not None and predicted_current_month > monthly_budget:
                advice.append("You're predicted to exceed your monthly budget.")
        
        elif predicted_current_month is not None and predicted_current_month > monthly_budget:
            advice.append("You're predicted to exceed your monthly budget.")

        elif predicted_current_month is not None and predicted_current_month > allowed_spending:
            advice.append("You're predicted to spend more than your goal allows.")

    else:
        advice.append('No goal was set for this month.')

        if total_spent > monthly_budget:
            advice.append("You've exceeded your monthly budget!")

        elif predicted_current_month is not None and predicted_current_month > monthly_budget:
            advice.append("You're predicted to exceed your monthly budget.")


    over_budget_categories = category_totals[category_totals['amount'] > category_totals['limit']]

    if len(over_budget_categories) > 0:
        combined_categories = "', '".join(over_budget_categories['category'])
        advice.append(f"You're overspending on '{combined_categories}'. Stop spending to avoid risks.")

    predicted_next_month = weighted_average(distinct_all_expenses, expenses, predicted_current_month) if len(distinct_all_expenses) >= 5 and len(expenses) >= 5 else None

    if len(expenses) >= 5:
        kmeans_clustering(expenses, smart_insights)
        spending_random_forest_classification(expenses, spending_classification)

    if len(expenses) >= 30:
        get_association_rules(expenses, association_rules, min_support=0.2, min_confidence=0.6, min_lift=1.0)
    elif len(expenses) >= 20:
        get_association_rules(expenses, association_rules, min_support=0.3, min_confidence=0.7, min_lift=1.2)
    elif len(expenses) >= 10:
        get_association_rules(expenses, association_rules, min_support=0.5, min_confidence=0.8, min_lift=1.5)

    if len(expenses) >= 5 and len(expenses['category'].unique()) >= 3:
        analyze_spending_variability(expenses, smart_insights)

    if len(expenses) >= 5 and len(distinct_all_expenses) >= 5 and len(expenses['category'].unique()) >= 3:
        analyze_spending_deviations(expenses, distinct_all_expenses, smart_insights)

    if len(expenses) >= 5:
        day_of_week_analysis(expenses, smart_insights)

    # Prepare results for API response
    category_limits_dict = category_limits.to_dict(orient='records')

    result = {
        'predicted_current_month': predicted_current_month,
        'predicted_next_month': predicted_next_month,
        'category_limits': category_limits_dict,
        'advice': advice,
        'smart_insights': smart_insights,
        'association_rules': association_rules,
        'spending_classification': spending_classification,
    }

    return jsonify(result)


# API endpoint for importance classification only
@app.route('/importance-classification', methods=['POST'])
def importance_classification_endpoint():
    data = request.json

    if data.get('password') != FLASK_PASSWORD:
        return jsonify({'error': 'Unauthorized'}), 401

    if 'all_expenses' not in data:
        return jsonify({'error': 'Missing required data: all_expenses'}), 400

    all_expenses = pd.DataFrame(data['all_expenses'])
    all_expenses['date'] = pd.to_datetime(all_expenses['date'])

    importance_classification = []
    importance_random_forest_classification(all_expenses, importance_classification)

    return jsonify({'importance_classification': importance_classification})


if __name__ == '__main__':
    app.run(port=5000, debug=True)
