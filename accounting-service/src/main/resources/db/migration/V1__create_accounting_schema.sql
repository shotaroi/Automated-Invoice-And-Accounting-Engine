-- Ledger and idempotency tables
CREATE TABLE ledger_entry (
    id CHAR(36) PRIMARY KEY,
    external_ref VARCHAR(36) NOT NULL,
    entry_type VARCHAR(30) NOT NULL,
    booking_date DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_ledger_external_entry UNIQUE (external_ref, entry_type),
    CONSTRAINT chk_entry_type CHECK (entry_type IN ('INVOICE_SENT', 'INVOICE_PAID'))
);

CREATE INDEX idx_ledger_external_ref ON ledger_entry(external_ref);
CREATE INDEX idx_ledger_booking_date ON ledger_entry(booking_date);

CREATE TABLE ledger_line (
    id CHAR(36) PRIMARY KEY,
    ledger_entry_id CHAR(36) NOT NULL,
    account_code VARCHAR(10) NOT NULL,
    direction VARCHAR(6) NOT NULL,
    amount DECIMAL(19, 2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ledger_line_entry FOREIGN KEY (ledger_entry_id) REFERENCES ledger_entry(id) ON DELETE CASCADE,
    CONSTRAINT chk_direction CHECK (direction IN ('DEBIT', 'CREDIT'))
);

CREATE INDEX idx_ledger_line_entry ON ledger_line(ledger_entry_id);
CREATE INDEX idx_ledger_line_account ON ledger_line(account_code);

CREATE TABLE idempotency_key (
    id VARCHAR(255) PRIMARY KEY,
    request_hash VARCHAR(64) NOT NULL,
    response_status INT,
    response_body LONGBLOB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_idempotency_expires ON idempotency_key(expires_at);
