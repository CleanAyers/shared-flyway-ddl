# Local PostgreSQL Database Setup with Distributed Flyway Structure

## 🎯 Objective
Set up a local PostgreSQL database that uses our proven distributed Flyway sync system to manage DDL changes across multiple database environments.

## 📋 Background
We have successfully created a distributed Flyway sync system that cascades DDL changes from a parent repository (`shared-flyway-ddl`) to 4 child repositories. Now we need to validate this system by connecting it to actual PostgreSQL databases and running Flyway migrations.

## 🏗️ Proposed Architecture

### **Database Structure**
```
Local PostgreSQL Instance
├── flyway_pipeline_1     # Database for flyway-1-pipeline
├── flyway_grants_1       # Database for flyway-1-grants  
├── flyway_pipeline_2     # Database for flyway-2-pipeline
├── flyway_grants_2       # Database for flyway-2-grants
└── flyway_shared         # Optional: shared metadata database
```

### **Integration Points**
- Each child repository's `read-only-flyway-files/sql/` contains migrations synced from parent
- Flyway configurations in each repo's `config/flyway.conf` point to respective databases
- Migrations should run successfully: V1 → V2 → V3 → V4 (orders table)

## 📋 Tasks

### **1. PostgreSQL Installation & Setup**
- [ ] Install PostgreSQL locally (via Homebrew on macOS)
- [ ] Start PostgreSQL service
- [ ] Create 4 databases for our repository structure
- [ ] Set up appropriate users/permissions

### **2. Flyway Installation & Configuration**
- [ ] Install Flyway CLI locally
- [ ] Configure each child repository's `flyway.conf` with database connections
- [ ] Test basic Flyway connectivity to each database

### **3. Migration Validation**
- [ ] Run migrations on `flyway-1-pipeline` database
- [ ] Run migrations on `flyway-1-grants` database  
- [ ] Run migrations on `flyway-2-pipeline` database
- [ ] Run migrations on `flyway-2-grants` database
- [ ] Verify all 4 databases have identical schema (V1-V4 applied)

### **4. Sync Integration Testing**
- [ ] Create V5 migration in parent repository
- [ ] Sync V5 to all child repositories using our proven sync system
- [ ] Apply V5 migration to all 4 databases
- [ ] Verify schema consistency across all environments

### **5. Automated Testing Scripts**
- [ ] Create script to run migrations across all databases
- [ ] Create script to verify schema consistency
- [ ] Create script to reset all databases (for testing)

## 🔧 Technical Requirements

### **PostgreSQL Setup Commands**
```bash
# Install PostgreSQL
brew install postgresql@15
brew services start postgresql@15

# Create databases
createdb flyway_pipeline_1
createdb flyway_grants_1  
createdb flyway_pipeline_2
createdb flyway_grants_2
```

### **Flyway Configuration Example**
```properties
# flyway-1-pipeline/config/flyway.conf
flyway.url=jdbc:postgresql://localhost:5432/flyway_pipeline_1
flyway.user=postgres
flyway.password=
flyway.locations=filesystem:read-only-flyway-files/sql
flyway.callbacks=filesystem:read-only-flyway-files/callbacks
```

### **Expected Migration Files**
Each database should successfully apply:
- ✅ `V1__init.sql` - Initial schema setup
- ✅ `V2__test_migration.sql` - Test migration  
- ✅ `V3__add_users_table.sql` - Users table creation
- ✅ `V4__create_orders_table.sql` - Orders table (distributed today)

## 🎯 Success Criteria

### **Primary Goals**
- [ ] All 4 PostgreSQL databases created and accessible
- [ ] Flyway successfully runs migrations V1-V4 on all databases
- [ ] All databases have identical schema after migration
- [ ] Our sync system can distribute new migrations (V5) to databases

### **Validation Checks**
- [ ] `flyway info` shows identical migration status across all databases
- [ ] Schema comparison confirms all tables/constraints match
- [ ] Sample data from V4 orders migration present in all databases
- [ ] Flyway callbacks execute successfully

### **Integration Test**
- [ ] Create V5 migration in parent → sync → apply → verify across all 4 databases

## 📊 Expected Outcome

After completion, we should have:
1. **4 local PostgreSQL databases** running our synced Flyway migrations
2. **Proven end-to-end workflow**: Code → Sync → Database
3. **Validation scripts** for ongoing development
4. **Foundation for multi-environment testing** (dev/staging/prod patterns)

## 🔗 Related Work
- **Day One Summary**: `docs/DAY_ONE_COMPLETE_SUMMARY.md` - Background on sync system
- **Sync Script**: `repo-tools/unified_flyway_sync.sh` - Proven distribution method
- **Migration Files**: `shared-flyway-ddl/read-write-flyway-files/sql/` - Source content

## ⚡ Priority
**High** - This validates our entire distributed Flyway architecture with real databases and completes the end-to-end development workflow.

---

**Assignee**: Development team  
**Labels**: enhancement, database, flyway, postgresql, integration-testing  
**Milestone**: Database Integration Phase