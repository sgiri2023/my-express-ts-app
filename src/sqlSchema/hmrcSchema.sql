-- ======= Enable extensions =======
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- provides gen_random_uuid()

-- ======= Core users / authentication / roles =======
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID, -- optional link to org/agent/client
    email TEXT NOT NULL UNIQUE,
    name TEXT,
    password_hash TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE,
    meta JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE -- e.g. 'agent_admin', 'client_user'
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    PRIMARY KEY (user_id, role_id)
);

-- ======= Agents & Clients (organizations) =======
CREATE TABLE IF NOT EXISTS agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    hmrc_agent_id TEXT,            -- HMRC Agent code (if assigned)
    created_by UUID REFERENCES users(id),
    meta JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_agents_hmrc_agent_id ON agents(hmrc_agent_id);

CREATE TABLE IF NOT EXISTS clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID REFERENCES agents(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    hmrc_client_id TEXT,           -- HMRC-assigned id for client org (if any)
    utr TEXT,
    registered_address TEXT,
    meta JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_clients_agent ON clients(agent_id);

-- ======= HMRC App / OAuth registration (for your app usage) =======
CREATE TABLE IF NOT EXISTS hmrc_apps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,                     -- 'MyTaxApp - Production'
    client_id TEXT NOT NULL,                -- HMRC client_id (public)
    client_secret_cipher BYTEA,             -- encrypted secret (ciphertext)
    redirect_uris TEXT[],
    environment TEXT NOT NULL DEFAULT 'production', -- 'sandbox' or 'production'
    meta JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_hmrc_apps_clientid_env ON hmrc_apps(client_id, environment);

-- ======= Groups (Pillar 2 groups) =======
CREATE TABLE IF NOT EXISTS groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    ultimate_parent_entity TEXT,
    ultimate_parent_tax_ref TEXT,
    country_of_parent CHAR(2),
    pillar2_id TEXT UNIQUE,              -- HMRC-assigned Pillar 2 Group ID (P2G...)
    pillar2_registration_status TEXT,    -- pending/registered/rejected
    pillar2_registration_date DATE,
    meta JSONB DEFAULT '{}'::jsonb,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_groups_client ON groups(client_id);

-- ======= Entities (companies/subsidiaries within a group) =======
CREATE TABLE IF NOT EXISTS entities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    jurisdiction CHAR(2),                 -- ISO country code
    entity_type TEXT,                     -- 'subsidiary','branch','headquarter'
    utr_or_taxid TEXT,
    parent_entity_id UUID REFERENCES entities(id) ON DELETE SET NULL,
    meta JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_entities_group ON entities(group_id);

-- ======= Accounting periods for groups =======
CREATE TABLE IF NOT EXISTS accounting_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status TEXT DEFAULT 'open',   -- open / filed / closed
    meta JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE (group_id, start_date, end_date)
);

CREATE INDEX IF NOT EXISTS idx_accounting_periods_group ON accounting_periods(group_id);

-- ======= Entity financials (junction: entity <-> accounting period) =======
CREATE TABLE IF NOT EXISTS entity_financials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
    accounting_period_id UUID REFERENCES accounting_periods(id) ON DELETE CASCADE,
    revenue NUMERIC(20,2),
    profit_before_tax NUMERIC(20,2),
    tax_paid NUMERIC(20,2),
    effective_tax_rate NUMERIC(6,3),
    currency VARCHAR(10) DEFAULT 'GBP',
    adjustments JSONB DEFAULT '{}'::jsonb, -- store any adjustments used in ETR calc
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE (entity_id, accounting_period_id)
);

CREATE INDEX IF NOT EXISTS idx_entity_financials_entity ON entity_financials(entity_id);
CREATE INDEX IF NOT EXISTS idx_entity_financials_period ON entity_financials(accounting_period_id);

-- ======= Filings (one filing per group + accounting period) =======
CREATE TABLE IF NOT EXISTS filings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    accounting_period_id UUID REFERENCES accounting_periods(id) ON DELETE CASCADE,
    filing_type TEXT,                    -- 'PILLAR2_UKTR', 'BTN', 'ORN', 'CT', etc.
    canonical_payload JSONB,             -- final JSON sent to HMRC
    hmrc_submission_summary JSONB,       -- high-level HMRC response
    idempotency_key UUID,                -- top-level idempotency key for the filing
    filing_status TEXT DEFAULT 'draft',  -- draft / submitted / accepted / rejected / amended
    submission_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_filings_group_period ON filings(group_id, accounting_period_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_filings_group_period_type ON filings(group_id, accounting_period_id, filing_type);

-- ======= Filing submissions (tracks every submit attempt / retry) =======
CREATE TABLE IF NOT EXISTS filing_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filing_id UUID REFERENCES filings(id) ON DELETE CASCADE,
    version INT DEFAULT 1,
    attempt_number INT DEFAULT 1,
    idempotency_key UUID,                -- idempotency key used in API header for this attempt
    request_payload JSONB,
    response_payload JSONB,
    hmrc_submission_id TEXT,             -- HMRC submission identifier (returned by HMRC)
    http_status INT,
    status TEXT DEFAULT 'pending',       -- pending / success / failure / accepted / rejected
    error_code TEXT,
    error_details JSONB,
    submission_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    delivered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_filing_submissions_filing ON filing_submissions(filing_id);
CREATE INDEX IF NOT EXISTS idx_filing_submissions_hmrc_submission ON filing_submissions(hmrc_submission_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_filing_submissions_idempotency ON filing_submissions(idempotency_key) WHERE idempotency_key IS NOT NULL;

-- ======= HMRC OAuth tokens & token history =======
CREATE TABLE IF NOT EXISTS hmrc_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID REFERENCES agents(id) ON DELETE SET NULL,
    client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
    hmrc_app_id UUID REFERENCES hmrc_apps(id) ON DELETE SET NULL,
    service TEXT,                                 -- 'PILLAR2', 'MTD_VAT', etc.
    access_token_cipher BYTEA,                    -- encrypted access token
    refresh_token_cipher BYTEA,                   -- encrypted refresh token
    scope TEXT[],
    expires_at TIMESTAMP WITH TIME ZONE,
    environment TEXT DEFAULT 'production',
    meta JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_hmrc_tokens_agent_client_service ON hmrc_tokens(agent_id, client_id, service);

CREATE TABLE IF NOT EXISTS hmrc_token_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID REFERENCES hmrc_tokens(id) ON DELETE CASCADE,
    rotated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    expires_at TIMESTAMP WITH TIME ZONE,
    note TEXT,
    meta JSONB DEFAULT '{}'::jsonb
);

-- ======= HMRC Webhooks (raw capture) =======
CREATE TABLE IF NOT EXISTS hmrc_webhooks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(id) ON DELETE SET NULL,
    client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
    event_type TEXT,
    event_id TEXT,
    payload JSONB,
    raw_headers JSONB,
    received_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    processed BOOLEAN DEFAULT FALSE,
    processing_result JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_hmrc_webhooks_event ON hmrc_webhooks(event_type, event_id);

-- ======= Obligations (deadlines / obligations for group periods) =======
CREATE TABLE IF NOT EXISTS obligations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    accounting_period_id UUID REFERENCES accounting_periods(id) ON DELETE CASCADE,
    service TEXT NOT NULL,           -- 'PILLAR2', 'CT', 'VAT', 'SA'
    obligation_from DATE,
    obligation_to DATE,
    due_date DATE,
    status TEXT DEFAULT 'open',      -- open / fulfilled / overdue / cancelled
    hmrc_obligation_ref TEXT,
    meta JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_obligations_due ON obligations(due_date);

-- ======= ETR / GLoBE computation storage (per jurisdiction) =======
CREATE TABLE IF NOT EXISTS etr_computations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    accounting_period_id UUID REFERENCES accounting_periods(id) ON DELETE CASCADE,
    jurisdiction_code CHAR(2),
    revenue NUMERIC(20,2),
    tax_paid NUMERIC(20,2),
    adjustments JSONB DEFAULT '{}'::jsonb,
    effective_tax_rate NUMERIC(6,4),
    top_up_tax NUMERIC(20,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_etr_group_period ON etr_computations(group_id, accounting_period_id);

-- ======= Audit logs (immutable action history) =======
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    actor_agent_id UUID REFERENCES agents(id) ON DELETE SET NULL,
    target_table TEXT,
    target_id UUID,
    action TEXT,                     -- 'create','update','submit','token_refresh','revoke', etc.
    before JSONB,
    after JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_target ON audit_logs(target_table, target_id);

-- ======= Attachments (object store pointers) =======
CREATE TABLE IF NOT EXISTS attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(id) ON DELETE SET NULL,
    entity_id UUID REFERENCES entities(id) ON DELETE SET NULL,
    filing_id UUID REFERENCES filings(id) ON DELETE SET NULL,
    filename TEXT,
    s3_key TEXT NOT NULL,    -- pointer to object store
    mime_type TEXT,
    size_bytes BIGINT,
    checksum TEXT,
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    meta JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_attachments_filing ON attachments(filing_id);

-- ======= Authorisations (agent <-> client service authorisations) =======
CREATE TABLE IF NOT EXISTS authorisations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    service TEXT NOT NULL,                 -- 'PILLAR2','VAT','CT','SA', etc.
    status TEXT DEFAULT 'pending',         -- pending / active / revoked / expired
    granted_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    hmrc_auth_id TEXT,                     -- HMRC link/authorisation id if available
    meta JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE (agent_id, client_id, service)
);

CREATE INDEX IF NOT EXISTS idx_authorisations_agent_client ON authorisations(agent_id, client_id);

-- ======= Workflow tasks (manual review queue, background jobs) =======
CREATE TABLE IF NOT EXISTS workflow_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL,
    payload JSONB,
    status TEXT DEFAULT 'queued',  -- queued / running / succeeded / failed
    attempts INT DEFAULT 0,
    last_error TEXT,
    scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ======= Settings (tenant-level config) =======
CREATE TABLE IF NOT EXISTS settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID, -- agent or client organization
    key TEXT NOT NULL,
    value JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE (organization_id, key)
);

-- ======= Useful indexes for common lookups =======
CREATE INDEX IF NOT EXISTS idx_filings_status ON filings(filing_status);
CREATE INDEX IF NOT EXISTS idx_entity_financials_rev ON entity_financials(revenue);

-- ======= Example: helpful view for group + period filings (optional) =======
-- CREATE VIEW v_group_period_filings AS
-- SELECT g.id as group_id, g.name as group_name, ap.id as period_id, ap.start_date, ap.end_date, f.id as filing_id, f.filing_type, f.filing_status
-- FROM groups g
-- JOIN accounting_periods ap ON ap.group_id = g.id
-- LEFT JOIN filings f ON f.group_id = g.id AND f.accounting_period_id = ap.id;

-- ======= Final notes: grant minimal privileges, set up RLS, and integrate encryption & backup =======
-- Add further constraints, partitions and RLS as needed in your environment.