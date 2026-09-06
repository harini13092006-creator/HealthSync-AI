"""
HealthSync AI - Content-Based Food Recommendation Engine
Uses dietary constraints, cuisine preferences, macro targets, and cosine similarity.
NOTICE: General wellness dietary recommendations only; NOT clinical or medical nutrition therapy.
"""

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


class FoodRecommender:
    """
    Recommends nutritionally balanced meal options matching the user's
    dietary preferences, cuisine, and wellness goals.
    """

    def __init__(self, food_items=None):
        self.food_items = food_items or []
        self.vectorizer = TfidfVectorizer(stop_words='english')
        self._fit_vectorizer()

    def _fit_vectorizer(self):
        if not self.food_items:
            return
        corpus = [
            f"{f.get('name', '')} {f.get('cuisine', '')} {' '.join(f.get('tags', []))} {' '.join(f.get('ingredients', []))}"
            for f in self.food_items
        ]
        self.tfidf_matrix = self.vectorizer.fit_transform(corpus)

    def recommend(self, user_diet_type='VEGETARIAN', user_preferences=None, cuisine=None, goal='HEALTHY_EATING', meal_type=None, top_k=5):
        """
        Filters and ranks foods matching the user's constraints.
        """
        user_preferences = user_preferences or []
        query_parts = []
        if cuisine:
            query_parts.append(cuisine)
        query_parts.extend(user_preferences)
        if goal == 'FITNESS':
            query_parts.extend(['high-protein', 'recovery'])
        elif goal == 'HEALTHY_EATING':
            query_parts.extend(['fiber', 'nutritious', 'wholesome', 'balanced'])

        query_str = " ".join(query_parts) if query_parts else "healthy balanced meal"

        candidates = []
        for idx, item in enumerate(self.food_items):
            # Strict diet filter
            item_diet = item.get('diet_type', 'VEGETARIAN')
            if user_diet_type == 'VEGAN' and item_diet != 'VEGAN':
                continue
            if user_diet_type == 'VEGETARIAN' and item_diet not in ('VEGETARIAN', 'VEGAN'):
                continue
            if user_diet_type == 'EGGETARIAN' and item_diet not in ('VEGETARIAN', 'VEGAN', 'EGGETARIAN'):
                continue

            # Meal type filter if requested
            if meal_type and meal_type != 'ANY':
                if item.get('meal_type') not in (meal_type, 'ANY'):
                    continue

            candidates.append((idx, item))

        if not candidates:
            return []

        # Calculate cosine similarity with query
        query_vec = self.vectorizer.transform([query_str])
        candidate_indices = [idx for idx, _ in candidates]
        sub_matrix = self.tfidf_matrix[candidate_indices]
        sim_scores = cosine_similarity(query_vec, sub_matrix).flatten()

        ranked = []
        for i, (orig_idx, item) in enumerate(candidates):
            score = float(sim_scores[i])
            # Additional bonus for exact cuisine match
            if cuisine and cuisine.lower() in item.get('cuisine', '').lower():
                score += 0.25

            explanation = self._generate_explanation(item, user_diet_type, cuisine, goal, meal_type)
            item_copy = dict(item)
            item_copy['similarity_score'] = round(score, 3)
            item_copy['explanation'] = explanation
            ranked.append(item_copy)

        ranked.sort(key=lambda x: x['similarity_score'], reverse=True)
        return ranked[:top_k]

    def _generate_explanation(self, item, diet_type, cuisine, goal, meal_type):
        reasons = []
        reasons.append(f"Complies with your {diet_type.replace('_', ' ').title()} lifestyle")
        if cuisine and cuisine.lower() in item.get('cuisine', '').lower():
            reasons.append(f"matches your preferred {cuisine} culinary taste")
        if item.get('protein', 0) >= 10:
            reasons.append(f"provides {item.get('protein')}g satisfying protein")
        if 'high-fiber' in item.get('tags', []):
            reasons.append("rich in dietary fiber for sustained digestive wellness")
        if goal == 'FITNESS':
            reasons.append("supports your active fitness recovery target")

        return "Selected because this " + ", ".join(reasons) + "."
