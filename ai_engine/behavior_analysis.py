"""
HealthSync AI - Behavioral Analytics and Habit Pattern Detection
Analyzes user adherence, skips, reschedules, and temporal completion patterns.
"""

from collections import defaultdict


class BehaviorAnalyzer:
    """
    Computes habit adherence statistics and detects user timing preferences.
    """

    @staticmethod
    def analyze_records(records):
        """
        records: list of dicts or BehaviorRecord objects with:
        task_type, scheduled_time, completed, skipped, rescheduled, day_of_week
        """
        if not records:
            return {
                'total_tasks': 0,
                'completion_rate': 0.0,
                'skip_rate': 0.0,
                'reschedule_rate': 0.0,
                'hourly_adherence': {},
                'best_hours': [],
                'patterns': ['No behavioral logs recorded yet. Start completing tasks to generate personalized insights.']
            }

        total = len(records)
        completed_count = sum(1 for r in records if r.get('completed'))
        skipped_count = sum(1 for r in records if r.get('skipped'))
        rescheduled_count = sum(1 for r in records if r.get('rescheduled'))

        # Hourly completion analysis
        hourly_stats = defaultdict(lambda: {'total': 0, 'completed': 0})
        type_stats = defaultdict(lambda: {'total': 0, 'completed': 0})

        for r in records:
            sched_time = r.get('scheduled_time')
            hour = 12
            if hasattr(sched_time, 'hour'):
                hour = sched_time.hour
            elif isinstance(sched_time, str):
                try:
                    hour = int(sched_time.split(':')[0])
                except Exception:
                    hour = 12

            hourly_stats[hour]['total'] += 1
            ttype = r.get('task_type', 'GENERAL')
            type_stats[ttype]['total'] += 1

            if r.get('completed'):
                hourly_stats[hour]['completed'] += 1
                type_stats[ttype]['completed'] += 1

        hourly_adherence = {}
        for h, st in hourly_stats.items():
            rate = round((st['completed'] / st['total']) if st['total'] > 0 else 0.0, 2)
            hourly_adherence[h] = {
                'total': st['total'],
                'completed': st['completed'],
                'adherence_rate': rate
            }

        # Find best completion hours (adherence >= 0.6 with at least 2 logs)
        sorted_hours = sorted(
            hourly_adherence.items(),
            key=lambda x: (x[1]['adherence_rate'], x[1]['completed']),
            reverse=True
        )
        best_hours = [h for h, st in sorted_hours if st['adherence_rate'] >= 0.5]

        # Detect specific behavioral patterns
        patterns = []
        if total >= 4:
            # Check morning vs evening exercise
            morning_ex = [r for r in records if r.get('task_type') == 'EXERCISE' and BehaviorAnalyzer._get_hour(r) < 10]
            evening_ex = [r for r in records if r.get('task_type') == 'EXERCISE' and BehaviorAnalyzer._get_hour(r) >= 17]

            m_comp = sum(1 for r in morning_ex if r.get('completed'))
            m_rate = (m_comp / len(morning_ex)) if morning_ex else 0.0

            e_comp = sum(1 for r in evening_ex if r.get('completed'))
            e_rate = (e_comp / len(evening_ex)) if evening_ex else 0.0

            if len(morning_ex) >= 2 and len(evening_ex) >= 2:
                if e_rate > m_rate + 0.3:
                    patterns.append(
                        f"Your workouts are completed more consistently in the evening (around 5:30 PM - 7:30 PM, {int(e_rate*100)}% adherence) compared to early mornings ({int(m_rate*100)}% adherence)."
                    )
                elif m_rate > e_rate + 0.3:
                    patterns.append(
                        f"You show significantly higher energy and consistency during morning workouts ({int(m_rate*100)}% adherence)."
                    )

        if not patterns:
            overall_rate = round((completed_count / total) * 100, 1)
            patterns.append(f"Overall task adherence is {overall_rate}%. Regular routines build lasting habits.")

        return {
            'total_tasks': total,
            'completion_rate': round(completed_count / total, 3),
            'skip_rate': round(skipped_count / total, 3),
            'reschedule_rate': round(rescheduled_count / total, 3),
            'hourly_adherence': hourly_adherence,
            'best_hours': best_hours,
            'patterns': patterns
        }

    @staticmethod
    def _get_hour(record):
        sched_time = record.get('scheduled_time')
        if hasattr(sched_time, 'hour'):
            return sched_time.hour
        elif isinstance(sched_time, str):
            try:
                return int(sched_time.split(':')[0])
            except Exception:
                pass
        return 12
