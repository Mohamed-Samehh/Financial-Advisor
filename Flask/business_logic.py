import pandas as pd

# Assign limits to categories based on priority
def assign_limits(categories, allowed_spending):
    max_priority = categories['priority'].max()
    categories['weight'] = (max_priority + 1) - categories['priority']
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


# Analyze deviations in spending by comparing current trends with historical averages
def analyze_spending_deviations(expenses, distinct_all_expenses, smart_insights):
    distinct_all_expenses['year_month'] = distinct_all_expenses['date'].dt.to_period('M')
    distinct_all_expenses['day_of_month'] = distinct_all_expenses['date'].dt.day

    historical_spending_trend = (
        distinct_all_expenses.groupby(['year_month', 'category', 'day_of_month'])['amount'].sum()
        .groupby(['year_month', 'category'])
        .cumsum()
        .groupby(['category', 'day_of_month'])
        .mean()
        .unstack()
        .ffill(axis=1)
        .stack()
    )

    days_so_far = expenses['date'].dt.day.max()
    historical_reference = (
        historical_spending_trend[historical_spending_trend.index.get_level_values('day_of_month') == days_so_far]
        .groupby('category')
        .mean()
    )

    current_month_spending = expenses.groupby('category')['amount'].sum()
    historical_reference = historical_reference.reindex(current_month_spending.index, fill_value=0)
    deviations = (current_month_spending - historical_reference).sort_values(ascending=False)

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
