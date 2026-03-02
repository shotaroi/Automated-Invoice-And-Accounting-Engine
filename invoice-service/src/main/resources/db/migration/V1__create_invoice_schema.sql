-- Invoice and LineItem tables
CREATE TABLE invoice (
    id CHAR(36) PRIMARY KEY,
    customer_id VARCHAR(255) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    status VARCHAR(20) NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    net_total DECIMAL(19, 2) NOT NULL DEFAULT 0,
    vat_total DECIMAL(19, 2) NOT NULL DEFAULT 0,
    gross_total DECIMAL(19, 2) NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_invoice_status CHECK (status IN ('DRAFT', 'SENT', 'PAID', 'CANCELLED')),
    CONSTRAINT chk_due_after_issue CHECK (due_date >= issue_date)
);

CREATE INDEX idx_invoice_customer ON invoice(customer_id);
CREATE INDEX idx_invoice_status ON invoice(status);
CREATE INDEX idx_invoice_issue_date ON invoice(issue_date);

CREATE TABLE line_item (
    id CHAR(36) PRIMARY KEY,
    invoice_id CHAR(36) NOT NULL,
    description VARCHAR(500) NOT NULL,
    quantity DECIMAL(19, 4) NOT NULL,
    unit_price DECIMAL(19, 2) NOT NULL,
    vat_rate DECIMAL(5, 4) NOT NULL,
    net_amount DECIMAL(19, 2) NOT NULL,
    vat_amount DECIMAL(19, 2) NOT NULL,
    gross_amount DECIMAL(19, 2) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_line_item_invoice FOREIGN KEY (invoice_id) REFERENCES invoice(id) ON DELETE CASCADE
);

CREATE INDEX idx_line_item_invoice ON line_item(invoice_id);
