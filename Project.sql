--Определить регионы с наибольшим количеством зарегистрированных доноров.
SELECT
	region,
	COUNT(id) AS count_donor
FROM donorsearch.user_anon_data
GROUP BY region
ORDER BY count_donor DESC
LIMIT 4;

--Изучить динамику общего количества донаций в месяц за 2022 и 2023 годы.
SELECT 
	TO_CHAR(DATE_TRUNC('month', donation_date), 'YYYY-MM')  AS donation_month,
	COUNT(id) AS total_donation
	FROM donorsearch.donation_anon
WHERE donation_date BETWEEN '2022-01-01' AND '2023-01-01'
GROUP BY donation_month
ORDER BY donation_month;

--Оценить, как система бонусов влияет на зарегистрированные в системе донации.
--кол-во активных доноров (сдающие кровь каждые 180 дней)
WITH
interval_day AS (
	SELECT 
	user_id,
	donation_date,
	lag(donation_date, 1) OVER w - donation_date  AS diff
FROM donorsearch.donation_anon
WHERE donation_date IS NOT NULL
WINDOW w AS (
	PARTITION BY user_id
	ORDER BY donation_date asc
)
)
SELECT user_id,
	COUNT(user_id) AS count_donation
FROM interval_day
WHERE diff <= 180
GROUP BY user_id
ORDER BY count_donation desc;

--Оценить, какие типы бонусов наиболее эффективны для увеличения числа донаций.
SELECT 
	uab.bonus_name,
	ROUND(AVG(uab.donation_count), 2) AS avg_donation,
	ROUND(AVG(uad.count_bonuses_taken), 2) AS avg_used_bonus
FROM donorsearch.user_anon_bonus AS uab
LEFT JOIN donorsearch.user_anon_data AS uad ON uad.id = uab.user_id
WHERE uab.date_of_use IS NOT NULL
GROUP BY bonus_name
ORDER BY AVG(uab.donation_count) desc;
	
