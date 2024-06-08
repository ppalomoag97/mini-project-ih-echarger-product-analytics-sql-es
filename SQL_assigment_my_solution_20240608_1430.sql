USE mini_project;

-- LEVEL 1

-- Question 1: Number of users with sessions

SELECT count(distinct user_id) as Número_usuarios
FROM sessions as s;


-- Question 2: Number of chargers used by user with id 1
SELECT COUNT(distinct s.charger_id)
FROM sessions as s
WHERE user_id=1;

-- LEVEL 2

-- Question 3: Number of sessions per charger type (AC/DC):
SELECT c.type,
	 count(s.id) AS Número_sesiones
FROM chargers as c
JOIN sessions as s
ON s.charger_id = c.id
GROUP BY c.type ;

-- Question 4: Chargers being used by more than one user
SELECT s.charger_id,
count(distinct user_id) as Número_usuarios
FROM sessions as s
GROUP BY s.charger_id
HAVING count(distinct user_id)  > 1 ;

-- Question 5: Average session time per charger
SELECT s.charger_id,
ROUND(AVG(timestampdiff(MINUTE,s.start_time,s.end_time)),2) as Avg_session_time
FROM sessions as s
group by s.charger_id;

-- LEVEL 3

-- Question 6: Full username of users that have used more than one charger in one day (NOTE: for date only consider start_time)

SELECT u.name,
		u.surname
FROM users as u
JOIN (SELECT s.user_id, s.start_time, count(distinct charger_id) as N_chargers
		FROM sessions as s
        GROUP BY s.user_id,s.start_time
        HAVING count(distinct charger_id) >1
        ) sub
ON sub.user_id = u.id;

-- Question 7: Top 3 chargers with longer sessions
SELECT c.label,
max(ROUND(timestampdiff(MINUTE,s.start_time,s.end_time),2)) as session_time
FROM sessions as s
JOIN chargers as c
ON s.charger_id = c.id
GROUP BY  c.label
ORDER BY session_time desc
LIMIT 3;

-- Question 8: Average number of users per charger (per charger in general, not per charger_id specifically)

SELECT sub.type, 
AVG(sub.users)
FROM(
	SELECT c.type, 
		count(s.user_id) as users
	FROM sessions s
		JOIN chargers c 
        ON s.charger_id = c.id 
	GROUP BY c.type) sub
GROUP BY sub.type;

-- Question 9: Top 3 users with more chargers being used
SELECT u.name,
		u.surname
FROM users as u
JOIN (SELECT s.user_id,  count(distinct charger_id) as N_chargers_used
		FROM sessions as s
        GROUP BY s.user_id
        ORDER BY  N_chargers_used desc limit 3
        ) sub
ON sub.user_id = u.id;

-- LEVEL 4

-- Question 10: Number of users that have used only AC chargers, DC chargers or both

SELECT 
    SUM(CASE WHEN charger_types = 'AC' THEN 1 ELSE 0 END) AS users_only_ac,
    SUM(CASE WHEN charger_types = 'DC' THEN 1 ELSE 0 END) AS users_only_dc,
    SUM(CASE WHEN charger_types LIKE '%AC%' AND charger_types LIKE '%DC%' THEN 1 ELSE 0 END) AS users_both_ac_dc
FROM ( SELECT s.user_id, 
             GROUP_CONCAT(DISTINCT c.type) AS charger_types
        FROM sessions s
			JOIN chargers c 
			ON s.charger_id = c.id
        GROUP BY s.user_id
    ) AS user_charger_types;
    
-- Question 11: Monthly average number of users per charger

SELECT charger_id, 
		AVG(sub.Number_users) as avg_monthly_users
FROM (SELECT s.charger_id, 
            MONTH(s.start_time) as month, 
            COUNT(DISTINCT user_id) as Number_users
        FROM sessions s
        GROUP BY s.charger_id, MONTH(s.start_time) 
    ) as sub
GROUP BY charger_id;

-- Question 12: Top 3 users per charger (for each charger, number of sessions)

WITH sessions AS (
    SELECT 
        s.charger_id, 
        u.name, 
        u.surname,
        COUNT(*) as session_count,
        ROW_NUMBER() OVER (PARTITION BY s.charger_id ORDER BY COUNT(*) DESC) as rank_
    FROM sessions s
		JOIN users as u
		ON s.user_id = u.id
	GROUP BY s.charger_id, s.user_id
)
SELECT charger_id, 
	   name,
       surname,
       session_count
FROM sessions
WHERE rank_ <= 3;

-- LEVEL 5

-- Question 13: Top 3 users with longest sessions per month (consider the month of start_time)
WITH sessions_month AS (
    SELECT name, 
        surname,
        month, 
        total_duration,
        ROW_NUMBER() OVER (PARTITION BY  month ORDER BY total_duration DESC) AS rank_
	FROM (SELECT u.name, 
			u.surname,
            MONTH(s.start_time) as month, 
            SUM(TIMESTAMPDIFF(MINUTE, start_time, end_time)) AS total_duration
        FROM sessions s
        JOIN users as u
		ON s.user_id = u.id
        GROUP BY s.user_id, MONTH(s.start_time) 
    ) as sub
)
SELECT 
    name,
    surname,
    month, 
    total_duration
FROM sessions_month
WHERE rank_ <= 3;
    
-- Question 14. Average time between sessions for each charger for each month (consider the month of start_time)

