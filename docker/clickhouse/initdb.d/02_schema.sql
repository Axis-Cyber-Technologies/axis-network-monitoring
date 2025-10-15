-- Local ClickHouse schema for development (single instance).
-- Mirrors sql/clickhouse_schema.sql but without cluster macros and using MergeTree engines.

CREATE DATABASE IF NOT EXISTS axis_monitor;

CREATE TABLE IF NOT EXISTS axis_monitor.sec_events
(
    ts DateTime64(6, 'UTC'),
    ingest_ts DateTime DEFAULT now('UTC'),
    event_id UUID,
    src_ip IPv6,
    src_port UInt16,
    dst_ip IPv6,
    dst_port UInt16,
    proto LowCardinality(String),
    action LowCardinality(String),
    policy LowCardinality(String),
    rule_id LowCardinality(String),
    app LowCardinality(String),
    vlan LowCardinality(String),
    iface LowCardinality(String),
    sni String,
    domain String,
    user LowCardinality(String),
    device_id LowCardinality(String),
    bytes_in UInt64,
    bytes_out UInt64,
    packets UInt32,
    verdict_details String,
    src_geo_country FixedString(2),
    src_geo_city String,
    dst_geo_country FixedString(2),
    dst_geo_city String,
    tags Array(LowCardinality(String)),
    _raw String
)
ENGINE = MergeTree
PARTITION BY toDate(ts)
ORDER BY (ts, dst_ip, src_ip, rule_id)
TTL ts + INTERVAL 180 DAY
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS axis_monitor.dns_queries
(
    ts DateTime64(6, 'UTC'),
    ingest_ts DateTime DEFAULT now('UTC'),
    event_id UUID,
    client_ip IPv6,
    client_port UInt16,
    server_ip IPv6,
    transport LowCardinality(String),
    query_type LowCardinality(String),
    qname String,
    action LowCardinality(String),
    policy LowCardinality(String),
    rule_id LowCardinality(String),
    answer Array(String),
    rcode LowCardinality(String),
    latency_ms Float32,
    bytes_in UInt32,
    bytes_out UInt32,
    device_id LowCardinality(String),
    user LowCardinality(String),
    tags Array(LowCardinality(String))
)
ENGINE = MergeTree
PARTITION BY toDate(ts)
ORDER BY (ts, client_ip, qname)
TTL ts + INTERVAL 90 DAY
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS axis_monitor.policy_changes
(
    ts DateTime64(6, 'UTC'),
    change_id UUID,
    policy LowCardinality(String),
    policy_version String,
    actor LowCardinality(String),
    actor_type LowCardinality(String),
    decision LowCardinality(String),
    source_ip IPv6,
    comment String,
    diff_summary String,
    status LowCardinality(String),
    duration_ms UInt32,
    metadata Map(String, String)
)
ENGINE = MergeTree
PARTITION BY toDate(ts)
ORDER BY (ts, policy, actor)
TTL ts + INTERVAL 365 DAY;

CREATE TABLE IF NOT EXISTS axis_monitor.sec_events_by_minute
(
    bucket DateTime,
    policy LowCardinality(String),
    action LowCardinality(String),
    iface LowCardinality(String),
    vlan LowCardinality(String),
    total_events AggregateFunction(count),
    blocked AggregateFunction(countIf, UInt8),
    allowed AggregateFunction(countIf, UInt8),
    total_bytes_in AggregateFunction(sum, UInt64),
    total_bytes_out AggregateFunction(sum, UInt64)
)
ENGINE = AggregatingMergeTree
PARTITION BY toDate(bucket)
ORDER BY (bucket, policy, action, iface, vlan)
TTL bucket + INTERVAL 730 DAY;

CREATE MATERIALIZED VIEW IF NOT EXISTS axis_monitor.mv_sec_events_by_minute
TO axis_monitor.sec_events_by_minute
AS
SELECT
    toStartOfMinute(ts) AS bucket,
    policy,
    action,
    iface,
    vlan,
    countState() AS total_events,
    countIfState(action = 'block' OR action = 'alert') AS blocked,
    countIfState(action = 'allow') AS allowed,
    sumState(bytes_in) AS total_bytes_in,
    sumState(bytes_out) AS total_bytes_out
FROM axis_monitor.sec_events
GROUP BY bucket, policy, action, iface, vlan;

CREATE TABLE IF NOT EXISTS axis_monitor.dns_blocks_by_hour
(
    bucket DateTime,
    policy LowCardinality(String),
    qname String,
    blocks UInt64
)
ENGINE = SummingMergeTree
PARTITION BY toDate(bucket)
ORDER BY (bucket, policy, qname)
TTL bucket + INTERVAL 365 DAY;

CREATE MATERIALIZED VIEW IF NOT EXISTS axis_monitor.mv_dns_blocks_by_hour
TO axis_monitor.dns_blocks_by_hour
AS
SELECT
    toStartOfHour(ts) AS bucket,
    policy,
    qname,
    count() AS blocks
FROM axis_monitor.dns_queries
WHERE action = 'blocked'
GROUP BY bucket, policy, qname;
