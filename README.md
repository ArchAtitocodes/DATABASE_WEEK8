# 🏥 Clinic Booking System Database (MySQL)

## 📌 Project Overview

This project implements a **relational database management system (RDBMS)** for a **Clinic Booking System** using **MySQL**. It is designed to handle patient management, doctor information, appointments, visits, prescriptions, billing, and insurance integration.

The schema follows relational database design principles with **primary keys, foreign keys, unique constraints, relationships (1-to-1, 1-to-many, many-to-many), and indexing** for optimized queries.

---

## 🎯 Features

* **Patient Management** – Store and manage patient records, contacts, and insurance details.
* **Doctor & Staff Management** – Track doctors, specialties, staff roles, and departments.
* **Appointment Scheduling** – Manage bookings, appointment statuses, and assigned rooms.
* **Visits & Treatments** – Record diagnoses, visit summaries, and follow-up plans.
* **Prescriptions** – Store prescriptions and associated medications.
* **Billing System** – Generate invoices, accept multiple payment methods, and track balances.
* **Insurance Integration** – Link patients with insurance providers and policies.
* **Department & Room Allocation** – Organize hospital rooms and departments.

---

## 🗂️ Database Schema

### Core Tables

* **departments** – List of hospital departments.
* **rooms** – Rooms allocated within departments.
* **specialties** – Medical specialties.
* **insurance\_providers** – Insurance companies.
* **medications** – Available medications.

### People

* **patients** – Patient information.
* **doctors** – Doctors assigned to departments and rooms.
* **staff** – Non-doctor staff (receptionists, admin, etc.).

### Relationships

* **doctor\_specialties** – Many-to-Many between doctors and specialties.
* **patient\_insurance** – Many-to-Many between patients and insurance providers.

### Workflow

* **appointment\_statuses** – Possible states of an appointment.
* **appointments** – Bookings between patients and doctors.
* **visits** – Records of medical visits linked to appointments.
* **prescriptions** – Issued prescriptions.
* **prescription\_items** – Medications prescribed per prescription.

### Billing

* **invoices** – Patient invoices linked to visits.
* **payments** – Payments made toward invoices.

---

## ⚙️ Installation & Setup

1. **Install MySQL**

   ```bash
   sudo apt-get install mysql-server
   ```

2. **Login to MySQL**

   ```bash
   mysql -u root -p
   ```

3. **Run the SQL Script**

   ```bash
   SOURCE path/to/clinic_db_schema.sql;
   ```

4. **Verify Database Creation**

   ```sql
   SHOW DATABASES;
   USE clinic_db;
   SHOW TABLES;
   ```

---

## 📊 Example Queries

### Insert a new patient

```sql
INSERT INTO patients (national_id, first_name, last_name, gender, date_of_birth, email, phone, address)
VALUES ('11223344','James','Omondi','Male','1992-05-12','james.omondi@example.com','0714000001','Kisumu');
```

### Schedule an appointment

```sql
INSERT INTO appointments (patient_id, doctor_id, scheduled_start, scheduled_end, room_id, created_by)
VALUES (1, 1, '2025-09-25 10:00:00','2025-09-25 10:30:00',1,1);
```

### Retrieve all upcoming appointments for a doctor

```sql
SELECT a.appointment_id, p.first_name, p.last_name, a.scheduled_start, a.status_code
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
WHERE a.doctor_id = 1 AND a.status_code = 'SCHEDULED';
```

### Generate invoice for a visit

```sql
INSERT INTO invoices (patient_id, visit_id, total_amount, paid_amount, status)
VALUES (1, 1, 2000.00, 0.00, 'UNPAID');
```

### Record payment

```sql
INSERT INTO payments (invoice_id, amount, payment_method, reference, recorded_by)
VALUES (1, 2000.00, 'MOBILE', 'MPESA123XYZ', 1);
```

---

## 📑 Deliverables

* **clinic\_db\_schema.sql** – Full database schema with sample data.
* **README.md** – Documentation (this file).

---

## ✅ Notes

* The schema is designed with **InnoDB** engine to support transactions and foreign keys.
* Indexes are created on commonly searched fields (patient\_id, doctor\_id, invoice\_id).
* Supports multiple billing/payment methods including **cash, card, mobile money, and insurance**.

---

## 👨‍💻 Author

**Eng. Stephen Odhiambo**
📧 Email: [stephen.odhiambo008@gmail.com](stephen.odhiambo008@gmail.com)
💻 Role: Database Designer & Developer
