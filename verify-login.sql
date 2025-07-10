-- Verify Login Status in Supabase
-- Run this in your Supabase SQL Editor

-- 1. Check the most recent logins (last 24 hours)
SELECT 
    u.id,
    u.email,
    u.raw_user_meta_data->>'full_name' as full_name,
    u.created_at,
    u.last_sign_in_at,
    u.email_confirmed_at,
    CASE 
        WHEN u.last_sign_in_at > NOW() - INTERVAL '5 minutes' THEN '🟢 Just logged in!'
        WHEN u.last_sign_in_at > NOW() - INTERVAL '1 hour' THEN '🟡 Active recently'
        ELSE '⚪ Not recent'
    END as login_status
FROM auth.users u
WHERE u.last_sign_in_at > NOW() - INTERVAL '24 hours'
ORDER BY u.last_sign_in_at DESC;

-- 2. Check active sessions (if you want to see current sessions)
SELECT 
    s.id as session_id,
    u.email,
    s.created_at as session_started,
    s.updated_at as last_activity,
    AGE(NOW(), s.created_at) as session_duration
FROM auth.sessions s
JOIN auth.users u ON s.user_id = u.id
WHERE s.updated_at > NOW() - INTERVAL '24 hours'
ORDER BY s.updated_at DESC;

-- 3. Check your specific user (replace with your email)
SELECT 
    id,
    email,
    raw_user_meta_data,
    created_at,
    last_sign_in_at,
    email_confirmed_at,
    AGE(NOW(), last_sign_in_at) as time_since_login
FROM auth.users
WHERE email = 'your-email@example.com';  -- Replace with your actual email

-- 4. Get user count and recent activity summary
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN last_sign_in_at > NOW() - INTERVAL '1 hour' THEN 1 END) as active_last_hour,
    COUNT(CASE WHEN last_sign_in_at > NOW() - INTERVAL '24 hours' THEN 1 END) as active_last_day,
    MAX(last_sign_in_at) as most_recent_login
FROM auth.users;