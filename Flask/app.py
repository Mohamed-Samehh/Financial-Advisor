from flask import Flask, request, jsonify
import pandas as pd
from sklearn.cluster import KMeans
from statsmodels.tsa.holtwinters import ExponentialSmoothing
from sklearn.preprocessing import StandardScaler

app = Flask(__name__)

@app.route('/analysis', methods=['POST'])
def analyze_expenses():
    data = request.json

    if 'expenses' not in data or 'categories' not in data:
        return jsonify({'error': 'Missing expenses or categories data'}), 400

    categories = pd.DataFrame(data['categories'])
    expenses = pd.DataFrame(data['expenses'])
    monthly_budget = data['monthly_budget']

    # Assign limits to categories
    expenses['priority'] = expenses['category'].map(dict(zip(categories['name'], categories['priority']))).fillna(-1)
    def assign_limits(categories, monthly_budget):
        categories['weight'] = (categories['priority'].count() + 1) - categories['priority']
        categories['limit'] = (categories['weight'] / categories['weight'].sum()) * monthly_budget
        return categories[['name', 'limit']]

    category_limits = assign_limits(categories, monthly_budget)
    expenses = expenses.merge(category_limits, left_on='category', right_on='name', how='left')

    advice = []
    smart_insights = []

    # Spending exceeding limits
    for _, row in expenses.iterrows():
        if row['amount'] > row['limit']:
            advice.append(f"Spending in {row['category']} exceeded its limit.")

    # Behavioral clustering
    if len(expenses) > 0:
        scaler = StandardScaler()
        expenses['normalized_amount'] = scaler.fit_transform(expenses[['amount']])

        kmeans = KMeans(n_clusters=3, random_state=42)
        clusters = kmeans.fit_predict(expenses[['normalized_amount']])
        expenses['cluster'] = clusters

        for cluster in range(3):
            cluster_data = expenses[expenses['cluster'] == cluster]
            unique_categories = cluster_data['category'].unique()

            # Skip clusters with no categories or too many unique categories
            if len(unique_categories) == 0 or len(unique_categories) > 5:
                continue

            smart_insights.append(f"Consider cutting down on {', '.join(unique_categories)}.")

    # Predictive insights using only current month's expenses
    expenses_timeseries = expenses.groupby('date')['amount'].sum().reset_index()
    expenses_timeseries['date'] = pd.to_datetime(expenses_timeseries['date'])
    expenses_timeseries = expenses_timeseries.sort_values('date')
    expenses_timeseries = expenses_timeseries[expenses_timeseries['amount'] > 0]

    if len(expenses_timeseries) >= 12:
        try:
            model = ExponentialSmoothing(expenses_timeseries['amount'], seasonal='add', seasonal_periods=12)
            fit = model.fit()
            prediction = fit.forecast(1).iloc[0]
            smart_insights.append(f"Predicted total spending for next month: E£{prediction:.2f}.")
        except ValueError:
            smart_insights.append("Insufficient data for seasonal forecasting. No prediction available.")
    else:
        if len(expenses_timeseries) > 0:
            mean_spending = expenses_timeseries['amount'].mean()
            smart_insights.append(f"Predicted total spending for next month on average: E£{mean_spending:.2f}.")
        else:
            smart_insights.append("Not enough data to make a prediction.")

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
