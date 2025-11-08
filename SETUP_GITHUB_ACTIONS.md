# GitHub Actions Setup for Private Repository Access

## Issue: Private Repository Access

Your child repositories are **private**, which means GitHub Actions' default `GITHUB_TOKEN` cannot access them. You need to create a Personal Access Token (PAT).

## Quick Fix: Create a Personal Access Token

### Step 1: Create PAT
1. Go to [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Give it a name like "Flyway Sync Workflow"
4. Select scopes:
   - ✅ `repo` (Full repository access)
   - ✅ `workflow` (Update GitHub Actions workflows)
5. Set expiration (recommend 90 days minimum)
6. Click "Generate token"
7. **Copy the token immediately** (you won't see it again)

### Step 2: Add Token to Repository Secrets
1. Go to your repository: `https://github.com/CleanAyers/shared-flyway-ddl`
2. Go to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `PAT_TOKEN`
5. Value: Paste your token from Step 1
6. Click "Add secret"

### Step 3: Test the Workflow
1. Make any small commit to trigger the workflow
2. The workflow will now use your PAT to access private repositories

## Alternative: Make Repositories Public
If you don't want to manage PATs, you could make the child repositories public:
- `CleanAyers/flyway-1-pipeline`
- `CleanAyers/flyway-1-grants` 
- `CleanAyers/flyway-2-pipeline`
- `CleanAyers/flyway-2-grants`

## Current Status
- ✅ All repositories exist
- ❌ They are private (GitHub Actions can't access them with default token)
- ✅ Workflow updated to use PAT_TOKEN when available
- ⏳ Need to create and add PAT_TOKEN secret

## Verification
After adding the PAT_TOKEN, your next workflow run should show:
```
✅ Successfully cloned flyway-1-pipeline with gh
✅ Successfully cloned flyway-1-grants with gh  
✅ Successfully cloned flyway-2-pipeline with gh
✅ Successfully cloned flyway-2-grants with gh
```