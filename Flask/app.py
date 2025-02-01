from flask import Flask, request, jsonify
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

app = Flask(__name__)

FLASK_PASSWORD = "Y7!mK4@vW9#qRp$2" # Require a password as a layer of security

# Assign limits to categories based on priority
def assign_limits(categories, allowed_spending):
    categories['weight'] = (categories['priority'].count() + 1) - categories['priority']
    categories['limit'] = (categories['weight'] / categories['weight'].sum()) * allowed_spending
    return categories[['name', 'limit']]


# Predict total spending for the current month using daily average
def predictive_insights(expenses):
    expenses['date'] = pd.to_datetime(expenses['date'])
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
    distinct_all_expenses['date'] = pd.to_datetime(distinct_all_expenses['date'])
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
    expenses['date'] = pd.to_datetime(expenses['date'])
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
    }

    return jsonify(result)


if __name__ == '__main__':
    app.run(port=5000, debug=True)
