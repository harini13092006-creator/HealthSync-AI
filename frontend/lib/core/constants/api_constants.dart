class ApiConstants {
  static String baseUrl = _defaultBaseUrl;

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }

  static String get _defaultBaseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configuredUrl.isNotEmpty) {
      return _normalizeBaseUrl(configuredUrl);
    }

    // Default to local backend at 127.0.0.1:8000
    // (Works via 'adb reverse tcp:8000 tcp:8000' on mobile devices connected over USB and on desktop)
    return 'http://127.0.0.1:8000';
  }

  // Auth endpoints
  static String register = '$baseUrl/api/auth/register/';
  static String login = '$baseUrl/api/auth/login/';
  static String tokenRefresh = '$baseUrl/api/auth/token/refresh/';
  static String me = '$baseUrl/api/auth/me/';

  // Profile endpoints
  static String profile = '$baseUrl/api/profile/';
  static String completeOnboarding = '$baseUrl/api/profile/onboarding/';
  static String goals = '$baseUrl/api/goals/';
  static String foodPreferences = '$baseUrl/api/profile/food-preferences/';
  static String exercisePreferences = '$baseUrl/api/profile/exercise-preferences/';
  static String availability = '$baseUrl/api/profile/availability/';

  // Tasks endpoints
  static String tasks = '$baseUrl/api/tasks/';
  static String todaysTasks = '$baseUrl/api/tasks/today/';
  static String generateRoutine = '$baseUrl/api/tasks/generate-routine/';

  // Health Monitoring endpoints
  static String healthOverview = '$baseUrl/api/health/';
  static String logActivity = '$baseUrl/api/health/activity/';
  static String logSleep = '$baseUrl/api/health/sleep/';
  static String logWater = '$baseUrl/api/health/water/';
  static String logMeal = '$baseUrl/api/health/meal/';
  static String logMeditation = '$baseUrl/api/health/meditation/';

  // Recommendations endpoints
  static String recommendationsHistory = '$baseUrl/api/recommendations/history/';
  static String generateRecommendation = '$baseUrl/api/recommendations/generate/';
  static String foodRecommendations = '$baseUrl/api/recommendations/food/';
  static String exerciseRecommendations = '$baseUrl/api/recommendations/exercise/';
  static String minimumViableTask = '$baseUrl/api/recommendations/mvt/';

  // Analytics endpoints
  static String dailyAnalytics = '$baseUrl/api/analytics/daily/';
  static String weeklyAnalytics = '$baseUrl/api/analytics/weekly/';
  static String wellnessScore = '$baseUrl/api/analytics/wellness-score/';
  static String behaviorAnalytics = '$baseUrl/api/analytics/behavior/';

  // Notifications endpoints
  static String notifications = '$baseUrl/api/notifications/';
  static String markAllRead = '$baseUrl/api/notifications/mark-all-read/';

  static void updateBaseUrl(String newUrl) {
    baseUrl = _normalizeBaseUrl(newUrl);
    register = '$baseUrl/api/auth/register/';
    login = '$baseUrl/api/auth/login/';
    tokenRefresh = '$baseUrl/api/auth/token/refresh/';
    me = '$baseUrl/api/auth/me/';
    profile = '$baseUrl/api/profile/';
    completeOnboarding = '$baseUrl/api/profile/onboarding/';
    goals = '$baseUrl/api/goals/';
    foodPreferences = '$baseUrl/api/profile/food-preferences/';
    exercisePreferences = '$baseUrl/api/profile/exercise-preferences/';
    availability = '$baseUrl/api/profile/availability/';
    tasks = '$baseUrl/api/tasks/';
    todaysTasks = '$baseUrl/api/tasks/today/';
    generateRoutine = '$baseUrl/api/tasks/generate-routine/';
    healthOverview = '$baseUrl/api/health/';
    logActivity = '$baseUrl/api/health/activity/';
    logSleep = '$baseUrl/api/health/sleep/';
    logWater = '$baseUrl/api/health/water/';
    logMeal = '$baseUrl/api/health/meal/';
    logMeditation = '$baseUrl/api/health/meditation/';
    recommendationsHistory = '$baseUrl/api/recommendations/history/';
    generateRecommendation = '$baseUrl/api/recommendations/generate/';
    foodRecommendations = '$baseUrl/api/recommendations/food/';
    exerciseRecommendations = '$baseUrl/api/recommendations/exercise/';
    minimumViableTask = '$baseUrl/api/recommendations/mvt/';
    dailyAnalytics = '$baseUrl/api/analytics/daily/';
    weeklyAnalytics = '$baseUrl/api/analytics/weekly/';
    wellnessScore = '$baseUrl/api/analytics/wellness-score/';
    behaviorAnalytics = '$baseUrl/api/analytics/behavior/';
    notifications = '$baseUrl/api/notifications/';
    markAllRead = '$baseUrl/api/notifications/mark-all-read/';
  }
}
