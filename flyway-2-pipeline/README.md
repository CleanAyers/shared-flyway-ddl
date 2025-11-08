# flyway-2-pipeline

# 🏗️ Cluster 2 – Flyway Pipeline

## Overview
This repository manages all **schema-level DDL migrations** for Cluster 2.  
It is part of the distributed Flyway structure defined in the [shared-flyway-ddl](https://github.com/CleanAyers/shared-flyway-ddl) parent repository.

**Purpose:**  
- Versioned SQL migrations `V__` prefix  
- Structural changes to tables, views, functions, and indexes  
- Separate lifecycle from `ecs-2-grants` (access control repository)  

---

## 📂 Structure
```
flyway-2-pipeline/
├── sql/
│ ├── V001__baseline_schema.sql
│ ├── V002__add_claims_indexes.sql
│ ├── V003__optimize_joins.sql
│ └── ...
├── conf/
│ └── flyway.conf
└── README.md
```


---

## 🚀 Usage
Run migrations locally or through CI/CD:

```bash
flyway -configFiles=conf/flyway.conf migrate
```

## 🧩 Notes

- All DDL scripts must be idempotent where feasible.

- Do not include grants or permissions here — those belong to flyway-2-grants.

- Sync schema baselines periodically with shared-flyway-ddl/global/baseline/.