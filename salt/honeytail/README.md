honeytail
=========

Installs honeytail from the debian repo.

Configurable keys through pillar:

- `honeytail:write_key` (required)
- `honeytail:dataset` (required)
- `honeytail:log_file` (required)
- `honeytail:parser_name` (required)
- `honeytail:sample_rate`
- `honeytail:keyval:time_field_name`: The name of the field that specifies time.
- `honeytail:dynsample`: List of fields to concatenate for dynamic sampling.
- `honeytail:debug`: Boolean, log instead of submitting events.
