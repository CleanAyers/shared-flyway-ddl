# 🪝 Flyway Callbacks

## Overview
Flyway callbacks extend Flyway’s migration lifecycle, allowing you to run custom SQL or shell logic automatically **before** or **after** specific Flyway commands. They’re great for automating post‑migration maintenance, seeding, validation, or integration tasks in a database DevOps pipeline.

---

## ⚙️ Common Callback Types

| Lifecycle Event | When It Runs | Example Use Case |
|-----------------|---------------|------------------|
| `beforeMigrate.sql` | Before any migration starts | Check DB readiness, ensure schema exists |
| `afterMigrate.sql` | After all migrations run | Refresh analytics views, seed data |
| `beforeEachMigrate.sql` | Before each individual migration | Validate dependencies between scripts |
| `afterEachMigrate.sql` | After each individual migration | Log applied version to audit table |
| `beforeClean.sql` | Before a `flyway clean` (dangerous!) | Safety check or backup trigger |
| `afterClean.sql` | After `flyway clean` | Reset sequences or load baseline data |
| `afterRepair.sql` | After `flyway repair` | Run validation or reconcile metadata |
| `beforeInfo.sql` / `afterInfo.sql` | Around `flyway info` | Capture migration status snapshot |

---

## 📁 Folder Layout Example

Place callbacks in a dedicated `callbacks/` directory alongside your migration scripts:

```
project/
├── conf/flyway.conf
├── sql/
│   ├── V1__init.sql
│   └── R__analytics_views.sql
└── callbacks/
    ├── beforeMigrate.sql
    ├── afterMigrate.sql
    └── afterEachMigrate.sql
```

Then update your configuration:

```properties
flyway.locations=filesystem:sql,filesystem:callbacks
```

---

## 🧠 Practical Examples

### 1. Auto‑refresh views after every migration

`callbacks/afterMigrate.sql`
```sql
DO $$
BEGIN
  RAISE NOTICE 'Refreshing analytics views...';
  PERFORM 1 FROM pg_matviews WHERE schemaname = 'sports';
  EXECUTE 'REFRESH MATERIALIZED VIEW CONCURRENTLY sports.vw_next_7_days_fixtures';
  EXECUTE 'REFRESH MATERIALIZED VIEW CONCURRENTLY sports.vw_recent_form';
  RAISE NOTICE 'Analytics views refreshed.';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'View refresh skipped: %', SQLERRM;
END $$;
```

---

### 2. Log each migration version to an audit table

`callbacks/afterEachMigrate.sql`
```sql
CREATE TABLE IF NOT EXISTS flyway_audit (
  id serial PRIMARY KEY,
  version text,
  description text,
  installed_on timestamptz DEFAULT now()
);

INSERT INTO flyway_audit(version, description)
SELECT version, description
FROM flyway_schema_history
WHERE success = true
ORDER BY installed_rank DESC
LIMIT 1;
```

---

### 3. Safety guard before clean

`callbacks/beforeClean.sql`
```sql
DO $$
DECLARE
  env TEXT := current_setting('application_name', true);
BEGIN
  IF env IS NULL OR env = '' THEN
    env := 'unknown';
  END IF;

  IF env LIKE '%prod%' THEN
    RAISE EXCEPTION 'Flyway clean is disabled in production environment (%).', env;
  ELSE
    RAISE NOTICE 'Environment % OK for clean', env;
  END IF;
END $$;
```

---

## 🧾 Documentation Notes

### File Naming
Callback file names follow the pattern:
```
[eventName].sql
```
Example: `afterMigrate.sql`, `beforeClean.sql`, `afterEachMigrate.sql`.

### Supported Types
Flyway supports callbacks written as:
- `.sql` scripts (database‑native)
- `.sh`, `.ps1`, `.cmd` scripts (OS‑level)

### Execution Context
- SQL callbacks execute inside the same transactional context as migrations (if supported by the DB).  
- Shell callbacks run on the host machine, allowing integration with CI/CD systems.

---

## Example Config Snippet (flyway.conf)

```properties
flyway.locations=filesystem:sql,filesystem:callbacks
flyway.schemas=sports
flyway.defaultSchema=sports
```

---

## 🏁 Summary
Flyway callbacks give you lifecycle hooks around migrations — a perfect tool for automating validation, logging, and post‑migration processes in your sports‑data pipeline or any Flyway‑managed environment.
