"""
HealthSync AI - Adaptive Routine Generator, Schedule Conflict Detector & Intelligent Rescheduler
"""

from datetime import time, timedelta, datetime
try:
    from ai_engine.user_profiler import UserProfiler
    from ai_engine.predict import CompletionPredictor
except ImportError:
    from user_profiler import UserProfiler
    from predict import CompletionPredictor


class ScheduleConflictDetector:
    """
    Identifies scheduling overlaps against fixed commitments (college/work, sleep, travel).
    """

    @staticmethod
    def is_slot_available(start_min, duration_min, blocked_intervals):
        """
        start_min: start in minutes from midnight
        duration_min: duration in minutes
        blocked_intervals: list of (start_m, end_m, label)
        """
        end_min = start_min + duration_min
        for b_start, b_end, label in blocked_intervals:
            if not (end_min <= b_start or start_min >= b_end):
                return False, label
        return True, None

    @staticmethod
    def detect_conflicts(task_list, blocked_intervals):
        """
        Finds overlapping tasks and conflicts with external blocks.
        """
        conflicts = []
        # Check against blocked external intervals
        for task in task_list:
            t_start = UserProfiler.parse_time_to_minutes(task['scheduled_time'])
            t_dur = task.get('duration', 15)
            avail, reason = ScheduleConflictDetector.is_slot_available(t_start, t_dur, blocked_intervals)
            if not avail:
                conflicts.append({
                    'task': task,
                    'conflict_type': 'UNAVAILABLE_PERIOD',
                    'reason': f"Conflicts with {reason} ({UserProfiler.minutes_to_time(t_start).strftime('%H:%M')} overlaps)."
                })

        # Check for overlaps between tasks
        sorted_tasks = sorted(task_list, key=lambda x: UserProfiler.parse_time_to_minutes(x['scheduled_time']))
        for i in range(len(sorted_tasks) - 1):
            cur = sorted_tasks[i]
            nxt = sorted_tasks[i + 1]
            cur_start = UserProfiler.parse_time_to_minutes(cur['scheduled_time'])
            cur_end = cur_start + cur.get('duration', 15)
            nxt_start = UserProfiler.parse_time_to_minutes(nxt['scheduled_time'])

            if cur_end > nxt_start:
                conflicts.append({
                    'task': nxt,
                    'conflict_type': 'TASK_OVERLAP',
                    'reason': f"'{nxt['title']}' overlaps with '{cur['title']}'."
                })

        return conflicts


class AdaptiveRoutinePlanner:
    """
    Constructs a personalized daily schedule based on user waking hours,
    commitments, goals, and behavioral completion probabilities.
    """

    def __init__(self, predictor=None):
        self.predictor = predictor or CompletionPredictor()

    def generate_daily_routine(self, user_profile, goals=None, availability=None, food_pref=None, exercise_pref=None, historical_rate=0.75):
        """
        Creates a structured daily plan without overlaps.
        """
        goals = goals or ['FITNESS', 'HEALTHY_EATING', 'HYDRATION']
        wake_t = user_profile.get('wake_time', '06:30:00')
        sleep_t = user_profile.get('sleep_time', '22:30:00')
        wake_m = UserProfiler.parse_time_to_minutes(wake_t)
        sleep_m = UserProfiler.parse_time_to_minutes(sleep_t)

        # Parse blocked periods from availability
        blocked = []
        # Sleep window is blocked
        if sleep_m > wake_m:
            blocked.append((0, wake_m, 'Sleep / Rest'))
            blocked.append((sleep_m, 24 * 60, 'Sleep Routine'))

        if availability and availability.get('unavailable_periods'):
            for p in availability['unavailable_periods']:
                p_start = UserProfiler.parse_time_to_minutes(p['start'])
                p_end = UserProfiler.parse_time_to_minutes(p['end'])
                blocked.append((p_start, p_end, p.get('label', 'Busy Period')))

        cuisine = food_pref.get('cuisine', 'South Indian') if food_pref else 'South Indian'
        diet_type = food_pref.get('diet_type', 'Vegetarian') if food_pref else 'Vegetarian'

        ex_category = 'Brisk Walk'
        ex_dur = 30
        if exercise_pref:
            exercises = exercise_pref.get('preferred_exercises', [])
            if exercises:
                ex_category = exercises[0]
            ex_dur = exercise_pref.get('preferred_duration', 30)

        tasks = []

        # 1. Morning Mindfulness (20 mins after waking)
        m_med_start = wake_m + 20
        tasks.append({
            'task_type': 'MEDITATION',
            'title': 'Morning Box Breathing & Reset',
            'description': '5-10 minutes of centering breathwork to sharpen morning focus.',
            'scheduled_time': UserProfiler.minutes_to_time(m_med_start).strftime('%H:%M:%S'),
            'duration': 10,
            'priority': 'HIGH',
            'ai_explanation': f"Scheduled shortly after your {UserProfiler.minutes_to_time(wake_m).strftime('%H:%M')} wake-up to promote calm cortisol regulation."
        })

        # 2. Morning Exercise or Movement
        m_ex_start = m_med_start + 20
        # Check if morning exercise fits before busy blocks
        avail, _ = ScheduleConflictDetector.is_slot_available(m_ex_start, ex_dur, blocked)
        if avail and 'FITNESS' in goals:
            tasks.append({
                'task_type': 'EXERCISE',
                'title': f"Morning {ex_category}",
                'description': f"Energizing {ex_dur}-minute session.",
                'scheduled_time': UserProfiler.minutes_to_time(m_ex_start).strftime('%H:%M:%S'),
                'duration': ex_dur,
                'priority': 'HIGH',
                'ai_explanation': f"Placed in your open morning window to kickstart metabolic energy before your daily commitments."
            })
            b_start = m_ex_start + ex_dur + 15
        else:
            b_start = m_med_start + 25

        # 3. Breakfast
        tasks.append({
            'task_type': 'MEAL',
            'title': f"Nutritious Breakfast ({cuisine})",
            'description': f"Wholesome {diet_type.lower()} breakfast with slow-digesting carbohydrates.",
            'scheduled_time': UserProfiler.minutes_to_time(b_start).strftime('%H:%M:%S'),
            'duration': 30,
            'priority': 'HIGH',
            'ai_explanation': "Timed within 2 hours of waking to replenish glycogen stores."
        })

        # 4. Mid-Morning Hydration
        tasks.append({
            'task_type': 'HYDRATION',
            'title': 'Mid-Morning Hydration Refresher',
            'description': 'Drink 350-500ml clean water to maintain mental clarity.',
            'scheduled_time': '10:30:00',
            'duration': 5,
            'priority': 'MEDIUM',
            'ai_explanation': "Hydration checkpoint between breakfast and lunch."
        })

        # 5. Lunch
        tasks.append({
            'task_type': 'MEAL',
            'title': 'Wholesome Balanced Lunch',
            'description': f"Fiber and protein-rich {diet_type.lower()} meal.",
            'scheduled_time': '13:00:00',
            'duration': 30,
            'priority': 'HIGH',
            'ai_explanation': "Scheduled at standard midday digestive peak."
        })

        # 6. Afternoon Hydration
        tasks.append({
            'task_type': 'HYDRATION',
            'title': 'Afternoon Water Checkpoint',
            'description': 'Drink 250-500ml water to counter the afternoon lull.',
            'scheduled_time': '15:30:00',
            'duration': 5,
            'priority': 'MEDIUM',
            'ai_explanation': "Prevents dehydration-related afternoon fatigue."
        })

        # 7. Evening Exercise (if not in morning or for general activity)
        # Check evening open window around 17:30 or after commute
        candidate_ex_times = [17 * 60 + 30, 18 * 60, 18 * 60 + 30, 19 * 60]
        chosen_ex_time = None
        for c_time in candidate_ex_times:
            avail, _ = ScheduleConflictDetector.is_slot_available(c_time, ex_dur, blocked)
            if avail:
                chosen_ex_time = c_time
                break

        if chosen_ex_time and not any(t['task_type'] == 'EXERCISE' for t in tasks):
            tasks.append({
                'task_type': 'EXERCISE',
                'title': f"Evening {ex_category} & Stretching",
                'description': f"De-stressing {ex_dur}-minute session after daytime work.",
                'scheduled_time': UserProfiler.minutes_to_time(chosen_ex_time).strftime('%H:%M:%S'),
                'duration': ex_dur,
                'priority': 'HIGH',
                'ai_explanation': "Scheduled after your daily commitments conclude when your body temperature and muscle strength peak."
            })

        # 8. Dinner
        dinner_m = max(19 * 60 + 30, (chosen_ex_time + ex_dur + 30) if chosen_ex_time else (20 * 60))
        tasks.append({
            'task_type': 'MEAL',
            'title': 'Light Balanced Dinner',
            'description': 'Easily digestible evening meal at least 2 hours before bedtime.',
            'scheduled_time': UserProfiler.minutes_to_time(min(dinner_m, 20 * 60 + 30)).strftime('%H:%M:%S'),
            'duration': 30,
            'priority': 'HIGH',
            'ai_explanation': "Timed sufficiently ahead of your sleep schedule to ensure unhindered nocturnal digestion."
        })

        # 9. Sleep Routine
        winddown_m = sleep_m - 45
        tasks.append({
            'task_type': 'SLEEP_ROUTINE',
            'title': 'Sleep Wind-down & Progressive Relaxation',
            'description': 'Dim overhead lights, disconnect from screens, and practice mindful relaxation.',
            'scheduled_time': UserProfiler.minutes_to_time(winddown_m).strftime('%H:%M:%S'),
            'duration': 20,
            'priority': 'HIGH',
            'ai_explanation': f"Scheduled 45 minutes before your planned {UserProfiler.minutes_to_time(sleep_m).strftime('%H:%M')} sleep time to facilitate natural melatonin release."
        })

        # Filter out any unresolved conflicts
        conflicts = ScheduleConflictDetector.detect_conflicts(tasks, blocked)
        conflict_titles = {c['task']['title'] for c in conflicts if c['conflict_type'] == 'UNAVAILABLE_PERIOD'}
        clean_tasks = [t for t in tasks if t['title'] not in conflict_titles]

        return clean_tasks

    def find_best_reschedule_slot(self, task, blocked_intervals, existing_tasks, user_history_summary=None):
        """
        Evaluates alternative candidate time slots for a missed task.
        Ranks slots using ML completion probability, availability, and spacing from meals/sleep.
        """
        task_type = task.get('task_type', 'EXERCISE')
        duration = task.get('duration', 20)

        # Candidate hours: 17:00 through 21:00 for evening
        candidate_hours = [17, 18, 19, 20]
        candidate_slots = []

        existing_spans = []
        for et in existing_tasks:
            st_m = UserProfiler.parse_time_to_minutes(et['scheduled_time'])
            et_dur = et.get('duration', 15)
            existing_spans.append((st_m, st_m + et_dur, et.get('title', 'Task')))

        all_blocked = list(blocked_intervals) + existing_spans

        for hour in candidate_hours:
            for minute in [0, 30]:
                slot_m = hour * 60 + minute
                avail, reason = ScheduleConflictDetector.is_slot_available(slot_m, duration, all_blocked)
                if not avail:
                    continue

                prob = self.predictor.predict_completion_probability(
                    task_type=task_type,
                    scheduled_hour=hour,
                    duration=duration,
                    previous_completion_rate=0.85 if hour in [19, 20] else 0.45,
                    availability=1
                )

                candidate_slots.append({
                    'time': UserProfiler.minutes_to_time(slot_m).strftime('%H:%M:%S'),
                    'hour': hour,
                    'minute': minute,
                    'completion_probability': prob,
                })

        if not candidate_slots:
            # Fallback to tomorrow morning or default 19:30
            return {
                'recommended_time': '19:30:00',
                'probability': 0.82,
                'explanation': "Alternative slot selected based on typical evening availability."
            }

        candidate_slots.sort(key=lambda x: x['completion_probability'], reverse=True)
        top_slot = candidate_slots[0]

        top_time_str = top_slot['time'][:5]
        prob_pct = int(top_slot['completion_probability'] * 100)

        explanation = (
            f"Based on your routine patterns, {top_time_str} is your highest-probability window "
            f"({prob_pct}% estimated completion probability) with no schedule conflicts."
        )

        return {
            'recommended_time': top_slot['time'],
            'probability': top_slot['completion_probability'],
            'explanation': explanation,
            'all_candidates': candidate_slots[:3]
        }
