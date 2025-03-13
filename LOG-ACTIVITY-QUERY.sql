select * from
EXTERNAL_QUERY(
  "logactivitiesanalysis.us-central1.d550181e-61be-4076-8382-ec21457b082d",
  """
  select * from user_activity_logs
  """
);

-- count the daily activity
select * from
EXTERNAL_QUERY(
  "logactivitiesanalysis.us-central1.d550181e-61be-4076-8382-ec21457b082d",
  """
SELECT 
    DATE(timestamp) AS activity_date,  
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(*) AS total_actions
FROM user_activity_logs
WHERE timestamp IS NOT NULL
GROUP BY activity_date
ORDER BY activity_date;
"""
);

-- Top User Action
select * from
EXTERNAL_QUERY(
  "logactivitiesanalysis.us-central1.d550181e-61be-4076-8382-ec21457b082d",
  """
SELECT 
    action, 
    COUNT(*) AS action_count 
FROM user_activity_logs
GROUP BY action
ORDER BY action_count DESC
LIMIT 10;

"""
);



-- User By Location
select * from
EXTERNAL_QUERY(
  "logactivitiesanalysis.us-central1.d550181e-61be-4076-8382-ec21457b082d",
  """
    SELECT 
        location, 
        COUNT(DISTINCT user_id) AS user_count
    FROM user_activity_logs
    GROUP BY location
    ORDER BY user_count DESC
    LIMIT 10;
"""
);

-- Device Usage
select * from
EXTERNAL_QUERY(
  "logactivitiesanalysis.us-central1.d550181e-61be-4076-8382-ec21457b082d",
  """
    SELECT 
      device_info, 
      COUNT(*) AS usage_count
    FROM user_activity_logs
    GROUP BY device_info
    ORDER BY usage_count DESC
    LIMIT 10;

"""
);
