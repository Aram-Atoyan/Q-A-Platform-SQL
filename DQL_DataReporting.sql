--Top 10 Active Users--
SELECT u.user_id, u.username, 
       COALESCE(COUNT(DISTINCT q.question_id), 0) + 
       COALESCE(COUNT(DISTINCT a.answer_id), 0) + 
       COALESCE(COUNT(DISTINCT c.comment_id), 0) AS total_activity
FROM users u
LEFT JOIN questions q ON u.user_id = q.author_id
LEFT JOIN answers a ON u.user_id = a.author_id
LEFT JOIN comments c ON u.user_id = c.author_id
GROUP BY u.user_id, u.username
ORDER BY total_activity DESC
LIMIT 10;
-- 10 Most Popular Tags--
SELECT t.name AS tag_name, COUNT(qt.question_id) AS tag_usage_count
FROM tags t
LEFT JOIN question_tags qt ON t.tag_id = qt.tag_id
LEFT JOIN questions q ON qt.question_id = q.question_id
GROUP BY t.tag_id, t.name
ORDER BY tag_usage_count DESC
LIMIT 10;
-- 10 Most Answered Questions--
SELECT q.question_id, q.title, COUNT(a.answer_id) AS answer_count
FROM questions q
LEFT JOIN answers a ON q.question_id = a.question_id
GROUP BY q.question_id, q.title
ORDER BY answer_count DESC
LIMIT 10;
--User Reputation Score--
SELECT u.user_id, u.username, 
       COALESCE(SUM(CASE WHEN v.vote = 1 THEN 1 ELSE 0 END), 0) AS total_upvotes,
       COALESCE(COUNT(DISTINCT a.answer_id), 0) AS accepted_answers,
       COALESCE(COUNT(DISTINCT ub.badge_id), 0) AS total_badges,
       (COALESCE(SUM(CASE WHEN v.vote = 1 THEN 1 ELSE 0 END), 0) + 
        COALESCE(COUNT(DISTINCT a.answer_id), 0) + 
        COALESCE(COUNT(DISTINCT ub.badge_id), 0)) AS reputation_score
FROM users u
LEFT JOIN votes v ON u.user_id = v.voter_id AND (v.question_id IS NOT NULL OR v.answer_id IS NOT NULL)
LEFT JOIN answers a ON u.user_id = a.author_id AND a.is_accepted = TRUE
LEFT JOIN user_badges ub ON u.user_id = ub.user_id
GROUP BY u.user_id, u.username
ORDER BY reputation_score DESC
LIMIT 10;
--Top 10 Badge Earners--
SELECT u.user_id, u.username, 
       b.tier AS badge_tier, 
       COUNT(ub.badge_id) AS badge_count
FROM users u
LEFT JOIN user_badges ub ON u.user_id = ub.user_id
LEFT JOIN badges b ON ub.badge_id = b.badge_id
GROUP BY u.user_id, u.username, b.tier
ORDER BY badge_count DESC, badge_tier DESC
LIMIT 10;
--User Growth last day/week/month--
SELECT 
    (SELECT COUNT(*) FROM users WHERE joined_at >= CURRENT_DATE - 1) AS users_last_day,
    (SELECT COUNT(*) FROM users WHERE joined_at >= CURRENT_DATE - 7) AS users_last_week,
    (SELECT COUNT(*) FROM users WHERE joined_at >= CURRENT_DATE - 30) AS users_last_month;
--Inactive Users--
SELECT COUNT(*) 
FROM users u
WHERE NOT EXISTS (
    SELECT * FROM questions q WHERE q.author_id = u.user_id AND q.created_at >= CURRENT_DATE - 30
)
AND NOT EXISTS (
    SELECT * FROM answers a WHERE a.author_id = u.user_id AND a.created_at >= CURRENT_DATE - 30
);
--User Engagement by Country--
SELECT u.country, COUNT(DISTINCT u.user_id) AS engaged_users
FROM users u
LEFT JOIN questions q ON u.user_id = q.author_id AND q.created_at >= CURRENT_DATE - 30
LEFT JOIN answers a ON u.user_id = a.author_id AND a.created_at >= CURRENT_DATE - 30
WHERE q.question_id IS NOT NULL OR a.answer_id IS NOT NULL
GROUP BY u.country
ORDER BY engaged_users DESC;
--Unanswered Questions--
SELECT q.question_id, q.title
FROM questions q
WHERE NOT EXISTS (
    SELECT * FROM answers a WHERE a.question_id = q.question_id
);
--10 Most Favorited Questions--
SELECT q.question_id, q.title, COUNT(fq.user_id) AS favorite_count
FROM questions q
LEFT JOIN favoriteQuestions fq ON q.question_id = fq.question_id
GROUP BY q.question_id, q.title
ORDER BY favorite_count DESC
LIMIT 10;
--Voting Summary--
SELECT 
    q.question_id, 
    q.title, 
    COALESCE(SUM(v.vote), 0) AS net_score
FROM questions q
LEFT JOIN votes v ON q.question_id = v.question_id
GROUP BY q.question_id, q.title
ORDER BY net_score DESC
LIMIT 10;
--Fastest Response--
SELECT 
    q.question_id, 
    q.title, 
    a.created_at AS first_answer_time,
    AGE(a.created_at, q.created_at) AS response_time
FROM questions q
LEFT JOIN answers a ON q.question_id = a.question_id
WHERE a.created_at = (
    SELECT MIN(created_at)
    FROM answers
    WHERE question_id = q.question_id
)
ORDER BY response_time ASC
LIMIT 10;
--Average Answers per Question--
SELECT 
    AVG(answer_count) AS avg_answers_per_question
FROM (
    SELECT COUNT(a.answer_id) AS answer_count
    FROM questions q
    LEFT JOIN answers a ON q.question_id = a.question_id
    GROUP BY q.question_id
) AS answer_counts;
--10 Most Commented Questions--
SELECT 
    q.question_id, 
    q.title, 
    COUNT(c.comment_id) AS comment_count
FROM questions q
LEFT JOIN comments c ON q.question_id = c.question_id
GROUP BY q.question_id, q.title
ORDER BY comment_count DESC
LIMIT 10;
--Badge Distribution--
SELECT 
    b.tier AS badge_tier, 
    COUNT(ub.user_id) AS user_count
FROM badges b
LEFT JOIN user_badges ub ON b.badge_id = ub.badge_id
GROUP BY b.tier
ORDER BY user_count DESC;