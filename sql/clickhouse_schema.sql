-- ClickHouse schema for Axis Network Monitor analytics
-- Engine: ReplicatedMergeTree assumed for HA deployments. Replace {shard} and {replica}
-- macros according to cluster layout. For single-node testing, drop REPLICATED syntax.

CREATE DATABASE IF NOT EXISTS axis_monitor
    ON CLUSTER '{cluster}'  -- remove ON CLUSTER for single-node
;

-- Raw security events (firewall / IDS / flow logs)
CREATE TABLE IF NOT EXISTS axis_monitor.sec_events ON CLUSTER '{cluster}'
(
    ts DateTime64(6, 'UTC'),
    ingest_ts DateTime DEFAULT now('UTC'),
    event_id UUID,
    src_ip IPv6,
    src_port UInt16,
    dst_ip IPv6,
    dst_port UInt16,
    proto LowCardinality(String),
    action LowCardinality(String),           -- allow / block / alert / drop
    policy LowCardinality(String),           -- logical policy id
    rule_id LowCardinality(String),          -- underlying firewall/IDS rule identifier
    app LowCardinality(String),              -- application detection result
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
    _raw String                                -- optional raw JSON payload
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/sec_events', '{replica}')
PARTITION BY toDate(ts)
ORDER BY (ts, dst_ip, src_ip, rule_id)
SAMPLE BY dst_ip
TTL ts + INTERVAL 180 DAY
SETTINGS index_granularity = 8192;

-- DNS query/response records
CREATE TABLE IF NOT EXISTS axis_monitor.dns_queries ON CLUSTER '{cluster}'
(
    ts DateTime64(6, 'UTC'),
    ingest_ts DateTime DEFAULT now('UTC'),
    event_id UUID,
    client_ip IPv6,
    client_port UInt16,
    server_ip IPv6,
    transport LowCardinality(String),         -- udp / tcp / dot / doh
    query_type LowCardinality(String),        -- A / AAAA / TXT ...
    qname String,
    action LowCardinality(String),            -- allowed / blocked / NXDOMAIN
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
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/dns_queries', '{replica}')
PARTITION BY toDate(ts)
ORDER BY (ts, client_ip, qname)
TTL ts + INTERVAL 90 DAY
SETTINGS index_granularity = 8192;

-- Policy change audit log
CREATE TABLE IF NOT EXISTS axis_monitor.policy_changes ON CLUSTER '{cluster}'
(
    ts DateTime64(6, 'UTC'),
    change_id UUID,
    policy LowCardinality(String),
    policy_version String,
    actor LowCardinality(String),
    actor_type LowCardinality(String),        -- human / ai / automation
    decision LowCardinality(String),          -- approved / denied / reverted / auto-approve
    source_ip IPv6,
    comment String,
    diff_summary String,
    status LowCardinality(String),            -- applied / failed / rolled_back
    duration_ms UInt32,
    metadata Map(String, String)
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/policy_changes', '{replica}')
PARTITION BY toDate(ts)
ORDER BY (ts, policy, actor)
TTL ts + INTERVAL 365 DAY;

-- Materialized view: 1-minute aggregates of security events
CREATE TABLE IF NOT EXISTS axis_monitor.sec_events_by_minute ON CLUSTER '{cluster}'
(
    bucket DateTime,
    policy LowCardinality(String),
    action LowCardinality(String),
    iface LowCardinality(String),
    vlan LowCardinality(String),
    total_events UInt64,
    blocked UInt64,
    allowed UInt64,
    total_bytes_in UInt64,
    total_bytes_out UInt64
)
ENGINE = ReplicatedAggregatingMergeTree('/clickhouse/tables/{shard}/sec_events_by_minute', '{replica}')
PARTITION BY toDate(bucket)
ORDER BY (bucket, policy, action, iface, vlan)
TTL bucket + INTERVAL 730 DAY;

CREATE MATERIALIZED VIEW IF NOT EXISTS axis_monitor.mv_sec_events_by_minute ON CLUSTER '{cluster}'
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

-- Materialized view: hourly DNS block counts
CREATE TABLE IF NOT EXISTS axis_monitor.dns_blocks_by_hour ON CLUSTER '{cluster}'
(
    bucket DateTime,
    policy LowCardinality(String),
    qname String,
    blocks UInt64
)
ENGINE = ReplicatedSummingMergeTree('/clickhouse/tables/{shard}/dns_blocks_by_hour', '{replica}')
PARTITION BY toDate(bucket)
ORDER BY (bucket, policy, qname)
TTL bucket + INTERVAL 365 DAY;

CREATE MATERIALIZED VIEW IF NOT EXISTS axis_monitor.mv_dns_blocks_by_hour ON CLUSTER '{cluster}'
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

-- Aggregating materialized view finalization queries
CREATE MATERIALIZED VIEW IF NOT EXISTS axis_monitor.sec_events_by_minute_final ON CLUSTER '{cluster}'
ENGINE = AggregatingMergeTree
PARTITION BY toDate(bucket)
ORDER BY (bucket, policy, action, iface, vlan)
AS
SELECT
    bucket,
    policy,
    action,
    iface,
    vlan,
    finalizeAggregation(total_events) AS total_events,
    finalizeAggregation(blocked) AS blocked,
    finalizeAggregation(allowed) AS allowed,
    finalizeAggregation(total_bytes_in) AS total_bytes_in,
    finalizeAggregation(total_bytes_out) AS total_bytes_out
FROM axis_monitor.sec_events_by_minute;

