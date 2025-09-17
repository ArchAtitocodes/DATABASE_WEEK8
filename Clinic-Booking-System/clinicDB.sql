-- QUESTION 1
-- Clinic Booking System SQL Schema
-- Single .sql file containing CREATE DATABASE, CREATE TABLE statements, and relationship constraints
-- Designed for MySQL 8+ (InnoDB engine preferred)

DROP DATABASE IF EXISTS clinic_db;
CREATE DATABASE clinic_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE clinic_db;

-- --------------------------------------------------
-- Core lookup tables
-- --------------------------------------------------

CREATE TABLE departments (
  department_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE rooms (
  room_id INT AUTO_INCREMENT PRIMARY KEY,
  department_id INT NOT NULL,
  room_number VARCHAR(20) NOT NULL,
  floor INT,
  notes TEXT,
  UNIQUE (department_id, room_number),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_rooms_department FOREIGN KEY (department_id) REFERENCES departments(department_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE specialties (
  specialty_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE insurance_providers (
  provider_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL UNIQUE,
  contact_number VARCHAR(30),
  website VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE medications (
  medication_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  manufacturer VARCHAR(255),
  active_ingredient VARCHAR(255),
  form VARCHAR(50), -- tablet, syrup, injection
  notes TEXT,
  UNIQUE (name, manufacturer),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- --------------------------------------------------
-- People: patients, doctors, staff
-- --------------------------------------------------

CREATE TABLE patients (
  patient_id INT AUTO_INCREMENT PRIMARY KEY,
  national_id VARCHAR(50) UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  gender ENUM('Male','Female','Other') DEFAULT 'Other',
  date_of_birth DATE,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(30) UNIQUE,
  address TEXT,
  emergency_contact_name VARCHAR(150),
  emergency_contact_phone VARCHAR(30),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE doctors (
  doctor_id INT AUTO_INCREMENT PRIMARY KEY,
  staff_number VARCHAR(50) UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(30) UNIQUE,
  department_id INT,
  room_id INT,
  hire_date DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_doctors_department FOREIGN KEY (department_id) REFERENCES departments(department_id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_doctors_room FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE staff (
  staff_id INT AUTO_INCREMENT PRIMARY KEY,
  staff_number VARCHAR(50) UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  role VARCHAR(100) NOT NULL,
  department_id INT,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(30) UNIQUE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_staff_department FOREIGN KEY (department_id) REFERENCES departments(department_id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- Many-to-many: doctors <-> specialties
CREATE TABLE doctor_specialties (
  doctor_id INT NOT NULL,
  specialty_id INT NOT NULL,
  PRIMARY KEY (doctor_id, specialty_id),
  CONSTRAINT fk_docspec_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_docspec_specialty FOREIGN KEY (specialty_id) REFERENCES specialties(specialty_id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Patient insurance (one patient can have multiple policies)
CREATE TABLE patient_insurance (
  patient_insurance_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  provider_id INT NOT NULL,
  policy_number VARCHAR(100) NOT NULL,
  coverage_details TEXT,
  valid_from DATE,
  valid_to DATE,
  UNIQUE(patient_id, provider_id, policy_number),
  CONSTRAINT fk_pi_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pi_provider FOREIGN KEY (provider_id) REFERENCES insurance_providers(provider_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Appointments & workflow
-- --------------------------------------------------

CREATE TABLE appointment_statuses (
  status_code VARCHAR(30) PRIMARY KEY,
  description VARCHAR(200)
) ENGINE=InnoDB;

INSERT INTO appointment_statuses (status_code, description) VALUES
('SCHEDULED','Appointment is scheduled'),
('COMPLETED','Appointment completed'),
('CANCELLED','Appointment cancelled'),
('NO_SHOW','Patient did not show up');

CREATE TABLE appointments (
  appointment_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  doctor_id INT NOT NULL,
  scheduled_start DATETIME NOT NULL,
  scheduled_end DATETIME NOT NULL,
  room_id INT,
  status_code VARCHAR(30) NOT NULL DEFAULT 'SCHEDULED',
  reason TEXT,
  created_by INT, -- staff_id who created/managed the appointment
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_appointment_time CHECK (scheduled_end > scheduled_start),
  CONSTRAINT fk_appointment_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_appointment_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_appointment_room FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_appointment_status FOREIGN KEY (status_code) REFERENCES appointment_statuses(status_code) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_appointment_creator FOREIGN KEY (created_by) REFERENCES staff(staff_id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- Visit/treatment records (one-to-one or one-to-many depending on model)
CREATE TABLE visits (
  visit_id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT UNIQUE, -- if 1-to-1 with appointment; remove UNIQUE to allow multiple visits per appointment
  patient_id INT NOT NULL,
  doctor_id INT NOT NULL,
  visit_datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  summary TEXT,
  diagnosis TEXT,
  follow_up_in_days INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_visit_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_visit_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_visit_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Prescriptions & prescription items
CREATE TABLE prescriptions (
  prescription_id INT AUTO_INCREMENT PRIMARY KEY,
  visit_id INT NOT NULL,
  prescribed_by INT NOT NULL, -- doctor_id
  prescribed_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notes TEXT,
  CONSTRAINT fk_presc_visit FOREIGN KEY (visit_id) REFERENCES visits(visit_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_presc_doctor FOREIGN KEY (prescribed_by) REFERENCES doctors(doctor_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE prescription_items (
  prescription_item_id INT AUTO_INCREMENT PRIMARY KEY,
  prescription_id INT NOT NULL,
  medication_id INT NOT NULL,
  dosage VARCHAR(100) NOT NULL,
  frequency VARCHAR(100),
  duration_days INT,
  instructions TEXT,
  CONSTRAINT fk_pi_prescription FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pi_medication FOREIGN KEY (medication_id) REFERENCES medications(medication_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Billing: invoices and payments
-- --------------------------------------------------

CREATE TABLE invoices (
  invoice_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  visit_id INT,
  invoice_date DATE NOT NULL DEFAULT (CURRENT_DATE()),
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  paid_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  status ENUM('UNPAID','PARTIAL','PAID','CANCELLED') NOT NULL DEFAULT 'UNPAID',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_invoice_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_invoice_visit FOREIGN KEY (visit_id) REFERENCES visits(visit_id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT NOT NULL,
  payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  amount DECIMAL(12,2) NOT NULL,
  payment_method ENUM('CASH','CARD','MOBILE','INSURANCE') NOT NULL,
  reference VARCHAR(200),
  recorded_by INT, -- staff_id
  CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_payment_staff FOREIGN KEY (recorded_by) REFERENCES staff(staff_id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Indexes and useful constraints
-- --------------------------------------------------

CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_doctor ON appointments(doctor_id);
CREATE INDEX idx_visits_patient ON visits(patient_id);
CREATE INDEX idx_invoices_patient ON invoices(patient_id);

-- --------------------------------------------------
-- Sample data (small) to help testing
-- --------------------------------------------------

INSERT INTO departments (name, description) VALUES
('General Medicine','General outpatient department'),
('Pediatrics','Children health'),
('Radiology','Imaging department');

INSERT INTO rooms (department_id, room_number, floor) VALUES
(1,'G-101',1),
(2,'P-201',2),
(3,'R-305',3);

INSERT INTO specialties (name, description) VALUES
('General Practitioner','Primary care physician'),
('Pediatrician','Children specialist'),
('Radiologist','Imaging specialist');

INSERT INTO doctors (staff_number, first_name, last_name, email, phone, department_id, room_id) VALUES
('D1001','Alice','Mwangi','alice.mwangi@example.com','0711000001',1,1),
('D1002','Brian','Otieno','brian.otieno@example.com','0711000002',2,2);

INSERT INTO doctor_specialties (doctor_id, specialty_id) VALUES
(1,1),(2,2);

INSERT INTO patients (national_id, first_name, last_name, gender, date_of_birth, email, phone, address) VALUES
('12345678','John','Karanja','Male','1985-04-15','john.karanja@example.com','0712000001','Nairobi'),
('87654321','Mary','Wambui','Female','1990-09-10','mary.wambui@example.com','0712000002','Nairobi');

INSERT INTO staff (staff_number, first_name, last_name, role, department_id, email, phone) VALUES
('S1001','Grace','Njeri','Receptionist',1,'grace.njeri@example.com','0713000001');

-- schedule an appointment
INSERT INTO appointments (patient_id, doctor_id, scheduled_start, scheduled_end, room_id, created_by)
VALUES (1,1,'2025-09-20 09:00:00','2025-09-20 09:30:00',1,1);

-- Example visit and prescription
INSERT INTO visits (appointment_id, patient_id, doctor_id, summary, diagnosis) VALUES (1,1,1,'Visited for cough and fever','Upper respiratory infection');

INSERT INTO prescriptions (visit_id, prescribed_by, notes) VALUES (1,1,'Paracetamol and rest');

-- End of file
