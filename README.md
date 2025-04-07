# **Google Cloud Logs Analysis Project**

## **Overview**
This project involves setting up a MySQL database, migrating data to Cloud Spanner, integrating it with BigQuery, and performing analytics on user activity logs. The steps include enabling APIs, configuring IAM roles, and using external queries for successful data migration and analysis.

---

## **Step 1: Setting Up MySQL in Google Cloud**

### **1. Create MySQL Instance in Cloud SQL**
- Navigate to **Google Cloud Console** → **Cloud SQL**
- Click **Create Instance** → Select **MySQL**
- Configure instance details (region, machine type, storage, etc.)
- Set **root password** and create the instance

### **2. Create a Database in MySQL**
```sql
CREATE DATABASE cloud_LOGS;
```

### **3. Create the User Activity Logs Table**
```sql
CREATE TABLE user_activity_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    action VARCHAR(100) NOT NULL,
    module VARCHAR(100),
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    device_info VARCHAR(255),
    browser_info VARCHAR(255),
    operating_system VARCHAR(100),
    referrer_url VARCHAR(500),
    location VARCHAR(255),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    session_id VARCHAR(255),
    user_agent TEXT,
    additional_info_text STRING(MAX)
);
```

### **4. Insert Sample Data**
```sql
INSERT INTO user_activity_logs
(user_id, username, email, action, module, ip_address, device_info, browser_info,
operating_system, referrer_url, location, latitude, longitude, session_id, user_agent, additional_info_text)
VALUES
(101, 'john_doe', 'john@example.com', 'Login', 'Authentication', '192.168.1.10',
'Windows 10 - Dell XPS', 'Chrome 110', 'Windows 10', 'https://example.com/home',
'New York, USA', 40.712776, -74.005974, 'ABC123',
'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', '{"login_method": "OAuth", "2FA": true}');
```

---

## **Step 2: Migrating MySQL Data to Cloud Spanner**

### **1. Enable Required APIs in Google Cloud Console**
- Cloud Spanner API
- IAM & Admin API
- Cloud SQL Admin API
- BigQuery API

### **2. Create a Cloud Spanner Instance and Database**
```sh
gcloud spanner instances create logs-instance --config=regional-us-central1 --nodes=1 --description="User Logs Spanner Instance"
gcloud spanner databases create cloud_LOGS --instance=logs-instance
```

### **3. Grant IAM Permissions for Spanner**
```sh
gcloud projects add-iam-policy-binding [PROJECT_ID] \
    --member=user:[YOUR_EMAIL] \
    --role=roles/spanner.admin
```

### **4. Migrate MySQL Data to Spanner**
```sh
mysqldump --host=[MYSQL_HOST] --user=root --password=[PASSWORD] --databases cloud_LOGS --hex-blob --no-data > schema.sql
gcloud spanner databases ddl update cloud_LOGS --instance=logs-instance --ddl="$(cat schema.sql)"
```

### **5. Verify Migration Success**
```sh
gcloud spanner databases execute-sql cloud_LOGS --instance=logs-instance --sql="SELECT COUNT(*) FROM user_activity_logs;"
```

---

## **Step 3: Connecting Cloud Spanner to BigQuery**

### **1. Install BigQuery CLI (if not already installed)**
```sh
gcloud components install bq
```

### **2. Create a BigQuery Dataset**
```sh
bq --location=US mk -d logactivitiesanalysis
```

### **3. Connect BigQuery to Cloud Spanner Using an External Table**
```sql
CREATE OR REPLACE EXTERNAL TABLE logactivitiesanalysis.cloud_logs
WITH CONNECTION `gcp_project.region.connection_id`
OPTIONS (
    endpoint = 'spanner.googleapis.com',
    database = 'projects/[PROJECT_ID]/instances/logs-instance/databases/cloud_LOGS'
);
```

### **4. Validate the Connection in BigQuery**
```sql
SELECT * FROM logactivitiesanalysis.cloud_logs.user_activity_logs LIMIT 10;
```

---

## **Step 4: Data Analysis in BigQuery**

### **1. Query to Find Daily Active Users**
```sql
SELECT
    DATE(activity_timestamp) AS activity_date,  
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(*) AS total_actions
FROM `logactivitiesanalysis.cloud_logs.user_activity_logs`
WHERE activity_timestamp IS NOT NULL
GROUP BY activity_date
ORDER BY activity_date;
```

### **2. Fixing `NULL` Issue in `activity_date`**
```sql
SELECT
    DATE(TIMESTAMP_SECONDS(CAST(session_id AS INT64))) AS activity_date,  
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(*) AS total_actions
FROM `logactivitiesanalysis.cloud_logs.user_activity_logs`
WHERE SAFE_CAST(session_id AS INT64) IS NOT NULL
GROUP BY activity_date
ORDER BY activity_date;
```

### **3. Identify Returning Users**
```sql
WITH first_activity AS (
    SELECT
        user_id,
        MIN(DATE(activity_timestamp)) AS first_action
    FROM logactivitiesanalysis.cloud_logs.user_activity_logs
    GROUP BY user_id
)
SELECT
    DATE(activity_timestamp) AS activity_date,
    COUNT(DISTINCT user_id) AS returning_users
FROM logactivitiesanalysis.cloud_logs.user_activity_logs
JOIN first_activity USING (user_id)
WHERE DATE(activity_timestamp) > first_action
GROUP BY activity_date
ORDER BY activity_date;
```

### **4. User Engagement Trends by Action Type**
```sql
SELECT
    action,
    COUNT(*) AS total_occurrences
FROM logactivitiesanalysis.cloud_logs.user_activity_logs
GROUP BY action
ORDER BY total_occurrences DESC;
```

---

## **Conclusion & Learnings**
- Resolved `NULL` values in `activity_date` using proper timestamp conversions.
- Fixed migration issues by using Spanner CLI and IAM permissions.
- Successfully connected BigQuery with Cloud Spanner using `EXTERNAL_QUERY`.
- Performed insights like daily active users, engagement trends, and returning users.
- Created interactive visualizations using BigQuery Console and Looker Studio.

---

## **Contributors**
- **Dhanyatha S** - Project Implementation & Documentation

---

This project provides a **complete pipeline from MySQL to BigQuery analytics**, ensuring efficient data storage, migration, and analysis. 🚀

