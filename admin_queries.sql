-- =====================================================
-- CODING SCHOOL ADMIN QUERIES
-- Useful SQL queries for daily operations and reporting
-- =====================================================

-- =====================================================
-- DAILY OPERATIONS QUERIES
-- =====================================================

-- 1. TODAY'S SCHEDULE - See all sessions happening today
SELECT 
    s.session_date,
    s.start_time,
    s.end_time,
    p.program_name,
    CONCAT(t.first_name, ' ', t.last_name) as tutor_name,
    zr.room_name,
    s.session_status,
    COUNT(sb.student_id) as enrolled_students,
    s.max_students,
    (s.max_students - COUNT(sb.student_id)) as available_spots
FROM Sessions s
JOIN Programs p ON s.program_id = p.program_id
JOIN Tutors t ON s.tutor_id = t.tutor_id
JOIN Zoom_Rooms zr ON s.zoom_room_id = zr.room_id
LEFT JOIN Session_Bookings sb ON s.session_id = sb.session_id 
    AND sb.booking_status = 'confirmed'
WHERE s.session_date = CURDATE()
GROUP BY s.session_id
ORDER BY s.start_time;

-- 2. STUDENTS IN TODAY'S SESSIONS - Get student details for today
SELECT 
    s.start_time,
    s.end_time,
    p.program_name,
    CONCAT(st.first_name, ' ', st.last_name) as student_name,
    st.age_group,
    CONCAT(pr.first_name, ' ', pr.last_name) as parent_name,
    pr.email as parent_email,
    pr.phone as parent_phone,
    sb.booking_status
FROM Sessions s
JOIN Programs p ON s.program_id = p.program_id
JOIN Session_Bookings sb ON s.session_id = sb.session_id
JOIN Students st ON sb.student_id = st.student_id
JOIN Student_Parents sp ON st.student_id = sp.student_id
JOIN Parents pr ON sp.parent_id = pr.parent_id
WHERE s.session_date = CURDATE() 
    AND sp.is_primary_contact = TRUE
    AND sb.booking_status IN ('confirmed', 'waitlist')
ORDER BY s.start_time, st.last_name;

-- 3. WEEKLY SCHEDULE - Next 7 days
SELECT 
    s.session_date,
    DAYNAME(s.session_date) as day_name,
    s.start_time,
    p.program_name,
    CONCAT(t.first_name, ' ', t.last_name) as tutor_name,
    COUNT(sb.student_id) as enrolled_students
FROM Sessions s
JOIN Programs p ON s.program_id = p.program_id
JOIN Tutors t ON s.tutor_id = t.tutor_id
LEFT JOIN Session_Bookings sb ON s.session_id = sb.session_id 
    AND sb.booking_status = 'confirmed'
WHERE s.session_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
GROUP BY s.session_id
ORDER BY s.session_date, s.start_time;

-- =====================================================
-- STUDENT MANAGEMENT QUERIES
-- =====================================================

-- 4. ACTIVE STUDENTS OVERVIEW
SELECT 
    CONCAT(st.first_name, ' ', st.last_name) as student_name,
    st.age_group,
    st.skill_level,
    COUNT(DISTINCT e.enrollment_id) as total_enrollments,
    COUNT(CASE WHEN e.enrollment_status = 'active' THEN 1 END) as active_enrollments,
    COUNT(CASE WHEN sb.attendance_status = 'present' THEN 1 END) as sessions_attended,
    MAX(sb.booking_date) as last_session_date
FROM Students st
LEFT JOIN Enrollments e ON st.student_id = e.student_id
LEFT JOIN Session_Bookings sb ON e.enrollment_id = sb.enrollment_id
WHERE st.status = 'active'
GROUP BY st.student_id
ORDER BY st.last_name, st.first_name;

-- 5. STUDENTS WITH OVERDUE PAYMENTS
SELECT 
    CONCAT(st.first_name, ' ', st.last_name) as student_name,
    CONCAT(pr.first_name, ' ', pr.last_name) as parent_name,
    pr.email,
    pr.phone,
    p.program_name,
    e.total_amount,
    e.amount_paid,
    (e.total_amount - e.amount_paid) as amount_due,
    e.start_date,
    DATEDIFF(CURDATE(), e.start_date) as days_overdue
FROM Students st
JOIN Enrollments e ON st.student_id = e.student_id
JOIN Programs p ON e.program_id = p.program_id
JOIN Student_Parents sp ON st.student_id = sp.student_id
JOIN Parents pr ON sp.parent_id = pr.parent_id
WHERE e.payment_status = 'overdue' 
    AND sp.is_billing_contact = TRUE
ORDER BY days_overdue DESC;

-- 6. TRIAL STUDENTS WHO HAVEN'T ENROLLED
SELECT 
    CONCAT(st.first_name, ' ', st.last_name) as student_name,
    CONCAT(pr.first_name, ' ', pr.last_name) as parent_name,
    pr.email,
    pr.phone,
    p.program_name,
    s.session_date as trial_date,
    DATEDIFF(CURDATE(), s.session_date) as days_since_trial,
    sb.student_feedback_rating
FROM Students st
JOIN Enrollments e ON st.student_id = e.student_id
JOIN Programs p ON e.program_id = p.program_id
JOIN Session_Bookings sb ON e.enrollment_id = sb.enrollment_id
JOIN Sessions s ON sb.session_id = s.session_id
JOIN Student_Parents sp ON st.student_id = sp.student_id
JOIN Parents pr ON sp.parent_id = pr.parent_id
WHERE e.enrollment_type = 'trial'
    AND s.session_date < CURDATE()
    AND sp.is_primary_contact = TRUE
    AND st.student_id NOT IN (
        SELECT DISTINCT student_id 
        FROM Enrollments 
        WHERE enrollment_type = 'weekly_recurring' 
        AND enrollment_status = 'active'
    )
ORDER BY days_since_trial DESC;

-- =====================================================
-- TUTOR MANAGEMENT QUERIES
-- =====================================================

-- 7. TUTOR UTILIZATION THIS WEEK
SELECT 
    CONCAT(t.first_name, ' ', t.last_name) as tutor_name,
    COUNT(s.session_id) as total_sessions,
    SUM(p.lesson_duration_minutes) / 60.0 as total_hours,
    AVG(COUNT(sb.student_id)) as avg_students_per_session,
    SUM(COUNT(sb.student_id) * p.price_per_session) as revenue_generated
FROM Tutors t
LEFT JOIN Sessions s ON t.tutor_id = s.tutor_id
LEFT JOIN Programs p ON s.program_id = p.program_id
LEFT JOIN Session_Bookings sb ON s.session_id = sb.session_id 
    AND sb.booking_status = 'confirmed'
WHERE s.session_date BETWEEN 
    DATE_SUB(CURDATE(), INTERVAL DAYOFWEEK(CURDATE())-1 DAY) 
    AND DATE_ADD(DATE_SUB(CURDATE(), INTERVAL DAYOFWEEK(CURDATE())-1 DAY), INTERVAL 6 DAY)
    AND t.status = 'active'
GROUP BY t.tutor_id
ORDER BY total_hours DESC;

-- 8. TUTOR AVAILABILITY FOR UPCOMING WEEK
SELECT 
    CONCAT(t.first_name, ' ', t.last_name) as tutor_name,
    ta.day_of_week,
    ta.start_time,
    ta.end_time,
    STRING_AGG(p.program_name, ', ') as can_teach_programs
FROM Tutors t
JOIN Tutor_Availability ta ON t.tutor_id = ta.tutor_id
JOIN Tutor_Programs tp ON t.tutor_id = tp.tutor_id
JOIN Programs p ON tp.program_id = p.program_id
WHERE t.status = 'active'
    AND ta.effective_date_start <= CURDATE()
    AND (ta.effective_date_end IS NULL OR ta.effective_date_end >= CURDATE())
    AND tp.proficiency_level IN ('certified', 'experienced')
GROUP BY t.tutor_id, ta.availability_id
ORDER BY tutor_name, 
    FIELD(ta.day_of_week, 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'),
    ta.start_time;

-- =====================================================
-- PROGRAM PERFORMANCE QUERIES
-- =====================================================

-- 9. PROGRAM POPULARITY AND REVENUE
SELECT 
    p.program_name,
    p.difficulty_level,
    COUNT(DISTINCT e.enrollment_id) as total_enrollments,
    COUNT(CASE WHEN e.enrollment_type = 'trial' THEN 1 END) as trial_enrollments,
    COUNT(CASE WHEN e.enrollment_type = 'weekly_recurring' THEN 1 END) as recurring_enrollments,
    SUM(e.total_amount) as total_revenue,
    SUM(e.amount_paid) as revenue_collected,
    AVG(sb.student_feedback_rating) as avg_rating
FROM Programs p
LEFT JOIN Enrollments e ON p.program_id = e.program_id
LEFT JOIN Session_Bookings sb ON e.enrollment_id = sb.enrollment_id
WHERE e.enrollment_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
GROUP BY p.program_id
ORDER BY total_enrollments DESC;

-- 10. TRIAL TO ENROLLMENT CONVERSION RATE
SELECT 
    p.program_name,
    COUNT(CASE WHEN e.enrollment_type = 'trial' THEN 1 END) as trial_students,
    COUNT(CASE WHEN e.enrollment_type = 'weekly_recurring' THEN 1 END) as converted_students,
    ROUND(
        (COUNT(CASE WHEN e.enrollment_type = 'weekly_recurring' THEN 1 END) * 100.0) / 
        NULLIF(COUNT(CASE WHEN e.enrollment_type = 'trial' THEN 1 END), 0), 
        2
    ) as conversion_rate_percent
FROM Programs p
LEFT JOIN Enrollments e ON p.program_id = e.program_id
WHERE e.enrollment_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
GROUP BY p.program_id
HAVING trial_students > 0
ORDER BY conversion_rate_percent DESC;

-- =====================================================
-- FINANCIAL REPORTS
-- =====================================================

-- 11. MONTHLY REVENUE REPORT
SELECT 
    DATE_FORMAT(pay.payment_date, '%Y-%m') as month,
    COUNT(DISTINCT pay.enrollment_id) as paying_students,
    SUM(pay.amount) as total_revenue,
    AVG(pay.amount) as avg_payment,
    COUNT(pay.payment_id) as total_transactions
FROM Payments pay
WHERE pay.payment_status = 'completed'
    AND pay.payment_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(pay.payment_date, '%Y-%m')
ORDER BY month DESC;

-- 12. OUTSTANDING PAYMENTS SUMMARY
SELECT 
    e.payment_status,
    COUNT(e.enrollment_id) as enrollment_count,
    SUM(e.total_amount - e.amount_paid) as total_outstanding,
    AVG(e.total_amount - e.amount_paid) as avg_outstanding
FROM Enrollments e
WHERE e.enrollment_status = 'active'
    AND e.total_amount > e.amount_paid
GROUP BY e.payment_status
ORDER BY total_outstanding DESC;

-- =====================================================
-- OPERATIONAL EFFICIENCY QUERIES
-- =====================================================

-- 13. ROOM UTILIZATION
SELECT 
    zr.room_name,
    COUNT(s.session_id) as total_sessions_this_week,
    SUM(p.lesson_duration_minutes) / 60.0 as total_hours_used,
    COUNT(DISTINCT s.session_date) as days_used,
    AVG(COUNT(sb.student_id)) as avg_students_per_session
FROM Zoom_Rooms zr
LEFT JOIN Sessions s ON zr.room_id = s.zoom_room_id
LEFT JOIN Programs p ON s.program_id = p.program_id
LEFT JOIN Session_Bookings sb ON s.session_id = sb.session_id 
    AND sb.booking_status = 'confirmed'
WHERE s.session_date BETWEEN 
    DATE_SUB(CURDATE(), INTERVAL DAYOFWEEK(CURDATE())-1 DAY) 
    AND DATE_ADD(DATE_SUB(CURDATE(), INTERVAL DAYOFWEEK(CURDATE())-1 DAY), INTERVAL 6 DAY)
GROUP BY zr.room_id
ORDER BY total_hours_used DESC;

-- 14. ATTENDANCE TRACKING
SELECT 
    p.program_name,
    COUNT(sb.session_id) as total_bookings,
    COUNT(CASE WHEN sb.attendance_status = 'present' THEN 1 END) as attended,
    COUNT(CASE WHEN sb.attendance_status = 'absent' THEN 1 END) as absent,
    COUNT(CASE WHEN sb.attendance_status = 'late' THEN 1 END) as late,
    ROUND(
        (COUNT(CASE WHEN sb.attendance_status = 'present' THEN 1 END) * 100.0) / 
        NULLIF(COUNT(sb.session_id), 0), 
        2
    ) as attendance_rate_percent
FROM Programs p
JOIN Sessions s ON p.program_id = s.program_id
JOIN Session_Bookings sb ON s.session_id = sb.session_id
WHERE s.session_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
    AND sb.booking_status = 'confirmed'
GROUP BY p.program_id
ORDER BY attendance_rate_percent DESC;

-- =====================================================
-- QUICK ADMIN ACTIONS
-- =====================================================

-- 15. FIND AVAILABLE TIME SLOTS FOR A PROGRAM
-- Replace @program_id, @target_date with actual values
SET @program_id = 1;  -- Replace with actual program ID
SET @target_date = '2024-01-15';  -- Replace with target date

SELECT 
    CONCAT(t.first_name, ' ', t.last_name) as tutor_name,
    ta.start_time,
    ta.end_time,
    zr.room_name
FROM Tutors t
JOIN Tutor_Availability ta ON t.tutor_id = ta.tutor_id
JOIN Tutor_Programs tp ON t.tutor_id = tp.tutor_id
CROSS JOIN Zoom_Rooms zr
WHERE tp.program_id = @program_id
    AND tp.proficiency_level IN ('certified', 'experienced')
    AND ta.day_of_week = LOWER(DAYNAME(@target_date))
    AND ta.effective_date_start <= @target_date
    AND (ta.effective_date_end IS NULL OR ta.effective_date_end >= @target_date)
    AND t.status = 'active'
    AND zr.is_active = TRUE
    -- Check tutor is not already booked
    AND NOT EXISTS (
        SELECT 1 FROM Sessions s 
        WHERE s.tutor_id = t.tutor_id 
        AND s.session_date = @target_date
        AND s.start_time < ta.end_time 
        AND s.end_time > ta.start_time
    )
    -- Check room is not already booked
    AND NOT EXISTS (
        SELECT 1 FROM Sessions s 
        WHERE s.zoom_room_id = zr.room_id 
        AND s.session_date = @target_date
        AND s.start_time < ta.end_time 
        AND s.end_time > ta.start_time
    )
ORDER BY ta.start_time, tutor_name;

-- 16. GET STUDENT'S COMPLETE PROFILE
-- Replace @student_id with actual student ID
SET @student_id = 1;

SELECT 
    -- Student Info
    CONCAT(st.first_name, ' ', st.last_name) as student_name,
    st.age_group,
    st.skill_level,
    st.status,
    
    -- Parent Info
    CONCAT(pr.first_name, ' ', pr.last_name) as parent_name,
    pr.email,
    pr.phone,
    sp.relationship_type,
    sp.is_primary_contact,
    sp.is_billing_contact,
    
    -- Enrollment Info
    p.program_name,
    e.enrollment_type,
    e.enrollment_status,
    e.payment_status,
    e.start_date,
    e.end_date,
    
    -- Session Stats
    COUNT(sb.session_id) as total_sessions_booked,
    COUNT(CASE WHEN sb.attendance_status = 'present' THEN 1 END) as sessions_attended,
    AVG(sb.student_feedback_rating) as avg_feedback_rating
    
FROM Students st
LEFT JOIN Student_Parents sp ON st.student_id = sp.student_id
LEFT JOIN Parents pr ON sp.parent_id = pr.parent_id
LEFT JOIN Enrollments e ON st.student_id = e.student_id
LEFT JOIN Programs p ON e.program_id = p.program_id
LEFT JOIN Session_Bookings sb ON e.enrollment_id = sb.enrollment_id
WHERE st.student_id = @student_id
GROUP BY st.student_id, pr.parent_id, e.enrollment_id;

-- =====================================================
-- END OF ADMIN QUERIES
-- =====================================================