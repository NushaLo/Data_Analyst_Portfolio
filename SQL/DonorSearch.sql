-- 1. Определить регионы с наибольшим количеством зарегистрированных доноров.
SELECT
	region,
	COUNT(id) AS count_donor
FROM donorsearch.user_anon_data
GROUP BY region
ORDER BY count_donor DESC
LIMIT 4;

--Первое место занимают крупные города. Много донаций без места и это надо исправить.

-- 2. Изучить динамику общего количества донаций в месяц за 2022 и 2023 годы.
SELECT 
	TO_CHAR(DATE_TRUNC('month', donation_date), 'YYYY-MM')  AS donation_month,
	COUNT(id) AS total_donation
	FROM donorsearch.donation_anon
WHERE donation_date BETWEEN '2022-01-01' AND '2023-12-31'
GROUP BY donation_month
ORDER BY donation_month, total_donation;

-- В 2022 году, рост донаций стабилен, за исключением мая и июня.
-- В 2023 году наблюдается заметный спад к концу года по сравнению с началом года.
-- В оба года пики активности приходятся на март и апрель.
-- Рекомендации:
-- На летний перод увеличить маркетинговые и рекламные кампании.
-- Провести дополнительные акции и мероприятия в конце года (октябрь-ноябрь).

-- 2. Оценить, как система бонусов влияет на зарегистрированные в системе донации.
-- 2.1 кол-во активных доноров (сдающие кровь каждые 180 дней)
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

-- Доноры с наибольшим количеством донаций показывают высокую степень вовлечённости и лояльности.
-- У донора с ID 235391 большое количество донаций (361), что указывает на его исключительную активность.
-- Эти доноры могут быть основой для создания программ лояльности и награждения, чтобы поддерживать их активность и стимулировать других доноров.

-- Рекомендации:
-- Создать специальные программы и награды для наиболее активных доноров: донорские значки, сертификаты, публичное признание и дополнительные бонусы.
-- Включить истории этих доноров в маркетинговые кампании для мотивации других.
-- Провести опросы или интервью с этими донорами, чтобы понять, что их мотивирует, и использовать эти знания для привлечения и удержания других доноров.

-- 2.2 Оценить, какие типы бонусов наиболее эффективны для увеличения числа донаций.
SELECT 
	uab.bonus_name,
	ROUND(AVG(uab.donation_count), 2) AS avg_donation,
	ROUND(AVG(uad.count_bonuses_taken), 2) AS avg_used_bonus
FROM donorsearch.user_anon_bonus AS uab
LEFT JOIN donorsearch.user_anon_data AS uad ON uad.id = uab.user_id
WHERE uab.date_of_use IS NOT NULL
GROUP BY bonus_name
ORDER BY AVG(uab.donation_count) desc;

-- Из данного запроса можно выделить три самые популярные бонусы, которые приводят и мягко мотивируют доноров:
-- "-10% на кофе и еду", "Скидка 15% на цветы", "Подписка «Попкорн» на 60 дней от билайн тв".
-- Соотношение донаций с использованными бонусами показывает нам, что многие идут на бонус, что не очень хорошо.
-- Рекомендации:
-- Создать программу лояльности, которая будет поощрять доноров за их долгосрочную вовлеченность и участие в разных проектах, а не за одноразовое пожертвование.
-- Подключите доноров к реальным историям тех, кто получил помощь благодаря их пожертвованиям. Это может уменьшить фокус на материальных бонусах и усилить эмоциональную связь с процессом.

--Эффективность бонусной системы по регионам
WITH 
bonus_stat AS (
SELECT 
	COUNT(DISTINCT user_id) AS count_unic_users,
	region,
	SUM(user_bonus_count) AS total_bonus,
	SUM(donation_count) AS total_donation,
	SUM(user_bonus_count) / COUNT(DISTINCT user_id) AS avg_bonus_per_donor,
	SUM(donation_count) / COUNT(DISTINCT user_id) AS donation_per_bonus
FROM donorsearch.user_anon_bonus uad 
GROUP BY region
)
SELECT
	region,
	total_bonus,
	total_donation,
	avg_bonus_per_donor,
	donation_per_bonus,
	total_bonus / total_donation AS bonuses_per_donation,
	RANK() OVER (ORDER BY donation_per_bonus DESC) AS rank_by_efficiency
FROM bonus_stat
ORDER BY donation_per_bonus DESC;
