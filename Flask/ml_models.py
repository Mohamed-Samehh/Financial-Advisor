import pandas as pd
import numpy as np
import calendar
from sklearn.linear_model import LinearRegression
from sklearn.metrics import r2_score
from sklearn.cluster import KMeans
from mlxtend.frequent_patterns import apriori
from itertools import combinations
from sklearn.preprocessing import StandardScaler


# Predict next x months "Total" spending using Linear Regression
def linear_regression(distinct_all_expenses, predictions, month_num=12, accuracy_threshold=0.5, correlation_threshold=0.5):
    distinct_all_expenses['month'] = distinct_all_expenses['date'].dt.month
    distinct_all_expenses['year'] = distinct_all_expenses['date'].dt.year
    
    last_year = distinct_all_expenses['date'].max().year
    last_month = distinct_all_expenses['date'].max().month
    
    monthly_spending = distinct_all_expenses.groupby(['year', 'month'])['amount'].sum().reset_index()

    if len(monthly_spending) >= 3:
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
                next_year, next_month = (last_year, last_month + 1) if last_month < 12 else (last_year + 1, 1)

                next_time_index = X['time_index'].max() + 1
                for _ in range(month_num):
                    next_time_index_df = pd.DataFrame([[next_time_index]], columns=['time_index'])
                    next_time_index_scaled = scaler.transform(next_time_index_df)
                    prediction = model.predict(next_time_index_scaled)[0]
                    prediction = max(0, prediction)
                    
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


# Predict next x months "Category" spending using Linear Regression
def category_linear_regression(distinct_all_expenses, category_predictions, month_num=12, accuracy_threshold=0.5, correlation_threshold=0.5):
    distinct_all_expenses['year'] = distinct_all_expenses['date'].dt.year
    distinct_all_expenses['month'] = distinct_all_expenses['date'].dt.month

    last_year = distinct_all_expenses['date'].max().year
    last_month = distinct_all_expenses['date'].max().month

    for category, group in distinct_all_expenses.groupby('category'):
        monthly_spending = group.groupby(['year', 'month'])['amount'].sum().reset_index()

        if len(monthly_spending) >= 3:
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
                next_year, next_month = (last_year, last_month + 1) if last_month < 12 else (last_year + 1, 1)

                next_time_index = X['time_index'].max() + 1
                category_predictions[category] = []

                for _ in range(month_num):
                    next_time_index_df = pd.DataFrame([[next_time_index]], columns=['time_index'])
                    next_time_index_scaled = scaler.transform(next_time_index_df)
                    prediction = model.predict(next_time_index_scaled)[0]
                    prediction = max(0, prediction)

                    category_predictions[category].append({
                        'year': int(next_year),
                        'month': calendar.month_name[next_month],
                        'predicted_spending': round(float(prediction), 2),
                        'accuracy': float(r2),
                        'correlation': float(correlation)
                    })

                    next_month += 1
                    if next_month > 12:
                        next_month = 1
                        next_year += 1

                    next_time_index += 1


# KMenas clustering to group "expenses" based on amount spent and frequency (in the highest spending cluster)
def kmeans_clustering(expenses, smart_insights):
    scaler = StandardScaler()

    unique_values = expenses['amount'].nunique()

    if unique_values >= 3:
        expenses['normalized_amount'] = scaler.fit_transform(expenses[['amount']])
        kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
        clusters = kmeans.fit_predict(expenses[['normalized_amount']])
        expenses['cluster'] = clusters

        cluster_averages = expenses.groupby('cluster')['normalized_amount'].mean()
        highest_spending_cluster = cluster_averages.idxmax()

        highest_cluster_data = expenses[expenses['cluster'] == highest_spending_cluster]

        category_counts = highest_cluster_data['category'].value_counts()

        top_categories = category_counts.head(4).index.tolist()

        if top_categories:
            combined_categories = "', '".join(top_categories)
            smart_insights.append(f"Consider monitoring expenses in '{combined_categories}', as they have the most expenses that are considered 'High'.")


# KMeans clustering to group "categories" based on total spending
def spending_kmeans_clustering(expenses, spending_clustering):
    total_spent = expenses.groupby('category')['amount'].sum().reset_index(name='total_spent')

    if total_spent['total_spent'].nunique() == 1:
        total_spent['spending_group'] = 'Moderate'
    else:
        scaler = StandardScaler()
        total_spent['normalized_total_spent'] = scaler.fit_transform(total_spent[['total_spent']])

        n_clusters = min(3, total_spent['normalized_total_spent'].nunique())
        kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
        total_spent['cluster'] = kmeans.fit_predict(total_spent[['normalized_total_spent']])

        cluster_averages = total_spent.groupby('cluster')['normalized_total_spent'].mean().sort_values(ascending=False)
        cluster_labels = {cluster: label for cluster, label in 
                          zip(cluster_averages.index, ['High', 'Moderate', 'Low'][:n_clusters])}

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

    if frequency['count'].nunique() == 1:
        frequency['frequency_group'] = 'Moderate'
    else:
        scaler = StandardScaler()
        frequency['normalized_count'] = scaler.fit_transform(frequency[['count']])

        n_clusters = min(3, frequency['normalized_count'].nunique())
        kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
        frequency['cluster'] = kmeans.fit_predict(frequency[['normalized_count']])

        cluster_averages = frequency.groupby('cluster')['normalized_count'].mean().sort_values(ascending=False)
        cluster_labels = {cluster: label for cluster, label in 
                          zip(cluster_averages.index, ['High', 'Moderate', 'Low'][:n_clusters])}
        
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