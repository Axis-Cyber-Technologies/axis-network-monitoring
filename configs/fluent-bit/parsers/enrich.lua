function enrich_record(tag, timestamp, record)
    -- Normalize field names and add derived values
    if record["src"] ~= nil and record["src"]["ip"] ~= nil then
        record["src_ip"] = record["src"]["ip"]
    end
    if record["dest"] ~= nil and record["dest"]["ip"] ~= nil then
        record["dst_ip"] = record["dest"]["ip"]
    end
    if record["src_port"] == nil and record["src"] ~= nil then
        record["src_port"] = record["src"]["port"]
    end
    if record["dst_port"] == nil and record["dest"] ~= nil then
        record["dst_port"] = record["dest"]["port"]
    end
    if record["event_type"] ~= nil then
        record["event_type"] = string.lower(record["event_type"])
    end
    -- Derive action
    if record["alert"] ~= nil then
        record["action"] = record["alert"]["action"] or "alert"
    elseif record["flow"] ~= nil then
        record["action"] = record["flow"]["action"] or "allow"
    end
    -- Flatten hostnames
    if record["dns"] ~= nil and record["dns"]["rrname"] ~= nil then
        record["qname"] = record["dns"]["rrname"]
    end
    -- Return modified record
    return 1, timestamp, record
end
