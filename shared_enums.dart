/// Priority used by both Tasks and Goals. Shared in one place so the two
/// features render priority badges identically.
enum Priority { low, medium, high }

/// Simple recurrence used by Tasks (and referenced by the Calendar/roadmap
/// features later). Deliberately not a full RRULE implementation — that's
/// far more power than a personal task list needs, and every extra rule is
/// one more thing that can silently compute the wrong next-due-date.
enum Recurrence { none, daily, weekly, monthly }

/// Where an alarm's sound comes from.
enum AlarmSoundSource { builtIn, deviceRingtone, customFile }
