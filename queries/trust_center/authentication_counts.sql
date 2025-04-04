SET date_period = '2025-01-01' -- Change the date

WITH login_info AS (
    SELECT
        user_name,
        first_authentication_factor,
        second_authentication_factor,
        COUNT(*) AS count_per_authenticator,
        MAX(event_timestamp) AS last_login_date
    FROM    
        SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
    WHERE
        event_timestamp >=  $date_period 
    GROUP BY
        user_name, 
        first_authentication_factor,
        second_authentication_factor
)

,user_info AS (
    SELECT
        name,
        user_id,
        type,
        has_mfa,
        has_rsa_public_key,
        has_password
        first_name,
        last_name
        -- email
FROM 
    SNOWFLAKE.ACCOUNT_USAGE.USERS
)

SELECT
    li.user_name
    CASE 
        WHEN ui.first_name IS NULL AND ui.last_name IS NULL
            THEN CONCAT('service_', TO_CHAR(ui.user_id))
        ELSE CONCAT('person_', TO_CHAR(ui.user_id))
    END AS redacted_name,
    ui.type,
    li.first_authentication_factor,
    li.second_authentication_factor,
    li.count_per_authenticator,
    li.last_login_date
    ui.has_mfa,
    ui.has_rsa_public_key,
    ui.has_password
    -- ui.email
FROM
    login_info AS li
LEFT JOIN user_info AS ui ON li.user_name = ui.name
WHERE ui.deleted_on IS NULL
AND NOT ui.disabled
ORDER BY
    li.user_name,
    li.first_authentication_factor,