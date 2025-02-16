from flask import Flask, request, jsonify
import pandas as pd
import numpy as np
import calendar
from sklearn.linear_model import LinearRegression
from sklearn.metrics import r2_score
from sklearn.cluster import KMeans
from mlxtend.frequent_patterns import apriori
from itertools import combinations
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


# # Generate weights with exponential decay
# def generate_weights(length, decay_factor=0.9):
#     return [decay_factor ** (length - i - 1) for i in range(length)]


# # Predict next month spending using Weighted Average method
# def weighted_average(distinct_all_expenses, expenses, predicted_current_month):
#     distinct_all_expenses['month'] = distinct_all_expenses['date'].dt.month
#     distinct_all_expenses['year'] = distinct_all_expenses['date'].dt.year

#     current_year = expenses['date'].max().year
#     current_month = expenses['date'].max().month

#     monthly_spending = distinct_all_expenses.groupby(['year', 'month'])['amount'].sum().reset_index()

#     if predicted_current_month is not None:
#         monthly_spending = pd.concat([
#             monthly_spending,
#             pd.DataFrame({'year': [current_year], 'month': [current_month], 'amount': [predicted_current_month]})
#         ], ignore_index=True)

#     if len(monthly_spending) >= 2:
#         weights = generate_weights(len(monthly_spending))
#         weighted_avg = (monthly_spending['amount'] * weights).sum() / sum(weights)
#         return round(weighted_avg, 2)

#     return None


# Predict next x months spending using Linear Regression
def linear_regression(distinct_all_expenses, expenses, predicted_current_month, predictions, month_num=12, accuracy_threshold=0.5, correlation_threshold=0.5):
    distinct_all_expenses['month'] = distinct_all_expenses['date'].dt.month
    distinct_all_expenses['year'] = distinct_all_expenses['date'].dt.year
    
    current_year = expenses['date'].max().year
    current_month = expenses['date'].max().month
    
    monthly_spending = distinct_all_expenses.groupby(['year', 'month'])['amount'].sum().reset_index()

    if len(monthly_spending) >= 2:
        if predicted_current_month is not None:
            monthly_spending = pd.concat([
                monthly_spending,
                pd.DataFrame({'year': [current_year], 'month': [current_month], 'amount': [predicted_current_month]})
            ], ignore_index=True)

            monthly_spending['time_index'] = range(1, len(monthly_spending) + 1)
            X = monthly_spending[['time_index']]
            y = monthly_spending['amount']

            scaler = StandardScaler()
            X_scaled = scaler.fit_transform(X)

            model = LinearRegression()
            model.fit(X_scaled, y)

            y_pred = model.predict(X_scaled)
            r2 = r2_score(y, y_pred)
            correlation = np.corrcoef(y, y_pred)[0, 1]

            if r2 >= accuracy_threshold and correlation >= correlation_threshold:
                next_year, next_month = (current_year, current_month + 1) if current_month < 12 else (current_year + 1, 1)

                next_time_index = X['time_index'].max() + 1
                for _ in range(month_num):
                    next_time_index_df = pd.DataFrame([[next_time_index]], columns=['time_index'])
                    next_time_index_scaled = scaler.transform(next_time_index_df)
                    prediction = model.predict(next_time_index_scaled)[0]
                    
                    predictions.append({
                        'year': next_year,
                        'month': calendar.month_name[next_month],
                        'predicted_spending': round(float(prediction), 2),
                        'accuracy': r2,
                        'correlation': correlation
                    })

                    next_month += 1
                    if next_month > 12:
                        next_month = 1
                        next_year += 1

                    next_time_index += 1


# KMenas clustering to group "expenses" based on amount spent and frequency (in the highest spending cluster)
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
        combined_categories = "', '".join(top_categories)
        smart_insights.append(f"Consider monitoring expenses in '{combined_categories}', as they show a high spending pattern.")


# KMeans clustering to group "categories" based on total spending
def spending_kmeans_clustering(expenses, spending_clustering):
    total_spent = expenses.groupby('category')['amount'].sum().reset_index(name='total_spent')

    if len(total_spent) >= 3:
        scaler = StandardScaler()
        total_spent['normalized_total_spent'] = scaler.fit_transform(total_spent[['total_spent']])

        kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
        total_spent['cluster'] = kmeans.fit_predict(total_spent[['normalized_total_spent']])

        cluster_averages = total_spent.groupby('cluster')['normalized_total_spent'].mean().sort_values(ascending=False)
        cluster_labels = {cluster: label for cluster, label in 
                          zip(cluster_averages.index, ['High', 'Moderate', 'Low'])}

        total_spent['spending_group'] = total_spent['cluster'].map(cluster_labels)

        sorted_spending = total_spent.sort_values(by='spending_group', key=lambda x: x.map({'High': 1, 'Moderate': 2, 'Low': 3}))

        spending_clustering.append({
            'spending_group': [
                {'category': row['category'], 'spending_group': row['spending_group']}
                for _, row in sorted_spending.iterrows()
            ]
        })


# KMeans clustering to group "categories" based on frequency
def frequency_kmeans_clustering(expenses, frequency_clustering):
    frequency = expenses.groupby('category').size().reset_index(name='count')

    if len(frequency) >= 3:
        scaler = StandardScaler()
        frequency['normalized_count'] = scaler.fit_transform(frequency[['count']])

        kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
        frequency['cluster'] = kmeans.fit_predict(frequency[['normalized_count']])

        cluster_averages = frequency.groupby('cluster')['normalized_count'].mean().sort_values(ascending=False)
        cluster_labels = {cluster: label for cluster, label in 
                          zip(cluster_averages.index, ['High', 'Moderate', 'Low'])}
        
        frequency['frequency_group'] = frequency['cluster'].map(cluster_labels)

        sorted_frequency = frequency.sort_values(by='frequency_group', key=lambda x: x.map({'High': 1, 'Moderate': 2, 'Low': 3}))

        frequency_clustering.append({
            'frequency_group': [
                {'category': row['category'], 'frequency_group': row['frequency_group']}
                for _, row in sorted_frequency.iterrows()
            ]
        })


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


# Label category importance based on rules
def Rule_Based_labeling(past_expenses, labeled_categories):
    past_expenses['year_month'] = past_expenses['date'].dt.strftime('%Y-%m')
    
    monthly_sums = past_expenses.groupby(['year_month', 'category'])['amount'].sum()
    category_average = monthly_sums.groupby('category').mean()

    monthly_frequency = past_expenses.groupby(['year_month', 'category']).size()
    category_frequency = monthly_frequency.groupby('category').mean()

    monthly_std = past_expenses.groupby(['year_month', 'category'])['amount'].std()
    category_consistency = monthly_std.groupby('category').mean()

    category_stats = pd.DataFrame({
        'total_spent': category_average,
        'frequency': category_frequency,
        'consistency': category_consistency
    })

    conditions = [
        # Category is considered "Essential" if total spending is in the top 25% (high spending)
        (category_stats['total_spent'] > category_stats['total_spent'].quantile(0.75)),

        # Category is considered "Essential" if frequency of spending is in the top 25% (high usage)
        (category_stats['frequency'] > category_stats['frequency'].quantile(0.75)),

        # Category is considered "Moderate" if spending and frequency are both in the middle 50% range
        (category_stats['total_spent'].between(category_stats['total_spent'].quantile(0.25), category_stats['total_spent'].quantile(0.75))) &  
        (category_stats['frequency'].between(category_stats['frequency'].quantile(0.25), category_stats['frequency'].quantile(0.75))),

        # Category is considered "Non-Essential" if spending consistency is low (low standard deviation)
        (category_stats['consistency'] < category_stats['consistency'].quantile(0.25)),

        # Category is considered "Essential" if total spending is extremely high (top 10%) but rarely spent on (low frequency)
        (category_stats['total_spent'] > category_stats['total_spent'].quantile(0.90)) &  
        (category_stats['frequency'] <= category_stats['frequency'].quantile(0.25))
    ]

    labels = ['Essential', 'Essential', 'Moderate', 'Non-Essential', 'Essential']

    category_stats['predicted_importance'] = 'Non-Essential'
    for i in range(len(conditions)):
        category_stats.loc[conditions[i], 'predicted_importance'] = labels[i]

    category_importance = category_stats[['predicted_importance']].reset_index()

    importance_order = {'Essential': 0, 'Moderate': 1, 'Non-Essential': 2}
    category_importance['importance_order'] = category_importance['predicted_importance'].map(importance_order)
    category_importance = category_importance.sort_values('importance_order').drop(columns=['importance_order'])

    labeled_categories.append({
        'predicted_importance': [
            {'category': row[0], 'predicted_importance': row[1]}
            for row in category_importance[['category', 'predicted_importance']].values.tolist()
        ]
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
def analyze_spending_deviations(expenses, distinct_all_expenses, smart_insights):
    distinct_all_expenses['year_month'] = distinct_all_expenses['date'].dt.strftime('%Y-%m')
    monthly_sums = distinct_all_expenses.groupby(['year_month', 'category'])['amount'].sum()
    category_average = monthly_sums.groupby('category').mean()

    current_month_sum = expenses.groupby('category')['amount'].sum()

    if not expenses.empty:
        days_so_far = expenses['date'].dt.day.max()
        total_days_in_month = expenses['date'].dt.to_period('M').max().days_in_month
        estimated_current_month = (current_month_sum / days_so_far) * total_days_in_month
        current_month_sum = estimated_current_month

        deviations = (current_month_sum - category_average).sort_values(ascending=False)

        if not deviations.empty:
            largest_increase_category = deviations.idxmax()
            largest_decrease_category = deviations.idxmin()

            if deviations[largest_increase_category] > 0 and deviations[largest_decrease_category] < 0:
                smart_insights.append(
                    f"Spending on '{largest_increase_category}' increased the most, while spending on '{largest_decrease_category}' decreased the most compared to your usual spending."
                )
            else:
                if deviations[largest_increase_category] > 0:
                    smart_insights.append(
                        f"Spending on '{largest_increase_category}' increased the most compared to your usual spending."
                    )
                if deviations[largest_decrease_category] < 0:
                    smart_insights.append(
                        f"Spending on '{largest_decrease_category}' decreased the most compared to your usual spending."
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
    predictions = []
    spending_clustering = []
    frequency_clustering = []
    association_rules = []
    

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

    # predicted_next_month = weighted_average(distinct_all_expenses, expenses, predicted_current_month) if len(distinct_all_expenses) >= 5 and len(expenses) >= 5 else None
    linear_regression(distinct_all_expenses, expenses, predicted_current_month, predictions) if len(distinct_all_expenses) >= 5 and len(expenses) >= 5 else None
    

    if len(expenses) >= 5:
        kmeans_clustering(expenses, smart_insights)
        spending_kmeans_clustering(expenses, spending_clustering)
        frequency_kmeans_clustering(expenses, frequency_clustering)

    if len(expenses) >= 30:
        get_association_rules(expenses, association_rules, min_support=0.1, min_confidence=0.3, min_lift=1.0)
    elif len(expenses) >= 20:
        get_association_rules(expenses, association_rules, min_support=0.15, min_confidence=0.3, min_lift=1.0)
    elif len(expenses) >= 10:
        get_association_rules(expenses, association_rules, min_support=0.25, min_confidence=0.3, min_lift=1.0)

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
        'predictions': predictions,
        'category_limits': category_limits_dict,
        'advice': advice,
        'smart_insights': smart_insights,
        'spending_clustering': spending_clustering,
        'frequency_clustering': frequency_clustering,
        'association_rules': association_rules,
    }

    return jsonify(result)


# API endpoint for rule-based labeling only
@app.route('/label_categories', methods=['POST'])
def labeling_endpoint():
    data = request.json

    if data.get('password') != FLASK_PASSWORD:
        return jsonify({'error': 'Unauthorized'}), 401

    if 'past_expenses' not in data:
        return jsonify({'error': 'Missing required data: past_expenses'}), 400

    past_expenses = pd.DataFrame(data['past_expenses'])
    past_expenses['date'] = pd.to_datetime(past_expenses['date'])

    labaled_categories = []
    if len(past_expenses) >= 5:
        Rule_Based_labeling(past_expenses, labaled_categories)

    return jsonify({'labaled_categories': labaled_categories})


if __name__ == '__main__':
    app.run(port=5000, debug=True)
