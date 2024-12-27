from flask import Flask, request, jsonify
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
import math

app = Flask(__name__)


# Assign limits to categories
def assign_limits(categories, monthly_budget, goal_amount):
    categories['weight'] = (categories['priority'].count() + 1) - categories['priority']
    categories['limit'] = (categories['weight'] / categories['weight'].sum()) * (monthly_budget - goal_amount)
    return categories[['name', 'limit']]


# Predictive insights based on current daily spending (Minimum 10 records)
def predictive_insights(expenses, smart_insights):
    expenses['date'] = pd.to_datetime(expenses['date'])

    # Calculate the number of days that have passed between the first and last expense
    total_days = (expenses['date'].max() - expenses['date'].min()).days + 1

    if total_days > 0:
        average_daily_spending = expenses['amount'].sum() / total_days
        predicted_spending = average_daily_spending * 30
        rounded_spending = math.ceil(predicted_spending)
        smart_insights.append(f"Next month's spending is predicted to be around E£{rounded_spending:,.0f}.")


# Day-of-week spending analysis (Minimum 30 records)
def day_of_week_analysis(all_expenses, smart_insights):
    all_expenses['date'] = pd.to_datetime(all_expenses['date'])
    all_expenses['day_of_week'] = all_expenses['date'].dt.day_name()

    weekday_counts = all_expenses['day_of_week'].value_counts().reindex(
        ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'], fill_value=0
    )

    if (weekday_counts >= 5).any():
        weekday_spending = all_expenses.groupby('day_of_week')['amount'].mean().reindex(
            ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
        )
        peak_day = weekday_spending.idxmax()
        smart_insights.append(f"You tend to spend the most on {peak_day}s. Plan ahead!")


# Category-based spending trends analysis (Minimum 20 records and 3 unique categories)
def category_trends_analysis(expenses, all_expenses, smart_insights):

    #zawed 3adad minimum expenses le kol category fehom
    category_variability = expenses.groupby('category')['amount'].std().sort_values(ascending=False)

    if not category_variability.empty:
        most_variable_category = category_variability.idxmax()
        if pd.notna(most_variable_category):
            smart_insights.append(f"Spending in '{most_variable_category}' varies the most. Keep an eye on it!")

    if len(all_expenses) >= 20 and len(all_expenses['category'].unique()) >= 3:
        category_average = all_expenses.groupby('category')['amount'].mean()
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


# Behavioral clustering (Minimum 50 records)
def behavioral_clustering(expenses, smart_insights):
    scaler = StandardScaler()
    expenses['normalized_amount'] = scaler.fit_transform(expenses[['amount']])

    kmeans = KMeans(n_clusters=3, random_state=42)
    clusters = kmeans.fit_predict(expenses[['normalized_amount']])
    expenses['cluster'] = clusters

    all_categories = set()

    for cluster in range(3):
        cluster_data = expenses[expenses['cluster'] == cluster]
        unique_categories = cluster_data['category'].unique()

        if len(unique_categories) == 0 or len(unique_categories) > 5:
            continue

        all_categories.update(unique_categories)

    if all_categories:
        combined_categories = ', '.join(sorted(all_categories))
        smart_insights.append(f"Consider reducing expenses on {combined_categories}, as they show patterns of higher spending.")


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
    category_limits = assign_limits(categories, monthly_budget, goal_amount)
    expenses = expenses.merge(category_limits, left_on='category', right_on='name', how='left')

    advice = []
    smart_insights = []

    if total_spent > monthly_budget:
        advice.append("You've exceeded your monthly budget!")

    if goal_amount > 0:
        if total_spent > (monthly_budget - goal_amount):
            advice.append("You've spent more than your goal allows.")
    else:
        advice.append('No goal was set for this month.')

    over_budget_categories = expenses[expenses['amount'] > expenses['limit']]['category'].unique()

    if len(over_budget_categories) > 0:
        combined_categories = "', '".join(over_budget_categories)
        advice.append(f"You've exceeded the limit for '{combined_categories}'. Stop spending to avoid risks.")

    if len(expenses) >= 10:
        predictive_insights(expenses, smart_insights)

    if len(all_expenses) >= 15:
        day_of_week_analysis(all_expenses, smart_insights)

    if len(expenses) >= 15 and len(expenses['category'].unique()) >= 3:
        category_trends_analysis(expenses, all_expenses, smart_insights)

    if len(expenses) >= 20:
        behavioral_clustering(expenses, smart_insights)

    # Prepare results
    category_limits_dict = category_limits.to_dict(orient='records')

    result = {
        'category_limits': category_limits_dict,
        'advice': advice,
        'smart_insights': smart_insights,
    }

    return jsonify(result)


if __name__ == '__main__':
    app.run(port=5000, debug=True)
