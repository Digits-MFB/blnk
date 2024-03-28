-- +migrate Up
CREATE SCHEMA IF NOT EXISTS blnk;

-- +migrate Up
CREATE TABLE IF NOT EXISTS blnk.ledgers
(
    id         SERIAL PRIMARY KEY,
    name       TEXT,
    ledger_id  TEXT      NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    meta_data  JSONB
);

-- +migrate Up
CREATE TABLE blnk.matching_rules
(
    id         SERIAL PRIMARY KEY,
    rule_id  TEXT      NOT NULL UNIQUE,
    rule_type  VARCHAR(255),
    parameters JSONB,
    all_match  BOOLEAN DEFAULT FALSE
);


-- +migrate Up
CREATE TABLE IF NOT EXISTS blnk.identity
(
    id                SERIAL PRIMARY KEY,
    identity_id       TEXT      NOT NULL UNIQUE,
    first_name        TEXT      NOT NULL,
    last_name         TEXT      NOT NULL,
    other_names       TEXT,
    gender            TEXT,
    dob               DATE,
    email_address     TEXT,
    phone_number      TEXT,
    nationality       TEXT,
    street            TEXT,
    country           TEXT,
    state             TEXT,
    organization_name TEXT,
    category          TEXT,
    identity_type     TEXT,
    post_code         TEXT,
    city              TEXT,
    created_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    meta_data         JSONB
);

-- +migrate Up
CREATE TABLE IF NOT EXISTS blnk.balances
(
    id                  SERIAL PRIMARY KEY,
    balance_id          TEXT      NOT NULL UNIQUE,
    indicator           TEXT,
    balance             BIGINT    NOT NULL,
    credit_balance      BIGINT    NOT NULL,
    debit_balance       BIGINT    NOT NULL,
    currency            TEXT      NOT NULL,
    currency_multiplier BIGINT    NOT NULL,
    ledger_id           TEXT      NOT NULL REFERENCES blnk.LEDGERS (ledger_id),
    identity_id         TEXT REFERENCES blnk.IDENTITY (identity_id),
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    modification_ref    TEXT,
    meta_data           JSONB
);

-- +migrate Up
CREATE TABLE IF NOT EXISTS blnk.accounts
(
    id          SERIAL PRIMARY KEY,
    account_id  TEXT      NOT NULL UNIQUE,
    name        TEXT      NOT NULL,
    number      TEXT      NOT NULL UNIQUE,
    bank_name   TEXT      NOT NULL,
    currency    TEXT      NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    ledger_id   TEXT      NOT NULL REFERENCES blnk.LEDGERS (ledger_id),
    identity_id TEXT      NOT NULL REFERENCES blnk.IDENTITY (identity_id),
    balance_id  TEXT      NOT NULL REFERENCES blnk.BALANCES (balance_id),
    meta_data   JSONB
);

-- +migrate Up
CREATE TABLE IF NOT EXISTS blnk.balance_monitors
(
    id            SERIAL PRIMARY KEY,
    monitor_id    TEXT      NOT NULL UNIQUE,
    balance_id    TEXT      NOT NULL REFERENCES blnk.BALANCES (balance_id),
    field         TEXT      NOT NULL CHECK (field IN ('debit_balance', 'credit_balance', 'balance')),
    operator      TEXT      NOT NULL CHECK (operator IN ('>', '<', '>=', '<=', '=')),
    value         BIGINT    NOT NULL,
    description   TEXT,
    call_back_url TEXT,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

-- +migrate Up
CREATE TABLE IF NOT EXISTS blnk.event_mappers
(
    id                  SERIAL PRIMARY KEY,
    name                TEXT      NOT NULL,
    mapper_id           TEXT      NOT NULL UNIQUE,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    mapping_instruction JSONB     NOT NULL
);

-- +migrate Up
CREATE TABLE IF NOT EXISTS blnk.transactions
(
    id             SERIAL PRIMARY KEY,
    transaction_id TEXT      NOT NULL UNIQUE,
    source         TEXT,
    destination    TEXT,
    description    TEXT,
    reference      TEXT,
    amount         BIGINT,
    currency       TEXT,
    status         TEXT,
    hash         TEXT,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    scheduled_for  TIMESTAMP,
    meta_data      JSONB,
    CONSTRAINT fk_source_balance FOREIGN KEY (source) REFERENCES blnk.balances (balance_id),
    CONSTRAINT fk_destination_balance FOREIGN KEY (destination) REFERENCES blnk.balances (balance_id)
);

-- +migrate Up
CREATE INDEX idx_transactions_reference ON blnk.transactions (reference);
CREATE INDEX idx_balances_indicator ON blnk.balances (indicator);
CREATE UNIQUE INDEX idx_unique_indicator_on_non_nulls
    ON blnk.balances (indicator)
    WHERE indicator IS NOT NULL;

-- +migrate Up
INSERT INTO blnk.ledgers (name, ledger_id, created_at, meta_data)
VALUES ('General Ledger', 'general_ledger_id', NOW(), '{}')
ON CONFLICT (ledger_id) DO NOTHING;


-- +migrate Down
DROP INDEX IF EXISTS blnk.idx_transactions_reference;
DROP INDEX IF EXISTS blnk.idx_balances_indicator;
DROP TABLE IF EXISTS blnk.transactions CASCADE;
DROP TABLE IF EXISTS blnk.balance_monitors CASCADE;
DROP TABLE IF EXISTS blnk.accounts CASCADE;
DROP TABLE IF EXISTS blnk.balances CASCADE;
DROP TABLE IF EXISTS blnk.identity CASCADE;
DROP TABLE IF EXISTS blnk.event_mappers CASCADE;
DROP TABLE IF EXISTS blnk.ledgers CASCADE;
DROP TABLE IF EXISTS blnk.matching_rules CASCADE;
