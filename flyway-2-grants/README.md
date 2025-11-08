# 🔐 Cluster 2 – Flyway Grants & Access Control (Aurora PostgreSQL)

## Overview
This repository manages all **role, privilege, and access control migrations** for **Cluster 2**,  
which runs on **Amazon Aurora PostgreSQL**. It complements the `flyway-2-pipeline` repository  
and follows the centralized governance defined in  
[shared-flyway-ddl](https://github.com/CleanAyers/shared-flyway-ddl).

**Purpose:**  
- Maintain environment-specific access logic via **repeatable migrations** (`R__`)  
- Apply and track PostgreSQL-specific role and grant operations  
- Keep security management isolated from schema changes  

---

## 📂 Structure
```
flyway-2-grants/
├── sql/
│ ├── R__grant_app_user.sql
│ ├── R__grant_readonly_role.sql
│ ├── R__grant_etl_role.sql
│ ├── R__revoke_legacy_roles.sql
│ └── ...
├── conf/
│ └── flyway.conf
├── logs/
│ └── .gitkeep
├── .gitignore
└── README.md
```

---

## 🚀 Usage

Run migrations to apply updated grants and roles:
```bash
flyway -configFiles=conf/flyway.conf migrate
```

Inspect current migration status:
```bash
flyway -configFiles=conf/flyway.conf info
```

Validate migration integrity before deployment:
```bash
flyway -configFiles=conf/flyway.conf validate
```
## 🧩 Notes
- Use repeatable migrations (`R__`) to manage PostgreSQL grants and roles.
These re-run automatically when file contents change.
- Keep schema-altering DDL out of this repo — that belongs to `flyway-2-pipeline`.
- Reference shared role templates and naming conventions in
`shared-flyway-ddl/global/shared-grants/`.
- Follow PostgreSQL-specific best practices:
- Grant privileges on sequences and schemas explicitly
- Apply `ALTER DEFAULT PRIVILEGES` where applicable

## 🧱 Example SQL Template
```sql
-- R__grant_app_user.sql
GRANT CONNECT ON DATABASE cluster2db TO app_user;
GRANT USAGE ON SCHEMA app TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA app
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
```

## 🔄 Deployment Order
1. Apply schema migrations from `flyway-2-pipeline`
2. Run grant and role migrations from `flyway-2-grants`
3. Validate access levels with `flyway info`

## 🧾 Governance
- All access-control migrations must undergo PR review and approval.
- Keep role definitions consistent across clusters using shared templates.
- Include environment identifiers (e.g., `cluster2`, `aurora_pg`) in migration comments.
- Review and reapply grants after major PostgreSQL version upgrades.


---