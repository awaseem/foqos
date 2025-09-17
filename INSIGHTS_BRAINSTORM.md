# Foqos Insights Screen - Feature Brainstorm

## Overview

This document outlines the comprehensive insights and analytics we can build for the new BlockedProfileSession Insights screen, based on the available data from `BlockedProfileSession` and `BlockedProfiles` models.

## Current Stats to Migrate

**Moving from BlockedProfileView "Stats for Nerds" section:**

- Profile ID
- Created Date
- Last Modified Date
- Total Sessions Count
- Categories/Apps Blocked Count
- Active Device Activity

---

## 📊 Time-Based Analytics

### Session Duration Insights

- **Average session duration** - Mean time across all completed sessions
- **Longest session ever** - Personal best for single session
- **Shortest completed session** - Minimum successful session time
- **Total time focused** - Cumulative sum of all completed sessions

### Daily/Weekly/Monthly Patterns

- **Sessions per day/week/month** - Frequency tracking over time periods
- **Average daily focus time** - Mean daily session duration
- **Best focus day of the week** - Most productive day identification
- **Focus time trends over time** - Line charts showing progression
- **Consistency streaks** - Consecutive days with completed sessions

### Time of Day Analysis

- **Most productive hours** - When sessions are typically started
- **Peak focus times** - Hours with longest average sessions
- **Session duration by time of day** - Performance correlation with timing

---

## ⏸️ Break Usage Analytics

### Break Behavior

- **Total breaks taken** - Across all sessions count
- **Average break duration** - Mean time spent on breaks
- **Sessions with breaks vs without** - Usage comparison
- **Break usage patterns** - By day/time analysis

### Break Impact Analysis

- **Session completion rate** - With/without breaks comparison
- **Average session duration** - Impact of breaks on total focus time
- **Break effectiveness** - Correlation between breaks and success

---

## ✅ Session Completion & Success Metrics

### Completion Rates

- **Completion percentage** - Sessions completed vs abandoned
- **Force-started vs regular sessions** - Success rate comparison
- **Success rate by profile type** - Which profiles work best

### Session Quality Indicators

- **Early termination analysis** - Sessions ended before intended
- **Most successful session patterns** - Optimal times/days/conditions
- **Failure pattern identification** - Common abandonment triggers

---

## 📱 Profile Comparison & Usage

### Profile Performance

- **Most frequently used profiles** - Usage ranking
- **Most effective profiles** - Longest average session duration
- **Profile usage trends** - Popularity changes over time
- **Profile success correlation** - Settings that lead to better outcomes

### Strategy Effectiveness

- **Success rates by blocking strategy** - NFC vs QR vs Manual comparison
- **Average session duration by strategy** - Which methods work longest
- **Strategy preference evolution** - How usage changes over time

---

## 🎯 Habit & Behavior Insights

### Focus Habits

- **Current streak** - Consecutive days with sessions
- **Longest streak ever** - Personal best consistency record
- **Days since last session** - Recency tracking
- **Focus consistency score** - Overall habit strength metric

### Goal Progress Tracking

- **Weekly/monthly goal progress** - Time-based targets
- **Sessions completed vs targets** - Quantity goal tracking
- **Historical goal achievement** - Success rate over time

---

## 📅 Calendar & Schedule Integration

### Schedule Adherence

- **Planned vs actual sessions** - Schedule compliance rate
- **Deviation from planned times** - How often users stick to schedule
- **Most/least reliable schedule slots** - Time periods with best adherence

### Seasonal & Long-term Patterns

- **Focus patterns by month/season** - Long-term trends
- **Productivity cycles** - Identifying natural rhythm patterns
- **Life event correlations** - How external factors affect focus

---

## 📈 Advanced Visualizations

### Heat Maps

- **Daily activity heat map** - GitHub-style contribution calendar
- **Hour vs Day heat map** - 24x7 grid showing peak times
- **Monthly intensity map** - Long-term pattern visualization

### Charts & Graphs

- **Session duration trends** - Line charts over time
- **Weekly focus time bars** - Comparative bar charts
- **Break usage pie charts** - Proportion breakdowns
- **Profile usage distribution** - Usage share visualization

---

## 🏆 Gamification Elements

### Achievements & Badges

- **"Marathon Focuser"** - Longest single session milestone
- **"Consistent Champion"** - X consecutive days streak
- **"Early Bird"** - Most morning sessions
- **"Night Owl"** - Most evening sessions
- **"Break Master"** - Effective break usage
- **"Strategy Explorer"** - Using multiple blocking strategies

### Milestone Tracking

- **Total hours focused** - Cumulative time achievements
- **Session count milestones** - Number-based goals
- **Days since first session** - Journey tracking
- **Personal records** - Various "best ever" metrics

---

## 📊 Comparative Analytics

### Personal Performance

- **This week vs last week** - Short-term progress
- **This month vs last month** - Medium-term trends
- **Year-over-year comparison** - Long-term growth
- **Personal bests tracking** - Record achievements

### Goal & Target Analysis

- **Daily focus time goals** - Time-based targets
- **Session frequency goals** - Quantity-based targets
- **Progress indicators** - Visual goal completion status
- **Goal achievement history** - Success rate tracking

---

## 🔍 Advanced Analytics

### Predictive Insights

- **Best times to start sessions** - Based on historical success
- **Optimal session length recommendations** - Personalized duration suggestions
- **Break timing suggestions** - When to take breaks for best results

### Correlation Analysis

- **Success factors identification** - What conditions lead to better sessions
- **Failure pattern recognition** - Common reasons for session abandonment
- **Environmental factor impact** - Day of week, time, season effects

---

## 📱 Implementation Priority

### Phase 1: Foundation

- Migrate existing stats
- Basic duration analytics
- Simple completion rates

### Phase 2: Core Insights

- Time pattern analysis
- Break usage analytics
- Habit tracking basics

### Phase 3: Advanced Features

- Heat maps and visualizations
- Gamification elements
- Predictive insights

### Phase 4: Polish

- Advanced correlations
- Goal setting and tracking
- Achievement system

---

## 🗂️ Available Data Points

### From BlockedProfileSession:

- `id` - Unique session identifier
- `tag` - Session label/category
- `startTime` - When session began
- `endTime` - When session ended (null if active)
- `breakStartTime` - When break began (optional)
- `breakEndTime` - When break ended (optional)
- `forceStarted` - Whether session was force-started
- `duration` - Calculated session length
- `blockedProfile` - Relationship to profile used

### From BlockedProfiles:

- Profile configuration data
- Blocking strategy information
- Schedule settings
- Feature flags (breaks, strict mode, etc.)
- Creation and modification timestamps

### Calculated Metrics:

- Session completion status
- Break usage patterns
- Success rates by various dimensions
- Time-based aggregations
- Trend calculations
