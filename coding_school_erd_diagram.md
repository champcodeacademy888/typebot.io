# Online Coding School - Entity Relationship Diagram

## Visual ERD Structure

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    PARENTS      │    │ STUDENT_PARENTS │    │    STUDENTS     │
│                 │    │   (Junction)    │    │                 │
│ • parent_id (PK)│◄──►│ • student_id    │◄──►│ • student_id(PK)│
│ • first_name    │    │ • parent_id     │    │ • first_name    │
│ • last_name     │    │ • relationship  │    │ • last_name     │
│ • email         │    │ • is_primary    │    │ • date_of_birth │
│ • phone         │    │ • is_billing    │    │ • age_group     │
│ • address       │    └─────────────────┘    │ • skill_level   │
│ • timezone      │                           │ • timezone      │
└─────────────────┘                           │ • status        │
         │                                    └─────────────────┘
         │                                             │
         │                                             │
         ▼                                             ▼
┌─────────────────┐                           ┌─────────────────┐
│    PAYMENTS     │                           │   ENROLLMENTS   │
│                 │                           │                 │
│ • payment_id(PK)│◄─────────────────────────►│ • enrollment_id │
│ • enrollment_id │                           │   (PK)          │
│ • parent_id     │                           │ • student_id    │
│ • amount        │                           │ • program_id    │
│ • payment_date  │                           │ • type (trial/  │
│ • method        │                           │   recurring)    │
│ • status        │                           │ • start_date    │
└─────────────────┘                           │ • end_date      │
                                              │ • payment_status│
                                              └─────────────────┘
                                                       │
                                                       │
                                                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    PROGRAMS     │    │ SESSION_BOOKINGS│    │    SESSIONS     │
│                 │    │                 │    │                 │
│ • program_id(PK)│◄──►│ • booking_id(PK)│◄──►│ • session_id(PK)│
│ • program_name  │    │ • session_id    │    │ • program_id    │
│ • description   │    │ • student_id    │    │ • tutor_id      │
│ • age_min/max   │    │ • enrollment_id │    │ • zoom_room_id  │
│ • difficulty    │    │ • booking_status│    │ • session_type  │
│ • duration      │    │ • attendance    │    │ • session_date  │
│ • price         │    │ • feedback      │    │ • start_time    │
└─────────────────┘    │ • tutor_notes   │    │ • end_time      │
         │              └─────────────────┘    │ • status        │
         │                                     └─────────────────┘
         │                                              │
         ▼                                              │
┌─────────────────┐                                     │
│ TUTOR_PROGRAMS  │                                     │
│   (Junction)    │                                     │
│ • tutor_id      │◄────────────────────────────────────┤
│ • program_id    │                                     │
│ • proficiency   │                                     │
│ • date_certified│                                     │
└─────────────────┘                                     │
         │                                              │
         │                                              ▼
         ▼                                     ┌─────────────────┐
┌─────────────────┐                           │   ZOOM_ROOMS    │
│     TUTORS      │                           │                 │
│                 │                           │ • room_id (PK)  │
│ • tutor_id (PK) │◄─────────────────────────►│ • room_name     │
│ • first_name    │                           │ • meeting_url   │
│ • last_name     │                           │ • meeting_id    │
│ • email         │                           │ • passcode      │
│ • phone         │                           │ • max_capacity  │
│ • timezone      │                           │ • is_active     │
│ • hourly_rate   │                           └─────────────────┘
│ • status        │
└─────────────────┘
         │
         │
         ▼
┌─────────────────┐
│TUTOR_AVAILABILITY│
│                 │
│ • availability_ │
│   id (PK)       │
│ • tutor_id      │
│ • day_of_week   │
│ • start_time    │
│ • end_time      │
│ • timezone      │
│ • is_recurring  │
│ • effective_    │
│   dates         │
└─────────────────┘

┌─────────────────┐
│STUDENT_PROGRESS │
│                 │
│ • progress_id   │
│   (PK)          │
│ • student_id    │◄────── Links to STUDENTS
│ • program_id    │◄────── Links to PROGRAMS  
│ • session_id    │◄────── Links to SESSIONS
│ • skill_assessed│
│ • competency_   │
│   level (1-5)   │
│ • assessment_   │
│   date          │
│ • tutor_comments│
│ • milestone_    │
│   achieved      │
└─────────────────┘
```

## Key Relationship Types

### 🔗 **One-to-Many Relationships**
- **Students** → **Enrollments** (1:M)
- **Programs** → **Enrollments** (1:M) 
- **Enrollments** → **Payments** (1:M)
- **Sessions** → **Session_Bookings** (1:M)
- **Tutors** → **Sessions** (1:M)
- **Zoom_Rooms** → **Sessions** (1:M)
- **Tutors** → **Tutor_Availability** (1:M)

### 🔗 **Many-to-Many Relationships**
- **Students** ↔ **Parents** (via Student_Parents junction)
- **Tutors** ↔ **Programs** (via Tutor_Programs junction)

### 🔗 **Key Junction Tables**
- **Student_Parents**: Links families with multiple children
- **Tutor_Programs**: Tracks which tutors can teach which programs
- **Session_Bookings**: Links students to specific sessions

## Data Flow Summary

### 📋 **Trial Lesson Flow**
1. **Student** enrollment created with type = 'trial'
2. **Session** scheduled with session_type = 'trial'  
3. **Session_Booking** created linking student to trial session
4. **Payment** processed for trial lesson
5. **Student_Progress** recorded after session

### 📋 **Weekly Recurring Lesson Flow**
1. **Student** enrollment created with type = 'weekly_recurring'
2. Multiple **Sessions** auto-generated based on tutor availability
3. **Session_Bookings** created for each upcoming session
4. **Payments** scheduled for weekly/monthly billing
5. **Student_Progress** tracked across multiple sessions

### 📋 **Admin Efficiency Features**
- **Centralized program updates** cascade to all enrollments
- **Automated session generation** reduces manual scheduling
- **Smart availability matching** prevents double-booking
- **Integrated payment tracking** updates enrollment status
- **Progress reporting** links directly to specific sessions

## Database Optimization Notes

### 🚀 **Performance Indexes**
```sql
-- High-traffic query optimization
CREATE INDEX idx_sessions_date_tutor ON Sessions(session_date, tutor_id);
CREATE INDEX idx_bookings_student_status ON Session_Bookings(student_id, booking_status);
CREATE INDEX idx_enrollments_status_payment ON Enrollments(enrollment_status, payment_status);
CREATE INDEX idx_availability_tutor_day ON Tutor_Availability(tutor_id, day_of_week);
```

### 🔒 **Data Integrity Constraints**
```sql
-- Prevent double booking
UNIQUE constraint on (tutor_id, session_date, start_time)
UNIQUE constraint on (zoom_room_id, session_date, start_time)

-- Business rule enforcement  
CHECK constraint: session start_time < end_time
CHECK constraint: student age matches program age requirements
CHECK constraint: max_students per session not exceeded
```

This ERD design ensures minimal data redundancy while supporting the complex scheduling and payment tracking needs of your online coding school!