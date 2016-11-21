CREATE TABLE dyn_dns_client (
    id SERIAL NOT NULL,
    record_id INTEGER,
    key BYTEA NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(record_id) REFERENCES records (id)
)
