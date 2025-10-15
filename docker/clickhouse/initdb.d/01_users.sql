CREATE USER IF NOT EXISTS axis_api IDENTIFIED WITH plaintext_password BY 'axis_secret';
GRANT SELECT ON axis_monitor.* TO axis_api;
GRANT INSERT ON axis_monitor.sec_events TO axis_api;
GRANT INSERT ON axis_monitor.dns_queries TO axis_api;
GRANT INSERT ON axis_monitor.policy_changes TO axis_api;
