# Data Ingestion Pipeline

The Fluent Bit configuration under `configs/fluent-bit/` collects events from
OPNsense components and forwards normalized JSON records to ClickHouse (and
optionally Kafka/OpenSearch).

## Flow Overview

```
Syslog / Suricata / ntopng / other sensors
    └─> Fluent Bit
          ├─ Lua + GeoIP enrichment
          ├─ Tag routing (suricata.alert, suricata.dns, ...)
          ├─ ClickHouse HTTP sink (primary)
          └─ Kafka sink (optional fan-out)
```

### Inputs
- `tcp` listener on 5170 collects structured syslog from OPNsense.
- `tail` sources follow JSON logs: Suricata `eve.json` and ntopng flow exports;
  add more inputs for any additional telemetry you collect.

### Enrichment
- `modify` filter injects collector metadata.
- `lua` script flattens nested structures into normalized fields (src_ip,
  dst_ip, ports, qname, action).
- `geoip2` adds city/country for both source and destination.
- `rewrite_tag` creates channel-specific tags (e.g., `suricata.alert`) for more
  granular routing.

### Outputs
- ClickHouse HTTP endpoint (`json` format) with microsecond timestamps. Provide
  credentials through the environment variable `CLICKHOUSE_BASIC_AUTH`.
- Kafka topic for syslog events, enabling additional downstream consumers.

### Persistence & Resilience
- Enable Fluent Bit local filesystem buffering (`storage.*` keys) before
  production deployment to survive ClickHouse outages.
- Tail inputs persist offsets under `/var/lib/fluent-bit/*.db`.

## Kafka Fan-out (Optional)

1. Deploy a 3-node Kafka cluster; provision topics:
   - `opnsense-syslog`
   - `suricata-eve`
   - `ntopng-flow`
2. Configure Fluent Bit `Match` rules to send each tag to the desired topic.
3. Downstream sinks:
   - Vector or Kafka-Connect → ClickHouse (for replay or delayed ingest).
   - Kafka-Connect → OpenSearch for short-lived full-text indexes.

## Next Steps
- Create Ansible roles or scripts to install Fluent Bit with the provided
  configuration.
- Define Lua enrichment logic for additional metadata (user/device lookup).
- Instrument monitoring via Fluent Bit HTTP metrics endpoint (`:2021`).
- With the Docker Compose stack (`docs/DEVELOPMENT_STACK.md`), update files in
  `demo/logs/` and confirm records arrive in ClickHouse via the FastAPI
  endpoints or `clickhouse-client`.
