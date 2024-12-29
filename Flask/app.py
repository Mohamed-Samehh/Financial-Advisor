from flask import Flask, request, jsonify
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.linear_model import LinearRegression
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler, PolynomialFeatures

app = Flask(__name__)


# Assign limits to categories based on priority
def assign_limits(categories, allowed_spending):
    categories['weight'] = (categories['priority'].count() + 1) - categories['priority']
    categories['limit'] = (categories['weight'] / categories['weight'].sum()) * allowed_spending

    total_calculated = categories['limit'].sum()
    rounding_error = allowed_spending - total_calculated

    categories.at[categories['weight'].idxmax(), 'limit'] += rounding_error

    return categories[['name', 'limit']]


# Predict total spending for the current month using daily average
def predictive_insights(expenses):
    expenses['date'] = pd.to_datetime(expenses['date'])
    total_days_in_month = expenses['date'].dt.daysinmonth.max()
    last_expense_day = expenses['date'].max().day

    if last_expense_day < 30:
        days_elapsed = (expenses['date'].max() - expenses['date'].min()).days + 1
        if days_elapsed > 0:
            average_daily_spending = expenses['amount'].sum() / days_elapsed
            remaining_days = total_days_in_month - days_elapsed
            predicted_remaining_spending = average_daily_spending * remaining_days
            predicted_total_spending = expenses['amount'].sum() + predicted_remaining_spending
            return round(predicted_total_spending, 2)
    return None


# Generate weights with exponential decay
def generate_weights(length, decay_factor):
    return [decay_factor ** (length - i - 1) for i in range(length)]


# Predict spending using weighted average
def weighted_average(all_expenses, decay_factor=0.95):
    all_expenses['date'] = pd.to_datetime(all_expenses['date'])
    all_expenses['month'] = all_expenses['date'].dt.month
    all_expenses['year'] = all_expenses['date'].dt.year

    monthly_spending = all_expenses.groupby(['year', 'month'])['amount'].sum().reset_index()
    if len(monthly_spending) >= 3:
        weights = generate_weights(len(monthly_spending), decay_factor)
        weighted_avg = (monthly_spending['amount'] * weights).sum() / sum(weights)
        return round(weighted_avg, 2)
    return None


# Predict spending using weighted linear regression
def linear_regression(all_expenses, decay_factor=0.95, degree=2):
    all_expenses['date'] = pd.to_datetime(all_expenses['date'])
    all_expenses['month'] = all_expenses['date'].dt.month
    all_expenses['year'] = all_expenses['date'].dt.year

    monthly_spending = all_expenses.groupby(['year', 'month'])['amount'].sum().reset_index()
    if len(monthly_spending) >= 3:
        monthly_spending['month_num'] = monthly_spending['year'] * 12 + monthly_spending['month']
        X = monthly_spending[['month_num']].values
        y = monthly_spending['amount'].values

        weights = generate_weights(len(y), decay_factor)

        model = Pipeline([
            ('poly', PolynomialFeatures(degree=degree)),
            ('reg', LinearRegression())
        ])
        model.fit(X, y, reg__sample_weight=weights)

        next_month_num = monthly_spending['month_num'].max() + 1
        predicted_spending = model.predict([[next_month_num]])[0]
        return round(predicted_spending, 2)
    return None


# Combine weighted average and linear regression for final prediction
def blended_prediction(all_expenses, alpha=0.9):
    weighted_avg = weighted_average(all_expenses)
    linear_pred = linear_regression(all_expenses)

    if weighted_avg is not None and linear_pred is not None:
        return round(alpha * weighted_avg + (1 - alpha) * linear_pred, 2)
    return weighted_avg or linear_pred


# Behavioral clustering using KMeans to identify spending patterns
def kmeans_clustering(expenses, smart_insights):
    scaler = StandardScaler()
    expenses['normalized_amount'] = scaler.fit_transform(expenses[['amount']])

    kmeans = KMeans(n_clusters=3, random_state=42)
    clusters = kmeans.fit_predict(expenses[['normalized_amount']])
    expenses['cluster'] = clusters

    all_categories = set()

    for cluster in range(3):
        cluster_data = expenses[expenses['cluster'] == cluster]
        unique_categories = cluster_data['category'].unique()

        if len(unique_categories) == 0 or len(unique_categories) > 4:
            continue

        all_categories.update(unique_categories)

    if all_categories:
        combined_categories = ', '.join(sorted(all_categories))
        smart_insights.append(f"Consider reducing expenses on {combined_categories}, as they show patterns of higher spending.")


# Analyze category spending variability
def analyze_spending_variability(expenses, smart_insights, min_expenses_threshold=2):
    category_expense_counts = expenses['category'].value_counts()
    valid_categories = category_expense_counts[category_expense_counts >= min_expenses_threshold].index

    # Calculate standard deviation for valid categories
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

    if (weekday_counts >= 3).any():
        weekday_spending = expenses.groupby('day_of_week')['amount'].mean().reindex(
            ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
        )
        peak_day = weekday_spending.idxmax()
        smart_insights.append(f"You tend to spend the most on {peak_day}s. Plan ahead!")


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
    allowed_spending = monthly_budget - goal_amount
    distinct_all_expenses = all_expenses[~all_expenses.index.isin(expenses.index)]

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

    predicted_next_month_weighted = weighted_average(all_expenses) if len(expenses) >= 10 and len(distinct_all_expenses) >= 10 else None
    # predicted_next_month_linear = linear_regression(all_expenses) if len(expenses) >= 10 and len(distinct_all_expenses) >= 10 else None
    predicted_next_month_linear = blended_prediction(all_expenses) if len(expenses) >= 10 and len(distinct_all_expenses) >= 10 else None

    if len(expenses) >= 10:
        kmeans_clustering(expenses, smart_insights)

    if len(expenses) >= 10 and len(expenses['category'].unique()) >= 3:
        analyze_spending_variability(expenses, smart_insights, min_expenses_threshold=2)

    if len(expenses) >= 10 and len(distinct_all_expenses) >= 10 and len(expenses['category'].unique()) >= 3:
        analyze_spending_deviations(expenses, distinct_all_expenses, smart_insights)

    if len(expenses) >= 10:
        day_of_week_analysis(expenses, smart_insights)

    # Prepare results for API response
    category_limits_dict = category_limits.to_dict(orient='records')

    result = {
        'predicted_current_month': predicted_current_month,
        'predicted_next_month_weighted': predicted_next_month_weighted,
        'predicted_next_month_linear': predicted_next_month_linear,
        'category_limits': category_limits_dict,
        'advice': advice,
        'smart_insights': smart_insights,
    }

    return jsonify(result)


if __name__ == '__main__':
    app.run(port=5000, debug=True)
