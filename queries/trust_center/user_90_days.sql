WITH tag AS (
    SELECT
        user_id,
        CASE
            WHEN type = 'LEGACY_SERVICE' THEN 'Service user' -- Deprecated in November 2025
            WHEN type = 'SERVICE' THEN 'Service user'
            WHEN name = 'SNOWFLAKE' THEN 'Service user'
            -- WHERE name = '' THEN 'Importan user -- for importan users
            WHEN last_success_login IS NULL OR last_success_login < DATEADD(DAY, -365, CURRENT_DATE) THEN 'User has never logged in'
            ELSE 'User has not logged in the last 90 days'
        END AS user_tag
    FROM snowflake.account_usage.users
)

SELECT
    u.name AS real_name,
    u.type,
    CASE 
        WHEN u.first_name IS NULL AND u.last_name IS NULL
            THEN CONCAT('service_', TO_CHAR(u.user_id))
        ELSE CONCAT('person_', TO_CHAR(u.user_id))
    END AS redacted_name,
    u.disabled,
    CAST(u.created_on AS DATE) AS created_on_date,
    tag.user_tag
FROM snowflake.account_usage.users AS u
LEFT JOIN tag ON u.user_id = tag.user_id
WHERE u.deleted_on IS NULL
    AND (
        (u.last_success_login IS NULL AND u.created_on < DATEADD(DAY, -90, CURRENT_DATE))
        OR
        u.last_success_login < DATEADD(DAY, -90, CURRENT_DATE)
    )
ORDER BY
    CASE
        WHEN u.last_success_login IS NULL THEN 0
        ELSE 1
    END,
    u.last_success_login;
