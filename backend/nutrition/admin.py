from django.contrib import admin
from .models import FoodItem


@admin.register(FoodItem)
class FoodItemAdmin(admin.ModelAdmin):
    list_display = ('name', 'meal_type', 'diet_type', 'calories', 'protein', 'carbohydrates', 'fat', 'cuisine')
    list_filter = ('meal_type', 'diet_type', 'cuisine')
    search_fields = ('name', 'cuisine', 'ingredients')
