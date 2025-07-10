# Online Coding School Database ERD Design

## Overview
This database design supports an online coding school offering trial lessons and weekly recurring lessons for children aged 7-15, teaching programs like Scratch, Minecraft, Roblox, Python, and JavaScript.

## Core Entities and Relationships

### 1. **Students** Table
```sql
Students {
    student_id (PK)
    first_name
    last_name
    date_of_birth
    age_group (7-9, 10-12, 13-15)
    skill_level (beginner, intermediate, advanced)
    preferred_timezone
    notes
    created_date
    updated_date
    status (active, inactive, graduated)
}
```

### 2. **Parents** Table
```sql
Parents {
    parent_id (PK)
    first_name
    last_name
    email
    phone
    address
    city
    country
    timezone
    preferred_contact_method
    created_date
    updated_date
}
```

### 3. **Student_Parents** (Junction Table)
```sql
Student_Parents {
    student_id (FK)
    parent_id (FK)
    relationship_type (mother, father, guardian)
    is_primary_contact (boolean)
    is_billing_contact (boolean)
}
```

### 4. **Tutors** Table
```sql
Tutors {
    tutor_id (PK)
    first_name
    last_name
    email
    phone
    timezone
    hourly_rate
    bio
    years_experience
    certifications
    profile_image_url
    status (active, inactive, on_leave)
    hire_date
    created_date
    updated_date
}
```

### 5. **Programs** Table
```sql
Programs {
    program_id (PK)
    program_name (Scratch, Minecraft, Roblox, Python, JavaScript)
    description
    recommended_age_min
    recommended_age_max
    difficulty_level (beginner, intermediate, advanced)
    duration_weeks
    lesson_duration_minutes
    max_students_per_session
    price_per_session
    is_active (boolean)
    created_date
    updated_date
}
```

### 6. **Tutor_Programs** (Junction Table)
```sql
Tutor_Programs {
    tutor_id (FK)
    program_id (FK)
    proficiency_level (certified, experienced, learning)
    date_certified
}
```

### 7. **Zoom_Rooms** Table
```sql
Zoom_Rooms {
    room_id (PK)
    room_name
    zoom_meeting_url
    zoom_meeting_id
    zoom_passcode
    max_capacity
    is_active (boolean)
    created_date
    updated_date
}
```

### 8. **Tutor_Availability** Table
```sql
Tutor_Availability {
    availability_id (PK)
    tutor_id (FK)
    day_of_week (monday, tuesday, etc.)
    start_time
    end_time
    timezone
    is_recurring (boolean)
    effective_date_start
    effective_date_end
    created_date
    updated_date
}
```

### 9. **Sessions** Table (Unified for Trials and Regular Lessons)
```sql
Sessions {
    session_id (PK)
    program_id (FK)
    tutor_id (FK)
    zoom_room_id (FK)
    session_type (trial, regular, makeup)
    session_date
    start_time
    end_time
    timezone
    max_students
    session_status (scheduled, completed, cancelled, no_show)
    lesson_plan_notes
    homework_assigned
    created_date
    updated_date
}
```

### 10. **Enrollments** Table
```sql
Enrollments {
    enrollment_id (PK)
    student_id (FK)
    program_id (FK)
    enrollment_type (trial, weekly_recurring)
    enrollment_date
    start_date
    end_date
    sessions_per_week
    preferred_day_of_week
    preferred_time_slot
    enrollment_status (active, paused, completed, cancelled)
    payment_status (pending, paid, overdue)
    total_amount
    amount_paid
    created_date
    updated_date
}
```

### 11. **Session_Bookings** Table
```sql
Session_Bookings {
    booking_id (PK)
    session_id (FK)
    student_id (FK)
    enrollment_id (FK)
    booking_date
    booking_status (confirmed, waitlist, cancelled, completed, no_show)
    attendance_status (present, absent, late)
    student_feedback_rating (1-5)
    tutor_notes
    homework_completion (boolean)
    created_date
    updated_date
}
```

### 12. **Payments** Table
```sql
Payments {
    payment_id (PK)
    enrollment_id (FK)
    parent_id (FK)
    amount
    payment_date
    payment_method (credit_card, paypal, bank_transfer)
    payment_status (pending, completed, failed, refunded)
    transaction_id
    invoice_number
    payment_period_start
    payment_period_end
    created_date
    updated_date
}
```

### 13. **Student_Progress** Table
```sql
Student_Progress {
    progress_id (PK)
    student_id (FK)
    program_id (FK)
    session_id (FK)
    skill_assessed
    competency_level (1-5)
    assessment_date
    tutor_comments
    milestone_achieved
    next_learning_goal
    created_date
    updated_date
}
```

## Key Relationships and Constraints

### Primary Relationships:
1. **Students ↔ Parents**: Many-to-Many (families can have multiple children)
2. **Students ↔ Enrollments**: One-to-Many (student can enroll in multiple programs)
3. **Tutors ↔ Programs**: Many-to-Many (tutors can teach multiple programs)
4. **Sessions ↔ Bookings**: One-to-Many (sessions can have multiple students)
5. **Enrollments ↔ Payments**: One-to-Many (enrollments can have multiple payments)

### Business Rules:
- A trial enrollment can only have 1 session booking
- Weekly recurring enrollments generate multiple sessions automatically
- Students cannot book overlapping sessions
- Tutors cannot be double-booked
- Zoom rooms cannot be double-booked
- Maximum students per session enforced by program rules

## Data Flow Optimization Features

### 1. **Automated Session Generation**
- Weekly recurring enrollments automatically generate sessions based on tutor availability
- Reduces manual scheduling work for admins

### 2. **Centralized Program Management**
- Program details (price, duration, requirements) stored once
- Updates cascade to all related enrollments and sessions

### 3. **Smart Booking System**
- Available time slots calculated from tutor availability × zoom room availability
- Prevents double-booking conflicts automatically

### 4. **Payment Tracking Integration**
- Enrollment status automatically updates based on payment status
- Overdue payments trigger enrollment pause

### 5. **Progress Tracking**
- Student progress linked directly to specific sessions
- Enables detailed reporting without data duplication

## Admin Dashboard Queries

### Key Reports Needed:
1. **Daily Schedule**: All sessions for a given date with tutor, students, and zoom room
2. **Student Overview**: All enrollments, payments, and progress for a student
3. **Tutor Utilization**: Hours taught, availability, and program assignments
4. **Revenue Reports**: Payments by period, program, or tutor
5. **Trial Conversion**: Track trial-to-enrollment conversion rates

### Sample Queries:

#### Today's Schedule
```sql
SELECT s.session_date, s.start_time, s.end_time,
       p.program_name, t.first_name + ' ' + t.last_name as tutor_name,
       zr.room_name, 
       COUNT(sb.student_id) as enrolled_students
FROM Sessions s
JOIN Programs p ON s.program_id = p.program_id
JOIN Tutors t ON s.tutor_id = t.tutor_id
JOIN Zoom_Rooms zr ON s.zoom_room_id = zr.room_id
LEFT JOIN Session_Bookings sb ON s.session_id = sb.session_id 
    AND sb.booking_status = 'confirmed'
WHERE s.session_date = CURRENT_DATE
GROUP BY s.session_id, s.session_date, s.start_time, s.end_time, 
         p.program_name, t.first_name, t.last_name, zr.room_name
ORDER BY s.start_time;
```

#### Student Enrollment Status
```sql
SELECT st.first_name + ' ' + st.last_name as student_name,
       p.program_name,
       e.enrollment_status,
       e.payment_status,
       COUNT(sb.session_id) as sessions_attended
FROM Students st
JOIN Enrollments e ON st.student_id = e.student_id
JOIN Programs p ON e.program_id = p.program_id
LEFT JOIN Session_Bookings sb ON e.enrollment_id = sb.enrollment_id 
    AND sb.attendance_status = 'present'
GROUP BY st.student_id, st.first_name, st.last_name, 
         p.program_name, e.enrollment_status, e.payment_status;
```

## Implementation Notes

### Indexes for Performance:
- `Students`: Index on (age_group, status)
- `Sessions`: Index on (session_date, tutor_id, zoom_room_id)
- `Session_Bookings`: Index on (session_id, student_id, booking_status)
- `Enrollments`: Index on (student_id, enrollment_status, payment_status)

### Data Integrity:
- Cascade deletes for related records
- Check constraints for valid age groups, time slots
- Unique constraints to prevent double-booking

### Automation Opportunities:
1. **Auto-generate sessions** for weekly enrollments
2. **Auto-update enrollment status** based on payment status
3. **Send automated reminders** before sessions
4. **Generate invoices** automatically for recurring payments

This design minimizes redundant data entry while maintaining data integrity and supporting efficient queries for daily operations.