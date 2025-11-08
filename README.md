# shared-flyway-ddl# 🛠️ Flyway-DDL Repository

## Overview

This repository serves as the central hub for all database schema migrations managed via Flyway. It orchestrates a distributed flyway pipeline strategy where each database cluster maintains separate repositories for schema migrations and access control management.

The architecture promotes:
- **Separation of Concerns**: Schema changes and grants are managed independently
- **Cluster Isolation**: Each database cluster has dedicated repositories
- **Centralized Governance**: Shared templates and baseline scripts ensure consistency
- **Scalable Deployment**: Independent deployment pipelines for each cluster

## 🏗️ Pipeline Architecture

```
shared-flyway-ddl/                   # Central hub & shared resources
├── flyway-1-pipeline/               # Cluster 1 schema migrations
├── flyway-1-grants/                 # Cluster 1 access control & permissions
├── flyway-2-pipeline/               # Cluster 2 schema migrations  
├── flyway-2-grants/                 # Cluster 2 access control & permissions
└── [additional clusters...]
```

### Repository Types

#### 1. **Pipeline Repositories** (`flyway-{n}-pipeline/`)
- Contains schema migration scripts (DDL)
- Versioned SQL files for structural changes
- Database object creation/modification
- Independent deployment cycles

#### 2. **Grants Repositories** (`flyway-{n}-grants/`)
- User access management
- Role assignments and permissions
- Security-focused migrations
- Isolated from schema changes

#### 3. **Shared Repository** (`shared-flyway-ddl/`)
- Global baseline scripts
- Common DDL templates
- Cross-cluster utilities
- Pipeline orchestration tools

## 📂 Repository Structure

```
shared-flyway-ddl/
├── README.md
├── global/
│   ├── baseline/                    # Common baseline migrations
│   │   ├── V001__initial_schema.sql
│   │   └── V002__common_functions.sql
│   ├── templates/                   # Reusable DDL templates
│   │   ├── table_template.sql
│   │   ├── index_template.sql
│   │   └── procedure_template.sql
│   └── shared-grants/               # Common role definitions
│       ├── readonly_role.sql
│       └── app_user_role.sql
├── clusters/
│   ├── cluster-1/                   # References to cluster 1 repos
│   │   ├── pipeline -> ../flyway-1-pipeline/
│   │   └── grants -> ../flyway-1-grants/
│   └── cluster-2/                   # References to cluster 2 repos
│       ├── pipeline -> ../flyway-2-pipeline/
│       └── grants -> ../flyway-2-grants/
├── scripts/
│   ├── orchestrate.sh               # Multi-cluster deployment orchestrator
│   ├── validate.sh                  # Cross-cluster validation
│   ├── diff-report.sh              # Cluster comparison reports
│   └── rollback-coordinator.sh     # Coordinated rollback across clusters
├── config/
│   ├── flyway-global.conf          # Global flyway configuration
│   ├── cluster-configs/            # Cluster-specific configurations
│   │   ├── cluster-1.conf
│   │   └── cluster-2.conf
│   ├── pipeline-vars.example       # Environment variables template
│   └── deployment-matrix.yaml      # Deployment dependency mapping
└── docs/