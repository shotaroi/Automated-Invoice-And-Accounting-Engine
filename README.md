# Automated Invoice & Accounting Engine

A production-style portfolio project inspired by automated accounting SaaS (e.g. Kleer). Built with Java 21, Spring Boot 3.x, MySQL, REST, and internal gRPC.

## Architecture

```
                    ┌─────────────────────────────────────────────────────────┐
                    │                     CLI / External Clients              │
                    └─────────────────────────────────────────────────────────┘
                                              │
                         REST                 │                 REST
                    ┌─────────────┐           │           ┌─────────────┐
                    │  invoice-   │           │           │  reporting- │
                    │  service    │           │           │  service    │
                    │  :8080      │           │           │  :8082      │
                    └──────┬──────┘           │           └──────┬──────┘
                           │                  │                  │
                           │ REST (sync)      │                  │ gRPC
                           │ POST /post       │                  │ GetMonthlyTotals
                           ▼                  │                  │
                    ┌─────────────┐           │           ┌─────────────┐
                    │ accounting- │◄──────────┘           │ accounting- │
                    │ service     │                       │ service     │
                    │ :8081 REST  │                       │ :9090 gRPC  │
                    │ :9090 gRPC  │                       └─────────────┘
                    └──────┬──────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
   ┌──────────┐     ┌──────────┐     ┌──────────┐
   │ invoice_ │     │accounting│     │ (no DB)  │
   │   db     │     │   _db    │     │          │
   │  MySQL   │     │  MySQL   │     │          │
   └──────────┘     └──────────┘     └──────────┘
```

### Services

| Service | Port | Role |
|---------|------|------|
| **invoice-service** | 8080 | Public REST API: create invoices, add line items, send, mark paid |
| **accounting-service** | 8081 (REST), 9090 (gRPC) | Ledger engine: double-entry postings, idempotent event handling |
| **reporting-service** | 8082 | Monthly revenue + VAT reports via gRPC from accounting |

## Tech Stack

- **Java 21** · **Spring Boot 3.2** · **Maven** (multi-module)
- **MySQL 8** · **Spring Data JPA** · **Flyway**
- **REST** (public APIs) · **gRPC** (internal service-to-service)
- **Docker** · **Testcontainers** · **JUnit 5** · **Mockito**

## Prerequisites

- Java 21
- Maven 3.9+
- Docker & Docker Compose (for local run)

## Quick Start

### 1. Build

```bash
mvn clean install
```

### 2. Start infrastructure (MySQL)

```bash
docker compose up -d
```

This starts 3 MySQL instances: `invoice_db`, `accounting_db` (reporting has no DB).

### 3. Run services

```bash
# Terminal 1 - accounting (must start first for gRPC)
cd accounting-service && MYSQL_HOST=localhost MYSQL_PORT=3307 mvn spring-boot:run

# Terminal 2 - invoice
cd invoice-service && MYSQL_HOST=localhost MYSQL_PORT=3306 mvn spring-boot:run

# Terminal 3 - reporting
cd reporting-service && mvn spring-boot:run
```

## Full Flow: cURL Examples

### 1. Create draft invoice

```bash
curl -X POST http://localhost:8080/api/invoices \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "cust-001",
    "currency": "SEK",
    "issueDate": "2025-03-01",
    "dueDate": "2025-03-31"
  }'
```

Save the returned `id` (e.g. `INV-123`).

### 2. Add line items

```bash
curl -X POST http://localhost:8080/api/invoices/INV-123/items \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Consulting hours",
    "quantity": 10,
    "unitPrice": 1000.00,
    "vatRate": 0.25
  }'
```

### 3. Send invoice

```bash
curl -X POST http://localhost:8080/api/invoices/INV-123/send
```

### 4. Mark paid (triggers accounting posting)

```bash
curl -X POST http://localhost:8080/api/invoices/INV-123/pay \
  -H "Idempotency-Key: pay-INV-123-001"
```

### 5. Fetch monthly report

```bash
curl "http://localhost:8082/api/reports/monthly?year=2025&month=3"
```

## Idempotency

When `invoice-service` calls `accounting-service` to post INVOICE_SENT or INVOICE_PAID events, the client sends an `Idempotency-Key` header. The accounting service:

- Stores `(key, request_hash, response)` for a retention period
- On duplicate request (same key + same body hash): returns stored response without re-posting
- Ignores duplicate postings for the same `(invoiceId, entryType)` even without a key

This prevents double ledger entries from retries or network glitches.

## Optimistic Locking

The `Invoice` entity uses `@Version` (JPA optimistic locking):

- Prevents lost updates when two clients update the same invoice concurrently
- On conflict, one transaction fails with `OptimisticLockException`; client can retry
- State transitions (DRAFT→SENT→PAID) are transactional and validated

## Project Structure

```
├── common/              # Shared proto, gRPC stubs
├── invoice-service/     # REST API for invoices
├── accounting-service/  # Ledger + gRPC server
├── reporting-service/   # Reports via gRPC client
├── docker-compose.yml
└── Jenkinsfile
```

## License

MIT
