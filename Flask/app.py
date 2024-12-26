from flask import Flask, request, jsonify
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

app = Flask(__name__)

@app.route('/analysis', methods=['POST'])
def analyze_expenses():
    data = request.json

    if not all(key in data for key in ['expenses', 'categories', 'monthly_budget', 'goal_amount', 'total_spent']):
        return jsonify({'error': 'Missing required data'}), 400

    categories = pd.DataFrame(data['categories'])
    expenses = pd.DataFrame(data['expenses'])
    all_expenses = pd.DataFrame(data['all_expenses'])
    monthly_budget = data['monthly_budget']
    goal_amount = data['goal_amount']
    total_spent = data['total_spent']

    # Assign limits to categories
    expenses['priority'] = expenses['category'].map(dict(zip(categories['name'], categories['priority']))).fillna(-1)
    def assign_limits(categories, monthly_budget):
        categories['weight'] = (categories['priority'].count() + 1) - categories['priority'] # Bene3kes 3ashan 2a2al priority ya5od akbar weight
        categories['limit'] = (categories['weight'] / categories['weight'].sum()) * (monthly_budget - goal_amount)
        return categories[['name', 'limit']]

    category_limits = assign_limits(categories, monthly_budget)
    expenses = expenses.merge(category_limits, left_on='category', right_on='name', how='left')

    advice = []
    smart_insights = []

    if total_spent > monthly_budget:
        advice.append("You've exceeded your monthly budget!")

    if goal_amount > 0:
        if total_spent > (monthly_budget - goal_amount):
            advice.append("You've spent more than your savings goal allows.")
    else:
        advice.append('No goal was set for this month.')

    for _, row in expenses.iterrows():
        if row['amount'] > row['limit']:
            advice.append(f"You've exceeded the limit for {row['category']}. Stop spending to avoid risks.")

    # Predictive insights
    if len(expenses) > 0:
        expenses['date'] = pd.to_datetime(expenses['date'])

        # Calculate the average daily spending for the current month
        total_days = (expenses['date'].max() - expenses['date'].min()).days + 1
        average_daily_spending = expenses['amount'].sum() / total_days
        predicted_spending = average_daily_spending * 30
        smart_insights.append(f"Next month's spending is predicted be around E£{predicted_spending:,.0f}.")

    # Day-of-week spending analysis
    if not all_expenses.empty:
        all_expenses['date'] = pd.to_datetime(all_expenses['date'])
        all_expenses['day_of_week'] = all_expenses['date'].dt.day_name()

        weekday_spending = all_expenses.groupby('day_of_week')['amount'].sum().reindex(
            ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
        )
        peak_day = weekday_spending.idxmax()
        smart_insights.append(f"Your highest spending is usually on {peak_day}. Plan for it!")

    # Category-based spending trends analysis
    if not expenses.empty:
        category_variability = expenses.groupby('category')['amount'].std().sort_values(ascending=False)

        # Identify the category with the most unstable spending
        if not category_variability.empty:
            most_variable_category = category_variability.idxmax()
            smart_insights.append(f"Your spending in '{most_variable_category}' varies the most. Keep an eye on it!")

        # Identify unexpected spending patterns by comparing to past average
        if not all_expenses.empty:
            category_average = all_expenses.groupby('category')['amount'].mean()
            current_month_average = expenses.groupby('category')['amount'].mean()

            deviations = (current_month_average - category_average).sort_values(ascending=False)
            if not deviations.empty:
                largest_increase_category = deviations.idxmax()
                largest_decrease_category = deviations.idxmin()

                if deviations[largest_increase_category] > 0:
                    smart_insights.append(
                        f"Spending in the '{largest_increase_category}' category increased significantly compared to your usual spending."
                    )
                if deviations[largest_decrease_category] < 0:
                    smart_insights.append(
                        f"Spending in the '{largest_decrease_category}' category decreased significantly compared to your usual spending."
                    )

    # Behavioral clustering
    MIN_EXPENSES_FOR_CLUSTERING = 20

    if len(expenses) >= MIN_EXPENSES_FOR_CLUSTERING:
        scaler = StandardScaler()
        expenses['normalized_amount'] = scaler.fit_transform(expenses[['amount']])

        kmeans = KMeans(n_clusters=3, random_state=42)
        clusters = kmeans.fit_predict(expenses[['normalized_amount']])
        expenses['cluster'] = clusters

        all_categories = set()

        for cluster in range(3):
            cluster_data = expenses[expenses['cluster'] == cluster]
            unique_categories = cluster_data['category'].unique()

            # Skip clusters with no categories or too many unique categories
            if len(unique_categories) == 0 or len(unique_categories) > 5:
                continue

            all_categories.update(unique_categories)

        if all_categories:
            combined_categories = ', '.join(sorted(all_categories))
            smart_insights.append(f"Consider reducing expenses on {combined_categories}, as they show patterns of higher spending.")

    # Prepare results
    category_limits_dict = category_limits.to_dict(orient='records')

    result = {
        'advice': advice,
        'category_limits': category_limits_dict,
        'smart_insights': smart_insights,
    }

    return jsonify(result)

if __name__ == '__main__':
    app.run(port=5000)
