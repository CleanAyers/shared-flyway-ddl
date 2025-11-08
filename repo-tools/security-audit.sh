#!/usr/bin/env bash
set -euo pipefail

# Security Audit Tool for Flyway Repository
# Scans logs, code, and git history for potential secrets and sensitive information

# Colors for output
RED=$'\033[31m'; GREEN=$'\033[32m'; YEL=$'\033[33m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; NC=$'\033[0m'

REPO_ROOT="$(git rev-parse --show-toplevel)"
SCAN_RESULTS="$REPO_ROOT/security_audit_results.txt"

echo "${BOLD}${CYAN}🔐 Flyway Repository Security Audit${NC}"
echo "Scanning for potential secrets, API keys, and sensitive information..."
echo

# Initialize results file
cat > "$SCAN_RESULTS" << EOF
# Security Audit Results - $(date)
# Repository: $(git remote get-url origin)
# Commit: $(git rev-parse HEAD)

## Scan Summary
EOF

ISSUES_FOUND=0

# =============================================================================
# FUNCTION: Scan patterns in files
# =============================================================================
scan_patterns() {
    local file="$1"
    local patterns=(
        # API Keys and Tokens
        "github_pat_[a-zA-Z0-9_]*"
        "ghs_[a-zA-Z0-9_]*"
        "ghp_[a-zA-Z0-9_]*"
        "gho_[a-zA-Z0-9_]*"
        "ghu_[a-zA-Z0-9_]*"
        "glpat-[a-zA-Z0-9_-]*"
        "[a-zA-Z0-9_-]*api[_-]?key[a-zA-Z0-9_-]*"
        "[a-zA-Z0-9_-]*secret[_-]?key[a-zA-Z0-9_-]*"
        
        # Database Credentials
        "password\s*=\s*['\"][^'\"]*['\"]"
        "pwd\s*=\s*['\"][^'\"]*['\"]"
        "user\s*=\s*['\"][^'\"]*['\"]"
        "username\s*=\s*['\"][^'\"]*['\"]"
        "jdbc:[^[:space:]]*"
        "mysql://.*:.*@"
        "postgres://.*:.*@"
        "mongodb://.*:.*@"
        
        # Generic secrets
        "bearer\s+[a-zA-Z0-9_-]+"
        "token\s*[=:]\s*['\"][^'\"]*['\"]"
        "key\s*[=:]\s*['\"][^'\"]*['\"]"
        "secret\s*[=:]\s*['\"][^'\"]*['\"]"
        
        # AWS/Cloud
        "AKIA[0-9A-Z]{16}"
        "aws_access_key_id"
        "aws_secret_access_key"
        
        # Private keys
        "-----BEGIN.*PRIVATE KEY-----"
        "-----BEGIN RSA PRIVATE KEY-----"
        "-----BEGIN OPENSSH PRIVATE KEY-----"
        
        # URLs with credentials
        "https://[^:]+:[^@]+@"
        "http://[^:]+:[^@]+@"
        
        # Email addresses (might contain sensitive info)
        "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
        
        # IP addresses (might be internal)
        "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"
        
        # Potential server names
        "server\s*[=:]\s*['\"][^'\"]*['\"]"
        "host\s*[=:]\s*['\"][^'\"]*['\"]"
        "hostname\s*[=:]\s*['\"][^'\"]*['\"]"
    )
    
    local found=0
    for pattern in "${patterns[@]}"; do
        if grep -Hn -E -i "$pattern" "$file" 2>/dev/null; then
            ((ISSUES_FOUND++))
            found=1
        fi
    done
    
    return $found
}

# =============================================================================
# FUNCTION: Scan directory recursively
# =============================================================================
scan_directory() {
    local dir="$1"
    local description="$2"
    
    echo "${CYAN}Scanning $description...${NC}"
    echo "## $description" >> "$SCAN_RESULTS"
    echo >> "$SCAN_RESULTS"
    
    local files_scanned=0
    local files_with_issues=0
    
    while IFS= read -r -d '' file; do
        # Skip binary files
        if file "$file" | grep -q "text\|ASCII\|UTF-8"; then
            ((files_scanned++))
            if scan_patterns "$file"; then
                echo "  ${RED}⚠️  Issues found in: ${file#$REPO_ROOT/}${NC}"
                echo "- Issues found in: ${file#$REPO_ROOT/}" >> "$SCAN_RESULTS"
                ((files_with_issues++))
            else
                echo "  ${GREEN}✅ Clean: ${file#$REPO_ROOT/}${NC}"
            fi
        fi
    done < <(find "$dir" -type f -print0 2>/dev/null)
    
    echo "  Scanned: $files_scanned files, Issues in: $files_with_issues files"
    echo "Scanned: $files_scanned files, Issues in: $files_with_issues files" >> "$SCAN_RESULTS"
    echo >> "$SCAN_RESULTS"
}

# =============================================================================
# FUNCTION: Scan git history
# =============================================================================
scan_git_history() {
    echo "${CYAN}Scanning Git History for Secrets...${NC}"
    echo "## Git History Scan" >> "$SCAN_RESULTS"
    echo >> "$SCAN_RESULTS"
    
    # Scan recent commit messages
    echo "${YEL}Scanning commit messages...${NC}"
    local commit_issues=0
    while IFS= read -r commit; do
        if echo "$commit" | grep -E -i "(password|secret|key|token|api)" >/dev/null; then
            echo "  ${RED}⚠️  Suspicious commit message: $commit${NC}"
            echo "- Suspicious commit: $commit" >> "$SCAN_RESULTS"
            ((commit_issues++))
            ((ISSUES_FOUND++))
        fi
    done < <(git log --oneline --all -n 100)
    
    if [[ $commit_issues -eq 0 ]]; then
        echo "  ${GREEN}✅ No suspicious commit messages found${NC}"
        echo "- No suspicious commit messages found" >> "$SCAN_RESULTS"
    fi
    
    # Scan for large files that might contain secrets
    echo "${YEL}Scanning for large files in history...${NC}"
    local large_files=0
    while IFS= read -r line; do
        local size=$(echo "$line" | awk '{print $1}')
        local file=$(echo "$line" | awk '{print $3}')
        if [[ $size -gt 100000 ]]; then  # Files larger than 100KB
            echo "  ${YEL}📋 Large file in history: $file (${size} bytes)${NC}"
            echo "- Large file: $file (${size} bytes)" >> "$SCAN_RESULTS"
            ((large_files++))
        fi
    done < <(git rev-list --objects --all | sort -k 2 | cut -f 1 -d' ' | uniq | while read sha1; do echo "$(git cat-file -s $sha1) commit $sha1"; done 2>/dev/null | sort -rn | head -20)
    
    echo "Found $large_files large files in git history" >> "$SCAN_RESULTS"
    echo >> "$SCAN_RESULTS"
}

# =============================================================================
# FUNCTION: Check environment files
# =============================================================================
scan_env_files() {
    echo "${CYAN}Scanning for Environment Files...${NC}"
    echo "## Environment Files" >> "$SCAN_RESULTS"
    echo >> "$SCAN_RESULTS"
    
    local env_patterns=(".env" ".env.*" "*.properties" "*.conf" "*.config" "flyway.conf")
    local env_found=0
    
    for pattern in "${env_patterns[@]}"; do
        while IFS= read -r -d '' file; do
            echo "  ${YEL}📋 Environment file found: ${file#$REPO_ROOT/}${NC}"
            echo "- Environment file: ${file#$REPO_ROOT/}" >> "$SCAN_RESULTS"
            ((env_found++))
            
            # Scan the content
            scan_patterns "$file" && echo "    ${RED}⚠️  Contains potential secrets${NC}"
        done < <(find "$REPO_ROOT" -name "$pattern" -type f -print0 2>/dev/null)
    done
    
    if [[ $env_found -eq 0 ]]; then
        echo "  ${GREEN}✅ No environment files found${NC}"
        echo "- No environment files found" >> "$SCAN_RESULTS"
    fi
    echo >> "$SCAN_RESULTS"
}

# =============================================================================
# FUNCTION: Generate recommendations
# =============================================================================
generate_recommendations() {
    echo "## Recommendations" >> "$SCAN_RESULTS"
    echo >> "$SCAN_RESULTS"
    
    if [[ $ISSUES_FOUND -eq 0 ]]; then
        cat >> "$SCAN_RESULTS" << 'EOF'
✅ **SECURITY STATUS: GOOD**

No obvious secrets or sensitive information detected in:
- Current codebase and logs
- Git commit history
- Configuration files

**Safe to make public** with normal precautions.

### Recommended Actions:
1. Review any large files in git history manually
2. Set up git pre-commit hooks to prevent future secret commits
3. Use GitHub's secret scanning when repositories become public
4. Continue using repository secrets for any future sensitive configuration

EOF
    else
        cat >> "$SCAN_RESULTS" << EOF
⚠️  **SECURITY STATUS: ISSUES FOUND**

Found $ISSUES_FOUND potential security issues that need review before making repositories public.

### Immediate Actions Required:
1. **Review all flagged files** - Check if detected patterns are actual secrets
2. **Clean up git history** if real secrets are found:
   \`\`\`bash
   # Remove sensitive files from git history
   git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch FILENAME' --prune-empty --tag-name-filter cat -- --all
   \`\`\`
3. **Rotate any exposed credentials** (API keys, passwords, tokens)
4. **Use .gitignore** to prevent future secret commits
5. **Set up git hooks** for secret detection

### Files to Review:
EOF
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

cd "$REPO_ROOT"

# Scan different areas
scan_directory "$REPO_ROOT/.github" "GitHub Workflows"
scan_directory "$REPO_ROOT/repo-tools/logs" "Repository Logs"
scan_directory "$REPO_ROOT/read-write-flyway-files" "Flyway Source Files"
scan_directory "$REPO_ROOT" "All Repository Files"

scan_git_history
scan_env_files

# Generate final report
generate_recommendations

echo
echo "${BOLD}${CYAN}🔍 Security Audit Complete${NC}"
echo "Results saved to: ${YEL}$SCAN_RESULTS${NC}"
echo

if [[ $ISSUES_FOUND -eq 0 ]]; then
    echo "${GREEN}✅ No obvious security issues detected!${NC}"
    echo "${GREEN}Repository appears safe to make public.${NC}"
else
    echo "${RED}⚠️  Found $ISSUES_FOUND potential security issues${NC}"
    echo "${YEL}Please review the results before making repositories public${NC}"
fi

echo
echo "📋 Review the full report: cat $SCAN_RESULTS"
echo "🔧 To make repositories public safely:"
echo "   1. Address any real issues found"
echo "   2. Run this audit again to confirm clean status"
echo "   3. Proceed with making repositories public"