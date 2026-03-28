#!/usr/bin/env bash
# ==============================================================================
# RTL Audit Script v3.0 - AST-based RTL violation detection
# Part of APEX Law #5 Enforcement
# 
# Usage:
#   ./rtl-audit.sh ./src              # Scan directory
#   ./rtl-audit.sh ./src --json       # JSON output
#   ./rtl-audit.sh ./src --fix        # Auto-fix violations
#   ./rtl-audit.sh ./src --ci         # CI mode (fail on violations)
#   ./rtl-audit.sh ./src --verbose    # Verbose output
# ==============================================================================

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

VERSION="3.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AST_ANALYZER="${SCRIPT_DIR}/lib/ast-analyzer.js"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
FILES_SCANNED=0
FILES_WITH_VIOLATIONS=0
FIXED_COUNT=0

# Options
JSON_MODE=false
FIX_MODE=false
CI_MODE=false
VERBOSE=false
TARGET_DIR="."

# File extensions to scan
EXTENSIONS=("tsx" "jsx" "ts" "js" "css" "scss")

# Exclude patterns
EXCLUDE_DIRS=("node_modules" ".next" ".git" "dist" "build" ".turbo" "coverage" ".cache")

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

print_header() {
    if [[ "$JSON_MODE" == false ]]; then
        echo ""
        echo -e "${BOLD}${BLUE}=============================================${NC}"
        echo -e "${BOLD}${BLUE}  RTL AUDIT v${VERSION} - APEX Law #5 Enforcement${NC}"
        echo -e "${BOLD}${BLUE}=============================================${NC}"
        echo ""
    fi
}

print_usage() {
    cat << EOF
RTL Audit Script v${VERSION} - AST-based RTL violation detection

USAGE:
    $(basename "$0") [TARGET] [OPTIONS]

ARGUMENTS:
    TARGET              Directory or file to scan (default: current directory)

OPTIONS:
    --json              Output results as JSON
    --fix               Auto-fix violations (modifies files in place)
    --ci                CI mode (exit 1 on any violations)
    --verbose, -v       Show detailed output
    --help, -h          Show this help message
    --version           Show version

EXAMPLES:
    $(basename "$0") ./src                    # Scan src directory
    $(basename "$0") ./src --json             # JSON output for CI
    $(basename "$0") ./src --fix              # Auto-fix violations
    $(basename "$0") ./src --ci --json        # CI with JSON output
    $(basename "$0") ./src/Button.tsx         # Scan single file

EXIT CODES:
    0   No violations found
    1   Violations found (or errors in CI mode)
    2   Script error

VIOLATION CATEGORIES:
    margin      ml-/mr- should be ms-/me-
    padding     pl-/pr- should be ps-/pe-
    position    left-/right- should be start-/end- (generates inset-inline-start/end)
    text        text-left/right should be text-start/end
    float       float-left/right should be float-start/end
    border      border-l-/r- and rounded-l-/r- violations
    icon        Directional icons without rtl:rotate-180

DOCUMENTATION:
    Full RTL reference: ~/.claude/rules/quality/rtl-i18n.md
    Fix suggestions:    ~/.claude/skills/rtl-validator/rtl-fix-suggestions.md
EOF
}

log_error() {
    if [[ "$JSON_MODE" == false ]]; then
        echo -e "${RED}[ERROR]${NC} $1" >&2
    fi
}

log_warning() {
    if [[ "$JSON_MODE" == false ]]; then
        echo -e "${YELLOW}[WARN]${NC} $1" >&2
    fi
}

log_info() {
    if [[ "$JSON_MODE" == false ]] && [[ "$VERBOSE" == true ]]; then
        echo -e "${CYAN}[INFO]${NC} $1"
    fi
}

log_success() {
    if [[ "$JSON_MODE" == false ]]; then
        echo -e "${GREEN}[OK]${NC} $1"
    fi
}

# Build find command exclude string
build_exclude_pattern() {
    local pattern=""
    for dir in "${EXCLUDE_DIRS[@]}"; do
        pattern="${pattern} -path '*/${dir}' -prune -o -path '*/${dir}/*' -prune -o"
    done
    echo "$pattern"
}

# Build find command extension pattern
build_extension_pattern() {
    local pattern="\( "
    local first=true
    for ext in "${EXTENSIONS[@]}"; do
        if [[ "$first" == true ]]; then
            pattern="${pattern}-name '*.${ext}'"
            first=false
        else
            pattern="${pattern} -o -name '*.${ext}'"
        fi
    done
    pattern="${pattern} \)"
    echo "$pattern"
}

# Check if node is available
check_dependencies() {
    if ! command -v node &> /dev/null; then
        log_error "Node.js is required but not installed"
        exit 2
    fi
    
    if [[ ! -f "$AST_ANALYZER" ]]; then
        log_error "AST analyzer not found at: $AST_ANALYZER"
        exit 2
    fi
}

# ==============================================================================
# SCANNING FUNCTIONS
# ==============================================================================

# Initialize JSON output array and temp file
declare -a JSON_VIOLATIONS=()
JSON_TEMP_FILE=$(mktemp)
echo "[]" > "$JSON_TEMP_FILE"

# Cleanup temp file on exit
cleanup() {
    rm -f "$JSON_TEMP_FILE" 2>/dev/null || true
}
trap cleanup EXIT

# Scan a single file
scan_file() {
    local file="$1"
    local violations_json
    
    ((FILES_SCANNED++)) || true
    log_info "Scanning: $file"
    
    if [[ "$FIX_MODE" == true ]]; then
        # Fix mode - apply fixes
        local fixed_output
        fixed_output=$(node "$AST_ANALYZER" "$file" --fix --json 2>/dev/null || echo '{"fixCount":0}')
        local fix_count
        fix_count=$(echo "$fixed_output" | node -pe "JSON.parse(require('fs').readFileSync(0,'utf-8')).fixCount" 2>/dev/null || echo "0")
        
        if [[ "$fix_count" -gt 0 ]]; then
            # Write fixed content back to file
            local fixed_content
            fixed_content=$(echo "$fixed_output" | node -pe "JSON.parse(require('fs').readFileSync(0,'utf-8')).content" 2>/dev/null)
            if [[ -n "$fixed_content" ]]; then
                echo "$fixed_content" > "$file"
                ((FIXED_COUNT += fix_count)) || true
                if [[ "$JSON_MODE" == false ]]; then
                    echo -e "${GREEN}[FIXED]${NC} $file (${fix_count} fixes)"
                fi
            fi
        fi
    else
        # Scan mode - detect violations
        # Note: AST analyzer exits with code 1 when errors found, but output is still valid JSON
        violations_json=$(node "$AST_ANALYZER" "$file" --json 2>&1) || true

        # Validate JSON output, fall back to empty array if invalid
        if ! echo "$violations_json" | node -e "JSON.parse(require('fs').readFileSync(0,'utf-8'))" 2>/dev/null; then
            violations_json="[]"
        fi
        
        # Parse violations
        local violation_count
        violation_count=$(echo "$violations_json" | node -pe "JSON.parse(require('fs').readFileSync(0,'utf-8')).length" 2>/dev/null || echo "0")
        
        if [[ "$violation_count" -gt 0 ]]; then
            ((FILES_WITH_VIOLATIONS++)) || true

            # Append violations to temp file for JSON output
            node -e "
                const existing = JSON.parse(require('fs').readFileSync('$JSON_TEMP_FILE', 'utf-8'));
                const newViolations = JSON.parse(process.argv[1]);
                require('fs').writeFileSync('$JSON_TEMP_FILE', JSON.stringify([...existing, ...newViolations]));
            " "$violations_json" 2>/dev/null || true
            
            # Parse and display violations
            if [[ "$JSON_MODE" == false ]]; then
                echo "$violations_json" | node -e "
                    const violations = JSON.parse(require('fs').readFileSync(0, 'utf-8'));
                    violations.forEach(v => {
                        const severity = v.severity === 'error' ? '\x1b[31m[ERROR]\x1b[0m' : '\x1b[33m[WARN]\x1b[0m';
                        const location = \`\${v.file}:\${v.line}:\${v.column}\`;
                        console.log(\`  \${severity} \${location}\`);
                        console.log(\`         \x1b[35m\${v.originalValue}\x1b[0m -> \x1b[32m\${v.suggestion}\x1b[0m\`);
                        if (process.env.VERBOSE === 'true' && v.context) {
                            console.log(\`         Context: \${v.context.substring(0, 60)}...\`);
                        }
                    });
                " 2>/dev/null || true
            fi
            
            # Count errors and warnings
            local error_count
            local warning_count
            error_count=$(echo "$violations_json" | node -pe "JSON.parse(require('fs').readFileSync(0,'utf-8')).filter(v=>v.severity==='error').length" 2>/dev/null || echo "0")
            warning_count=$(echo "$violations_json" | node -pe "JSON.parse(require('fs').readFileSync(0,'utf-8')).filter(v=>v.severity==='warning').length" 2>/dev/null || echo "0")
            
            ((ERRORS += error_count)) || true
            ((WARNINGS += warning_count)) || true
        fi
    fi
}

# Scan directory recursively
scan_directory() {
    local dir="$1"
    
    log_info "Scanning directory: $dir"
    
    # Build find command
    local exclude_pattern
    exclude_pattern=$(build_exclude_pattern)
    local ext_pattern
    ext_pattern=$(build_extension_pattern)
    
    # Find and scan files
    local find_cmd="find \"$dir\" $exclude_pattern -type f $ext_pattern -print"
    
    while IFS= read -r file; do
        if [[ -n "$file" ]] && [[ -f "$file" ]]; then
            scan_file "$file"
        fi
    done < <(eval "$find_cmd" 2>/dev/null || true)
}

# ==============================================================================
# OUTPUT FUNCTIONS
# ==============================================================================

print_summary() {
    if [[ "$JSON_MODE" == true ]]; then
        print_json_output
    else
        print_terminal_summary
    fi
}

print_terminal_summary() {
    echo ""
    echo -e "${BOLD}=============================================${NC}"
    echo -e "${BOLD}  SCAN SUMMARY${NC}"
    echo -e "${BOLD}=============================================${NC}"
    echo ""
    echo -e "  Files scanned:        ${CYAN}${FILES_SCANNED}${NC}"
    echo -e "  Files with issues:    ${YELLOW}${FILES_WITH_VIOLATIONS}${NC}"
    echo ""
    
    if [[ "$FIX_MODE" == true ]]; then
        echo -e "  ${GREEN}Fixes applied:        ${FIXED_COUNT}${NC}"
    else
        echo -e "  ${RED}Errors:               ${ERRORS}${NC}"
        echo -e "  ${YELLOW}Warnings:             ${WARNINGS}${NC}"
    fi
    
    echo ""
    echo -e "${BOLD}=============================================${NC}"
    
    if [[ "$ERRORS" -eq 0 ]] && [[ "$WARNINGS" -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}  RTL COMPLIANT - All checks passed!${NC}"
    elif [[ "$ERRORS" -eq 0 ]]; then
        echo -e "${YELLOW}${BOLD}  WARNINGS FOUND - Review recommended${NC}"
    else
        echo -e "${RED}${BOLD}  VIOLATIONS FOUND - Fixes required!${NC}"
        echo ""
        echo -e "  ${CYAN}Quick fix: $(basename "$0") $TARGET_DIR --fix${NC}"
        echo -e "  ${CYAN}Reference: ~/.claude/skills/rtl-validator/rtl-fix-suggestions.md${NC}"
    fi
    
    echo -e "${BOLD}=============================================${NC}"
    echo ""
}

print_json_output() {
    local all_violations
    all_violations=$(cat "$JSON_TEMP_FILE" 2>/dev/null || echo "[]")
    
    # Output final JSON
    cat << JSONEOF
{
  "version": "${VERSION}",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "target": "${TARGET_DIR}",
  "summary": {
    "filesScanned": ${FILES_SCANNED},
    "filesWithViolations": ${FILES_WITH_VIOLATIONS},
    "totalErrors": ${ERRORS},
    "totalWarnings": ${WARNINGS},
    "fixesApplied": ${FIXED_COUNT}
  },
  "status": "$([ $ERRORS -eq 0 ] && echo "pass" || echo "fail")",
  "violations": ${all_violations}
}
JSONEOF
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                JSON_MODE=true
                shift
                ;;
            --fix)
                FIX_MODE=true
                shift
                ;;
            --ci)
                CI_MODE=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                export VERBOSE=true
                shift
                ;;
            --help|-h)
                print_usage
                exit 0
                ;;
            --version)
                echo "RTL Audit v${VERSION}"
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                print_usage
                exit 2
                ;;
            *)
                TARGET_DIR="$1"
                shift
                ;;
        esac
    done
    
    # Check dependencies
    check_dependencies
    
    # Print header
    print_header
    
    # Validate target
    if [[ ! -e "$TARGET_DIR" ]]; then
        log_error "Target not found: $TARGET_DIR"
        exit 2
    fi
    
    # Scan target
    if [[ -f "$TARGET_DIR" ]]; then
        scan_file "$TARGET_DIR"
    elif [[ -d "$TARGET_DIR" ]]; then
        scan_directory "$TARGET_DIR"
    else
        log_error "Invalid target: $TARGET_DIR"
        exit 2
    fi
    
    # Print summary
    print_summary
    
    # Determine exit code
    if [[ "$CI_MODE" == true ]]; then
        if [[ "$ERRORS" -gt 0 ]]; then
            exit 1
        fi
    fi
    
    if [[ "$ERRORS" -gt 0 ]]; then
        exit 1
    fi
    
    exit 0
}

# Run main function
main "$@"
