from django.db import models


class FoodItem(models.Model):
    class MealType(models.TextChoices):
        BREAKFAST = 'BREAKFAST', 'Breakfast'
        LUNCH = 'LUNCH', 'Lunch'
        SNACK = 'SNACK', 'Snack'
        DINNER = 'DINNER', 'Dinner'
        ANY = 'ANY', 'Any Meal'

    class DietType(models.TextChoices):
        VEGETARIAN = 'VEGETARIAN', 'Vegetarian'
        VEGAN = 'VEGAN', 'Vegan'
        NON_VEGETARIAN = 'NON_VEGETARIAN', 'Non-Vegetarian'
        EGGETARIAN = 'EGGETARIAN', 'Eggetarian'
        PESCATARIAN = 'PESCATARIAN', 'Pescatarian'

    name = models.CharField(max_length=255, db_index=True)
    meal_type = models.CharField(max_length=20, choices=MealType.choices, default=MealType.ANY)
    diet_type = models.CharField(max_length=20, choices=DietType.choices, default=DietType.VEGETARIAN)
    calories = models.FloatField(help_text='Calories per serving (kcal)', default=200.0)
    protein = models.FloatField(help_text='Protein (g)', default=5.0)
    carbohydrates = models.FloatField(help_text='Carbohydrates (g)', default=30.0)
    fat = models.FloatField(help_text='Fat (g)', default=5.0)
    ingredients = models.JSONField(default=list, blank=True, help_text='List of primary ingredients')
    cuisine = models.CharField(max_length=100, default='South Indian')
    tags = models.JSONField(default=list, blank=True, help_text='Keywords e.g. ["high-fiber", "low-calorie"]')
    description = models.TextField(blank=True, default='')

    class Meta:
        ordering = ['name']
        indexes = [
            models.Index(fields=['meal_type', 'diet_type']),
            models.Index(fields=['cuisine']),
        ]

    def __str__(self):
        return f"{self.name} ({self.meal_type} - {self.diet_type} - {self.calories} kcal)"
