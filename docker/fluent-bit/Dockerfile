FROM fluent/fluent-bit:2.2

COPY configs/fluent-bit/fluent-bit.conf /fluent-bit/etc/fluent-bit.conf
COPY configs/fluent-bit/parsers /fluent-bit/etc/parsers

ENTRYPOINT ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]
