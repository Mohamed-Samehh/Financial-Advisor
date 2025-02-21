from flask import Flask, request, jsonify
from ml_models import linear_regression, category_linear_regression, kmeans_clustering, spending_kmeans_clustering, frequency_kmeans_clustering, get_association_rules, Rule_Based_labeling
from business_logic import assign_limits, predictive_insights, analyze_spending_variability, analyze_spending_deviations, day_of_week_analysis
import pandas as pd
from datetime import datetime
import requests
import json
from dotenv import load_dotenv
import os

app = Flask(__name__)

load_dotenv()
FLASK_PASSWORD = os.getenv("FLASK_PASSWORD")

# API endpoint responsible for the whole analyzing
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
    goal_row = pd.DataFrame([{'name': 'Goal', 'limit': goal_amount}])
    category_limits = pd.concat([goal_row, category_limits], ignore_index=True)

    category_totals = expenses.groupby('category')['amount'].sum().reset_index()
    category_totals = category_totals.merge(category_limits, left_on='category', right_on='name', how='left')

    advice = []
    smart_insights = []
    predictions = []
    category_predictions = {}
    expenses_clustering = []
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
                advice.append("Your spending is estimated to exceed your monthly budget.")
        
        elif predicted_current_month is not None and predicted_current_month > monthly_budget:
            advice.append("Your spending is estimated to exceed your monthly budget.")

        elif predicted_current_month is not None and predicted_current_month > allowed_spending:
            advice.append("Your spending is estimated to be more than what your goal allows.")

    else:
        advice.append('No goal was set for this month.')

        if total_spent > monthly_budget:
            advice.append("You've exceeded your monthly budget!")

        elif predicted_current_month is not None and predicted_current_month > monthly_budget:
            advice.append("Your spending is estimated to exceed your monthly budget.")


    over_budget_categories = category_totals[category_totals['amount'] > category_totals['limit']]

    if len(over_budget_categories) > 0:
        combined_categories = "', '".join(over_budget_categories['category'])
        advice.append(f"You're overspending on '{combined_categories}'. Stop spending to avoid risks.")

    # predicted_next_month = weighted_average(distinct_all_expenses, expenses, predicted_current_month) if len(distinct_all_expenses) >= 5 and len(expenses) >= 5 else None
    
    if len(distinct_all_expenses) >= 5:
        linear_regression(distinct_all_expenses, predictions)
        category_linear_regression(distinct_all_expenses, category_predictions)
    
    if len(expenses) >= 5:
        kmeans_clustering(expenses, smart_insights, expenses_clustering)
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
        'category_predictions': category_predictions,
        'category_limits': category_limits_dict,
        'advice': advice,
        'smart_insights': smart_insights,
        'expenses_clustering': expenses_clustering,
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


# API endpoint for calling LLM "Gemini Flash 2.0 Experimental"
@app.route('/chat', methods=['POST'])
def chat():
    if request.json.get('password') != FLASK_PASSWORD:
        return jsonify({'error': 'Unauthorized'}), 401
    
    user_message = request.json.get("message")
    api_key = request.json.get("api_key")
    user_name = request.json.get("name")
    budget = request.json.get("budget")
    goal_name = request.json.get("goal_name")
    goal_amount = request.json.get("goal_amount")
    categories = request.json.get("categories")
    total_spent = request.json.get("total_spent")
    last_day_month = request.json.get("last_day_month")
    daily_expenses = request.json.get("daily_expenses")

    if not user_message or not api_key:
        return jsonify({"error": "Message and API key are required"}), 400

    # Default values if not provided
    user_name = user_name if user_name else "User"
    budget_text = f"Your monthly budget is {budget} EGP." if budget else "You haven't provided a budget."
    goal_text = f"Your goal is to save E£{goal_amount} EGP for '{goal_name}' from your monthly budget." if goal_amount else "No savings goal set."
    spent_text = f"You've spent {total_spent} EGP so far this month." if total_spent else "No spending this month."

    if daily_expenses:
        daily_spending_text = "Here is a breakdown of your daily spending for the current month:\n"
        for day, spent in daily_expenses.items():
            daily_spending_text += f"- **{datetime.strptime(day, '%Y-%m-%d').strftime('%B %d')}:** {spent} EGP\n"
    else:
        daily_spending_text = "No daily spending data available."

    if categories:
        category_text = "Here is a breakdown of your spending by category:\n"
        for category in categories:
            category_text += f"- **{category['name']}** (Priority {category['priority']}): {category['total_spent']} EGP\n"
    else:
        category_text = "No category spending data available."

    # Construct the system prompt
    system_prompt = (
        f"You are a financial assistant chatbot specializing in budgeting, spending analysis, savings strategies, and investment insights. "
        f"All recommendations must be tailored to Egypt’s economic conditions, and all currency values should be in Egyptian Pounds (EGP). "
        f"Your responses should be structured, practical, and easy to understand. Always provide a complete response in a single message.\n\n"

        f"### System Purpose:\n"
        f"The user sets a savings goal, representing the amount of money they need to have left by the end of the current month. "
        f"Your role is to analyze their budget, spending patterns, and financial goals to help them achieve this target. "
        f"Suggest realistic adjustments, cost-cutting strategies, and optimized savings methods based on their financial data.\n"
        f"Additionally, provide information on banking options in Egypt, including savings accounts, interest rates, certificates of deposit (CDs), and investment plans.\n\n"

        f"### Date Handling Rules:\n"
        f"- Do not assume the current date unless explicitly provided by the user.\n"
        f"- When analyzing recent spending trends, always refer to the **last recorded date** from the daily spending data.\n\n"

        f"### User's Financial Overview:\n"
        f"- **Name:** {user_name}\n"
        f"- **Monthly Budget:** {budget_text}\n"
        f"- **Goal:** {goal_text}\n"
        f"- **Total Spent This Month:** {spent_text}\n"
        f"- **Current Budget Cycle Ends On:** {last_day_month}\n\n"

        f"{daily_spending_text}\n\n"
        f"{category_text}\n\n"

        f"### Banking Data:\n"
        f"- Provide details on savings and investment accounts offered by Egyptian banks.\n"
        f"- Compare interest rates on savings accounts and fixed deposits.\n"
        f"- Offer insights on available certificates of deposit (CDs), their interest rates, and terms.\n\n"

        f"### Important Notes on Categories:\n"
        f"Lower priority values indicate higher importance, with 1 being the most critical.\n\n"

        f"### Response Guidelines:\n"
        f"- Ensure all financial recommendations are aligned with Egypt’s cost of living, banking options, and inflation trends.\n"
        f"- Provide structured, actionable insights based on the user's budget and spending behavior.\n"
        f"- Never split responses into multiple messages. Always provide a complete answer in a single response.\n"
        f"- If the user asks a question unrelated to finance, respond with: 'I am a financial assistant and can only answer finance-related questions.'"
    )

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost:4200/",
        "X-Title": "Financial Advisor"
    }

    data = json.dumps({
        "model": "google/gemini-2.0-flash-exp:free",
         "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message}
        ]
    })

    response = requests.post(
        url="https://openrouter.ai/api/v1/chat/completions",
        headers=headers,
        data=data
    )

    if response.status_code != 200:
        return jsonify({"error": "Failed to fetch response", "details": response.text}), response.status_code

    return jsonify(response.json())


if __name__ == '__main__':
    app.run(port=5000, debug=True)
