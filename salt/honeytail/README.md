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
- `honeytail:version_info`: A string like `1.666 sha256=deadbeef` specifying which version of
  honeytail to install. Latest version and hash can be found [in the docs](https://docs.honeycomb.io/getting-data-in/honeytail/).
- `honeytail:add_grains`: A list of grains that should be added to the data, like `num_cpus`, `manufacturer`, `cpu_model`, etc.
- `honeytail:request_shape`: Field that holds request line or path.
