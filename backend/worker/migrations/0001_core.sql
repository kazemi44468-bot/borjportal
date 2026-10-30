PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS people(id TEXT PRIMARY KEY,full_name TEXT NOT NULL,email TEXT NOT NULL COLLATE NOCASE UNIQUE,phone TEXT,password_hash TEXT NOT NULL,password_salt TEXT NOT NULL,status TEXT NOT NULL DEFAULT 'active' CHECK(status IN('active','suspended','pending')),created_at TEXT NOT NULL,updated_at TEXT);
CREATE TABLE IF NOT EXISTS buildings(id TEXT PRIMARY KEY,name TEXT NOT NULL,slug TEXT NOT NULL UNIQUE,address TEXT,city TEXT,latitude REAL,longitude REAL,status TEXT NOT NULL DEFAULT 'active' CHECK(status IN('active','suspended','archived')),created_at TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS units(id TEXT PRIMARY KEY,building_id TEXT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,unit_number TEXT NOT NULL,floor TEXT,area_sqm REAL,parking_number TEXT,storage_number TEXT,status TEXT NOT NULL DEFAULT 'active' CHECK(status IN('active','inactive')),created_at TEXT NOT NULL,UNIQUE(building_id,unit_number));
CREATE TABLE IF NOT EXISTS memberships(id TEXT PRIMARY KEY,person_id TEXT NOT NULL REFERENCES people(id) ON DELETE CASCADE,building_id TEXT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,status TEXT NOT NULL DEFAULT 'active' CHECK(status IN('active','suspended','ended')),created_at TEXT NOT NULL,UNIQUE(person_id,building_id));
CREATE TABLE IF NOT EXISTS membership_roles(membership_id TEXT NOT NULL REFERENCES memberships(id) ON DELETE CASCADE,role_key TEXT NOT NULL,PRIMARY KEY(membership_id,role_key));
CREATE TABLE IF NOT EXISTS role_permissions(role_key TEXT NOT NULL,permission_key TEXT NOT NULL,PRIMARY KEY(role_key,permission_key));
CREATE TABLE IF NOT EXISTS unit_relationships(id TEXT PRIMARY KEY,unit_id TEXT NOT NULL REFERENCES units(id) ON DELETE CASCADE,person_id TEXT NOT NULL REFERENCES people(id) ON DELETE CASCADE,relationship_type TEXT NOT NULL CHECK(relationship_type IN('owner','resident','tenant','family','authorized')),status TEXT NOT NULL DEFAULT 'active' CHECK(status IN('active','ended')),start_date TEXT,end_date TEXT,created_at TEXT NOT NULL,UNIQUE(unit_id,person_id,relationship_type));
CREATE TABLE IF NOT EXISTS sessions(id TEXT PRIMARY KEY,person_id TEXT NOT NULL REFERENCES people(id) ON DELETE CASCADE,token_hash TEXT NOT NULL UNIQUE,expires_at TEXT NOT NULL,created_at TEXT NOT NULL,revoked_at TEXT);
CREATE TABLE IF NOT EXISTS invitations(id TEXT PRIMARY KEY,building_id TEXT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,unit_id TEXT REFERENCES units(id) ON DELETE SET NULL,email TEXT NOT NULL COLLATE NOCASE,role_key TEXT NOT NULL,token_hash TEXT NOT NULL UNIQUE,expires_at TEXT NOT NULL,created_by TEXT NOT NULL REFERENCES people(id),created_at TEXT NOT NULL,accepted_at TEXT,revoked_at TEXT);
CREATE TABLE IF NOT EXISTS audit_logs(id TEXT PRIMARY KEY,actor_person_id TEXT REFERENCES people(id) ON DELETE SET NULL,building_id TEXT REFERENCES buildings(id) ON DELETE SET NULL,action TEXT NOT NULL,target_type TEXT,target_id TEXT,ip_hash TEXT,created_at TEXT NOT NULL);
CREATE INDEX IF NOT EXISTS idx_memberships_person ON memberships(person_id,status);
CREATE INDEX IF NOT EXISTS idx_memberships_building ON memberships(building_id,status);
CREATE INDEX IF NOT EXISTS idx_units_building ON units(building_id,status);
CREATE INDEX IF NOT EXISTS idx_unit_relationships_person ON unit_relationships(person_id,status);
CREATE INDEX IF NOT EXISTS idx_sessions_person ON sessions(person_id,expires_at);
CREATE INDEX IF NOT EXISTS idx_invitations_email ON invitations(email,expires_at);
CREATE INDEX IF NOT EXISTS idx_audit_building ON audit_logs(building_id,created_at);
INSERT OR IGNORE INTO role_permissions VALUES
('building_admin','building:*'),
('manager','units:read'),('manager','units:write'),('manager','members:invite'),('manager','finance:read'),('manager','finance:write'),('manager','requests:read'),('manager','requests:write'),('manager','notices:write'),('manager','facilities:write'),('manager','documents:read'),('manager','reports:read'),
('board','units:read'),('board','finance:read'),('board','requests:read'),('board','notices:read'),('board','reports:read'),
('owner','units:own:read'),('owner','finance:own:read'),('owner','documents:own:read'),('owner','requests:own:write'),('owner','notices:read'),
('resident','units:assigned:read'),('resident','requests:own:write'),('resident','notices:read'),('resident','facilities:book'),('resident','guests:write'),('resident','parcels:read'),
('guard','units:read'),('guard','guests:manage'),('guard','parcels:manage'),('guard','notices:read'),
('technical','units:read'),('technical','maintenance:read'),('technical','maintenance:write'),('technical','documents:technical:read');
CREATE VIEW IF NOT EXISTS active_unit_people AS SELECT ur.unit_id,ur.person_id,ur.relationship_type,p.full_name,p.email FROM unit_relationships ur JOIN people p ON p.id=ur.person_id WHERE ur.status='active' AND p.status='active';
