PRAGMA foreign_keys = ON;

-- تعهدات مالی آینده؛ ثبت تعهد به‌تنهایی صندوق را کاهش نمی‌دهد.
CREATE TABLE IF NOT EXISTS building_obligations (
  id TEXT PRIMARY KEY,
  building_id TEXT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
  vendor_id TEXT REFERENCES building_vendors(id) ON DELETE SET NULL,
  contract_id TEXT REFERENCES building_contracts(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  total_amount INTEGER NOT NULL CHECK(total_amount >= 0),
  paid_amount INTEGER NOT NULL DEFAULT 0 CHECK(paid_amount >= 0),
  status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('draft','open','partially_paid','paid','cancelled')),
  next_due_on TEXT,
  approval_reference TEXT,
  description TEXT,
  created_by TEXT REFERENCES people(id) ON DELETE SET NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  CHECK(paid_amount <= total_amount)
);
CREATE TABLE IF NOT EXISTS obligation_installments (
  id TEXT PRIMARY KEY,
  obligation_id TEXT NOT NULL REFERENCES building_obligations(id) ON DELETE CASCADE,
  sequence_no INTEGER NOT NULL,
  due_on TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK(amount >= 0),
  paid_amount INTEGER NOT NULL DEFAULT 0 CHECK(paid_amount >= 0),
  paid_at TEXT,
  finance_transaction_id TEXT REFERENCES finance_transactions(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'planned' CHECK(status IN ('planned','due','partially_paid','paid','cancelled')),
  created_at TEXT NOT NULL,
  UNIQUE(obligation_id, sequence_no),
  CHECK(paid_amount <= amount)
);

CREATE TABLE IF NOT EXISTS building_insurance_policies (
  id TEXT PRIMARY KEY,
  building_id TEXT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
  policy_type TEXT NOT NULL,
  insurer_name TEXT NOT NULL,
  policy_number TEXT NOT NULL,
  starts_on TEXT NOT NULL,
  expires_on TEXT NOT NULL,
  premium_amount INTEGER CHECK(premium_amount >= 0),
  coverage_json TEXT,
  document_id TEXT REFERENCES building_documents(id) ON DELETE SET NULL,
  reminder_days INTEGER NOT NULL DEFAULT 30,
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('draft','active','expired','cancelled')),
  created_by TEXT REFERENCES people(id) ON DELETE SET NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  CHECK(expires_on >= starts_on)
);

CREATE TABLE IF NOT EXISTS charge_incentive_rules (
  id TEXT PRIMARY KEY,
  building_id TEXT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  payer_type TEXT NOT NULL CHECK(payer_type IN ('owner','resident','both')),
  grace_day INTEGER NOT NULL DEFAULT 0,
  reward_type TEXT NOT NULL DEFAULT 'none' CHECK(reward_type IN ('none','fixed','percent')),
  reward_value REAL NOT NULL DEFAULT 0,
  penalty_start_day INTEGER,
  penalty_type TEXT NOT NULL DEFAULT 'none' CHECK(penalty_type IN ('none','fixed','percent')),
  penalty_value REAL NOT NULL DEFAULT 0,
  penalty_cap INTEGER,
  exempt_unit_ids_json TEXT,
  is_active INTEGER NOT NULL DEFAULT 0,
  created_by TEXT REFERENCES people(id) ON DELETE SET NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT
);

CREATE TABLE IF NOT EXISTS legal_notice_cases (
  id TEXT PRIMARY KEY,
  building_id TEXT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
  unit_id TEXT REFERENCES units(id) ON DELETE SET NULL,
  payer_type TEXT CHECK(payer_type IN ('owner','resident','both')),
  case_type TEXT NOT NULL,
  claim_amount INTEGER CHECK(claim_amount >= 0),
  issued_on TEXT NOT NULL,
  response_due_on TEXT,
  delivery_method TEXT,
  delivery_status TEXT NOT NULL DEFAULT 'draft',
  reference_number TEXT,
  body TEXT NOT NULL,
  created_by TEXT REFERENCES people(id) ON DELETE SET NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT
);
CREATE TABLE IF NOT EXISTS legal_notice_events (
  id TEXT PRIMARY KEY,
  case_id TEXT NOT NULL REFERENCES legal_notice_cases(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  event_at TEXT NOT NULL,
  channel TEXT,
  recipient TEXT,
  delivery_reference TEXT,
  viewed_at TEXT,
  notes TEXT,
  created_by TEXT REFERENCES people(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS building_violation_reports (
  id TEXT PRIMARY KEY,
  building_id TEXT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
  unit_id TEXT REFERENCES units(id) ON DELETE SET NULL,
  case_number TEXT,
  category TEXT NOT NULL,
  location TEXT NOT NULL,
  occurred_at TEXT NOT NULL,
  reporter_person_id TEXT REFERENCES people(id) ON DELETE SET NULL,
  confidentiality TEXT NOT NULL DEFAULT 'management' CHECK(confidentiality IN ('management','board','anonymous_followup')),
  evidence_document_id TEXT REFERENCES building_documents(id) ON DELETE SET NULL,
  action_taken TEXT,
  resolution TEXT,
  status TEXT NOT NULL DEFAULT 'new',
  created_at TEXT NOT NULL,
  updated_at TEXT
);

CREATE TABLE IF NOT EXISTS reserve_funds (
  id TEXT PRIMARY KEY,
  building_id TEXT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
  account_id TEXT REFERENCES finance_accounts(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  purpose TEXT NOT NULL,
  opening_balance INTEGER NOT NULL DEFAULT 0 CHECK(opening_balance >= 0),
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','frozen','closed')),
  created_at TEXT NOT NULL,
  updated_at TEXT
);
CREATE TABLE IF NOT EXISTS reserve_fund_transactions (
  id TEXT PRIMARY KEY,
  reserve_fund_id TEXT NOT NULL REFERENCES reserve_funds(id) ON DELETE CASCADE,
  transaction_id TEXT REFERENCES finance_transactions(id) ON DELETE SET NULL,
  transaction_type TEXT NOT NULL CHECK(transaction_type IN ('contribution','withdrawal','adjustment')),
  amount INTEGER NOT NULL CHECK(amount > 0),
  transaction_date TEXT NOT NULL,
  approval_reference TEXT,
  description TEXT,
  created_by TEXT REFERENCES people(id) ON DELETE SET NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS unit_clearance_certificates (
  id TEXT PRIMARY KEY,
  building_id TEXT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
  unit_id TEXT NOT NULL REFERENCES units(id) ON DELETE CASCADE,
  certificate_number TEXT,
  purpose TEXT NOT NULL,
  requested_by TEXT,
  as_of_date TEXT NOT NULL,
  charge_debt INTEGER NOT NULL DEFAULT 0 CHECK(charge_debt >= 0),
  utility_debt INTEGER NOT NULL DEFAULT 0 CHECK(utility_debt >= 0),
  other_debt INTEGER NOT NULL DEFAULT 0 CHECK(other_debt >= 0),
  credit_balance INTEGER NOT NULL DEFAULT 0 CHECK(credit_balance >= 0),
  status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','debt_due','conditional','cleared','cancelled')),
  issued_at TEXT,
  expires_at TEXT,
  created_by TEXT REFERENCES people(id) ON DELETE SET NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT
);

CREATE TABLE IF NOT EXISTS access_control_devices (
  id TEXT PRIMARY KEY,
  building_id TEXT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
  device_name TEXT NOT NULL,
  device_type TEXT NOT NULL,
  location TEXT NOT NULL,
  hardware_identifier TEXT,
  vendor_name TEXT,
  connection_status TEXT NOT NULL DEFAULT 'unconfigured',
  last_seen_at TEXT,
  metadata_json TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT
);
CREATE TABLE IF NOT EXISTS access_control_policies (
  id TEXT PRIMARY KEY,
  building_id TEXT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
  device_id TEXT REFERENCES access_control_devices(id) ON DELETE CASCADE,
  policy_type TEXT NOT NULL,
  debt_threshold INTEGER,
  rules_json TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 0,
  created_by TEXT REFERENCES people(id) ON DELETE SET NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_obligations_building_due ON building_obligations(building_id,next_due_on,status);
CREATE INDEX IF NOT EXISTS idx_installments_due ON obligation_installments(due_on,status);
CREATE INDEX IF NOT EXISTS idx_insurance_expiry ON building_insurance_policies(building_id,expires_on,status);
CREATE INDEX IF NOT EXISTS idx_legal_notice_unit ON legal_notice_cases(building_id,unit_id,issued_on);
CREATE INDEX IF NOT EXISTS idx_violation_status ON building_violation_reports(building_id,status,occurred_at);
CREATE INDEX IF NOT EXISTS idx_reserve_fund_building ON reserve_funds(building_id,status);
CREATE INDEX IF NOT EXISTS idx_clearance_unit ON unit_clearance_certificates(building_id,unit_id,created_at);
CREATE INDEX IF NOT EXISTS idx_access_devices_building ON access_control_devices(building_id,connection_status);
