-- =====================================================
-- Online Coding School Database Schema
-- =====================================================

-- =====================================================
-- Core Entity Tables
-- =====================================================

-- Students table
CREATE TABLE Students (
    student_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    age_group ENUM('7-9', '10-12', '13-15') NOT NULL,
    skill_level ENUM('beginner', 'intermediate', 'advanced') DEFAULT 'beginner',
    preferred_timezone VARCHAR(50),
    notes TEXT,
    status ENUM('active', 'inactive', 'graduated') DEFAULT 'active',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_age_group_status (age_group, status),
    INDEX idx_student_name (last_name, first_name)
);

-- Parents table
CREATE TABLE Parents (
    parent_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    country VARCHAR(50),
    timezone VARCHAR(50),
    preferred_contact_method ENUM('email', 'phone', 'sms') DEFAULT 'email',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_parent_email (email),
    INDEX idx_parent_name (last_name, first_name)
);

-- Junction table for Students and Parents (many-to-many)
CREATE TABLE Student_Parents (
    student_id INT,
    parent_id INT,
    relationship_type ENUM('mother', 'father', 'guardian', 'other') NOT NULL,
    is_primary_contact BOOLEAN DEFAULT FALSE,
    is_billing_contact BOOLEAN DEFAULT FALSE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (student_id, parent_id),
    FOREIGN KEY (student_id) REFERENCES Students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES Parents(parent_id) ON DELETE CASCADE,
    
    INDEX idx_primary_contact (is_primary_contact),
    INDEX idx_billing_contact (is_billing_contact)
);

-- Tutors table
CREATE TABLE Tutors (
    tutor_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    timezone VARCHAR(50) NOT NULL,
    hourly_rate DECIMAL(10,2),
    bio TEXT,
    years_experience INT DEFAULT 0,
    certifications TEXT,
    profile_image_url VARCHAR(255),
    status ENUM('active', 'inactive', 'on_leave') DEFAULT 'active',
    hire_date DATE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_tutor_status (status),
    INDEX idx_tutor_timezone (timezone)
);

-- Programs table
CREATE TABLE Programs (
    program_id INT PRIMARY KEY AUTO_INCREMENT,
    program_name VARCHAR(50) NOT NULL,
    description TEXT,
    recommended_age_min INT NOT NULL,
    recommended_age_max INT NOT NULL,
    difficulty_level ENUM('beginner', 'intermediate', 'advanced') NOT NULL,
    duration_weeks INT DEFAULT 12,
    lesson_duration_minutes INT DEFAULT 60,
    max_students_per_session INT DEFAULT 6,
    price_per_session DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_program_active (is_active),
    INDEX idx_program_age (recommended_age_min, recommended_age_max),
    INDEX idx_program_difficulty (difficulty_level)
);

-- Junction table for Tutors and Programs (many-to-many)
CREATE TABLE Tutor_Programs (
    tutor_id INT,
    program_id INT,
    proficiency_level ENUM('certified', 'experienced', 'learning') NOT NULL,
    date_certified DATE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (tutor_id, program_id),
    FOREIGN KEY (tutor_id) REFERENCES Tutors(tutor_id) ON DELETE CASCADE,
    FOREIGN KEY (program_id) REFERENCES Programs(program_id) ON DELETE CASCADE,
    
    INDEX idx_proficiency (proficiency_level)
);

-- Zoom Rooms table
CREATE TABLE Zoom_Rooms (
    room_id INT PRIMARY KEY AUTO_INCREMENT,
    room_name VARCHAR(100) NOT NULL,
    zoom_meeting_url VARCHAR(255),
    zoom_meeting_id VARCHAR(50) UNIQUE,
    zoom_passcode VARCHAR(20),
    max_capacity INT DEFAULT 10,
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_room_active (is_active),
    INDEX idx_zoom_id (zoom_meeting_id)
);

-- =====================================================
-- Scheduling and Availability Tables
-- =====================================================

-- Tutor Availability table
CREATE TABLE Tutor_Availability (
    availability_id INT PRIMARY KEY AUTO_INCREMENT,
    tutor_id INT NOT NULL,
    day_of_week ENUM('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    timezone VARCHAR(50) NOT NULL,
    is_recurring BOOLEAN DEFAULT TRUE,
    effective_date_start DATE NOT NULL,
    effective_date_end DATE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (tutor_id) REFERENCES Tutors(tutor_id) ON DELETE CASCADE,
    
    INDEX idx_tutor_day (tutor_id, day_of_week),
    INDEX idx_availability_dates (effective_date_start, effective_date_end),
    
    CONSTRAINT chk_time_order CHECK (start_time < end_time)
);

-- Sessions table (unified for trials and regular lessons)
CREATE TABLE Sessions (
    session_id INT PRIMARY KEY AUTO_INCREMENT,
    program_id INT NOT NULL,
    tutor_id INT NOT NULL,
    zoom_room_id INT NOT NULL,
    session_type ENUM('trial', 'regular', 'makeup') NOT NULL,
    session_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    timezone VARCHAR(50) NOT NULL,
    max_students INT DEFAULT 6,
    session_status ENUM('scheduled', 'completed', 'cancelled', 'no_show') DEFAULT 'scheduled',
    lesson_plan_notes TEXT,
    homework_assigned TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (program_id) REFERENCES Programs(program_id),
    FOREIGN KEY (tutor_id) REFERENCES Tutors(tutor_id),
    FOREIGN KEY (zoom_room_id) REFERENCES Zoom_Rooms(room_id),
    
    -- Prevent double booking of tutors
    UNIQUE KEY unique_tutor_time (tutor_id, session_date, start_time),
    -- Prevent double booking of zoom rooms
    UNIQUE KEY unique_room_time (zoom_room_id, session_date, start_time),
    
    INDEX idx_session_date_tutor (session_date, tutor_id),
    INDEX idx_session_program (program_id),
    INDEX idx_session_status (session_status),
    
    CONSTRAINT chk_session_time CHECK (start_time < end_time)
);

-- =====================================================
-- Enrollment and Booking Tables
-- =====================================================

-- Enrollments table
CREATE TABLE Enrollments (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    program_id INT NOT NULL,
    enrollment_type ENUM('trial', 'weekly_recurring') NOT NULL,
    enrollment_date DATE NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    sessions_per_week INT DEFAULT 1,
    preferred_day_of_week ENUM('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'),
    preferred_time_slot TIME,
    enrollment_status ENUM('active', 'paused', 'completed', 'cancelled') DEFAULT 'active',
    payment_status ENUM('pending', 'paid', 'overdue', 'refunded') DEFAULT 'pending',
    total_amount DECIMAL(10,2),
    amount_paid DECIMAL(10,2) DEFAULT 0.00,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (program_id) REFERENCES Programs(program_id),
    
    INDEX idx_student_enrollment_status (student_id, enrollment_status),
    INDEX idx_enrollment_payment_status (enrollment_status, payment_status),
    INDEX idx_enrollment_program (program_id),
    
    CONSTRAINT chk_amount_paid CHECK (amount_paid >= 0),
    CONSTRAINT chk_total_amount CHECK (total_amount > 0)
);

-- Session Bookings table (links students to specific sessions)
CREATE TABLE Session_Bookings (
    booking_id INT PRIMARY KEY AUTO_INCREMENT,
    session_id INT NOT NULL,
    student_id INT NOT NULL,
    enrollment_id INT NOT NULL,
    booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    booking_status ENUM('confirmed', 'waitlist', 'cancelled', 'completed', 'no_show') DEFAULT 'confirmed',
    attendance_status ENUM('present', 'absent', 'late') NULL,
    student_feedback_rating INT CHECK (student_feedback_rating BETWEEN 1 AND 5),
    tutor_notes TEXT,
    homework_completion BOOLEAN,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (session_id) REFERENCES Sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (enrollment_id) REFERENCES Enrollments(enrollment_id),
    
    -- Prevent duplicate bookings
    UNIQUE KEY unique_student_session (session_id, student_id),
    
    INDEX idx_booking_session_student (session_id, student_id),
    INDEX idx_booking_student_status (student_id, booking_status),
    INDEX idx_booking_enrollment (enrollment_id)
);

-- =====================================================
-- Payment and Progress Tables
-- =====================================================

-- Payments table
CREATE TABLE Payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    enrollment_id INT NOT NULL,
    parent_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method ENUM('credit_card', 'paypal', 'bank_transfer', 'cash') NOT NULL,
    payment_status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    transaction_id VARCHAR(100),
    invoice_number VARCHAR(50),
    payment_period_start DATE,
    payment_period_end DATE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (enrollment_id) REFERENCES Enrollments(enrollment_id),
    FOREIGN KEY (parent_id) REFERENCES Parents(parent_id),
    
    INDEX idx_payment_enrollment (enrollment_id),
    INDEX idx_payment_parent (parent_id),
    INDEX idx_payment_status_date (payment_status, payment_date),
    INDEX idx_transaction_id (transaction_id),
    
    CONSTRAINT chk_payment_amount CHECK (amount > 0)
);

-- Student Progress table
CREATE TABLE Student_Progress (
    progress_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    program_id INT NOT NULL,
    session_id INT NOT NULL,
    skill_assessed VARCHAR(100) NOT NULL,
    competency_level INT CHECK (competency_level BETWEEN 1 AND 5),
    assessment_date DATE NOT NULL,
    tutor_comments TEXT,
    milestone_achieved VARCHAR(200),
    next_learning_goal VARCHAR(200),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (program_id) REFERENCES Programs(program_id),
    FOREIGN KEY (session_id) REFERENCES Sessions(session_id),
    
    INDEX idx_progress_student_program (student_id, program_id),
    INDEX idx_progress_session (session_id),
    INDEX idx_progress_date (assessment_date)
);

-- =====================================================
-- Sample Data Population
-- =====================================================

-- Insert sample programs
INSERT INTO Programs (program_name, description, recommended_age_min, recommended_age_max, difficulty_level, price_per_session) VALUES
('Scratch', 'Visual programming with Scratch blocks', 7, 12, 'beginner', 25.00),
('Minecraft', 'Learn coding through Minecraft modding', 8, 15, 'beginner', 30.00),
('Roblox', 'Game development with Roblox Studio', 9, 15, 'intermediate', 35.00),
('Python', 'Text-based programming with Python', 10, 15, 'intermediate', 40.00),
('JavaScript', 'Web development with JavaScript', 12, 15, 'advanced', 45.00);

-- Insert sample zoom rooms
INSERT INTO Zoom_Rooms (room_name, zoom_meeting_id, zoom_passcode, max_capacity) VALUES
('Coding Room 1', '123456789', 'code123', 8),
('Coding Room 2', '987654321', 'learn456', 6),
('Coding Room 3', '555666777', 'fun789', 10);

-- =====================================================
-- Useful Views for Admin Dashboard
-- =====================================================

-- Daily Schedule View
CREATE VIEW daily_schedule AS
SELECT 
    s.session_date,
    s.start_time,
    s.end_time,
    p.program_name,
    CONCAT(t.first_name, ' ', t.last_name) as tutor_name,
    zr.room_name,
    s.session_status,
    COUNT(sb.student_id) as enrolled_students,
    s.max_students
FROM Sessions s
JOIN Programs p ON s.program_id = p.program_id
JOIN Tutors t ON s.tutor_id = t.tutor_id
JOIN Zoom_Rooms zr ON s.zoom_room_id = zr.room_id
LEFT JOIN Session_Bookings sb ON s.session_id = sb.session_id 
    AND sb.booking_status = 'confirmed'
GROUP BY s.session_id
ORDER BY s.session_date, s.start_time;

-- Student Enrollment Overview
CREATE VIEW student_enrollment_overview AS
SELECT 
    CONCAT(st.first_name, ' ', st.last_name) as student_name,
    st.age_group,
    p.program_name,
    e.enrollment_type,
    e.enrollment_status,
    e.payment_status,
    e.start_date,
    e.end_date,
    COUNT(sb.session_id) as sessions_booked,
    SUM(CASE WHEN sb.attendance_status = 'present' THEN 1 ELSE 0 END) as sessions_attended
FROM Students st
JOIN Enrollments e ON st.student_id = e.student_id
JOIN Programs p ON e.program_id = p.program_id
LEFT JOIN Session_Bookings sb ON e.enrollment_id = sb.enrollment_id
GROUP BY st.student_id, e.enrollment_id;

-- =====================================================
-- Triggers for Business Logic
-- =====================================================

-- Update enrollment amount paid when payment is completed
DELIMITER //
CREATE TRIGGER update_enrollment_payment 
AFTER UPDATE ON Payments
FOR EACH ROW
BEGIN
    IF NEW.payment_status = 'completed' AND OLD.payment_status != 'completed' THEN
        UPDATE Enrollments 
        SET amount_paid = amount_paid + NEW.amount,
            payment_status = CASE 
                WHEN amount_paid + NEW.amount >= total_amount THEN 'paid'
                ELSE 'pending'
            END
        WHERE enrollment_id = NEW.enrollment_id;
    END IF;
END//
DELIMITER ;

-- =====================================================
-- End of Schema
-- =====================================================