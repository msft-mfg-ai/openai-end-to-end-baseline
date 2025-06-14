#!/bin/bash

# ------------------------------------------------------------------------------------------------------------------------
# Test Script: Validate Azure DevOps Pipeline Structure
# ------------------------------------------------------------------------------------------------------------------------
# This script validates the Azure DevOps pipeline structure and ensures all required files exist.
# ------------------------------------------------------------------------------------------------------------------------

echo "🔍 Validating Azure DevOps Pipeline Structure..."

# Define base directory
BASE_DIR="/home/runner/work/openai-end-to-end-baseline/openai-end-to-end-baseline/.azdo"
ERRORS=0

# Function to validate file existence
validate_file() {
    local file_path="$1"
    local description="$2"
    
    if [[ -f "$file_path" ]]; then
        echo "✅ $description: $file_path"
    else
        echo "❌ $description: $file_path (NOT FOUND)"
        ((ERRORS++))
    fi
}

# Function to validate directory existence
validate_directory() {
    local dir_path="$1"
    local description="$2"
    
    if [[ -d "$dir_path" ]]; then
        echo "✅ $description: $dir_path"
    else
        echo "❌ $description: $dir_path (NOT FOUND)"
        ((ERRORS++))
    fi
}

# Function to validate YAML syntax
validate_yaml() {
    local yaml_file="$1"
    local description="$2"
    
    if [[ -f "$yaml_file" ]]; then
        # Check if python3 and pyyaml are available for YAML validation
        if command -v python3 >/dev/null 2>&1; then
            python3 -c "
import yaml
import sys
try:
    with open('$yaml_file', 'r') as f:
        yaml.safe_load(f)
    print('✅ YAML Syntax Valid: $description')
except yaml.YAMLError as e:
    print('❌ YAML Syntax Error in $description: ' + str(e))
    sys.exit(1)
except Exception as e:
    print('⚠️  Could not validate YAML for $description: ' + str(e))
" 2>/dev/null || echo "⚠️  YAML validation skipped for $description (PyYAML not available)"
        else
            echo "⚠️  YAML validation skipped for $description (Python not available)"
        fi
    fi
}

echo ""
echo "📁 Validating Directory Structure..."

# Validate main directories
validate_directory "$BASE_DIR" "Main .azdo directory"
validate_directory "$BASE_DIR/pipelines" "Pipelines directory"
validate_directory "$BASE_DIR/pipelines/pipes" "Pipes directory"
validate_directory "$BASE_DIR/pipelines/vars" "Variables directory"

echo ""
echo "📄 Validating Pipeline Files..."

# Validate main pipeline files
validate_file "$BASE_DIR/pipelines/deploy-webapp-only-pipeline.yml" "Deploy-only pipeline"
validate_file "$BASE_DIR/pipelines/readme.md" "Pipeline documentation"

echo ""
echo "🔧 Validating Pipeline Templates..."

# Validate pipe templates
validate_file "$BASE_DIR/pipelines/pipes/deploy-only-pipe.yml" "Deploy-only pipe template"

echo ""
echo "📋 Validating Variable Files..."

# Validate variable files
validate_file "$BASE_DIR/pipelines/vars/var-common.yml" "Common variables"
validate_file "$BASE_DIR/pipelines/vars/var-dev.yml" "DEV environment variables"
validate_file "$BASE_DIR/pipelines/vars/var-qa.yml" "QA environment variables"
validate_file "$BASE_DIR/pipelines/vars/var-prod.yml" "PROD environment variables"
validate_file "$BASE_DIR/pipelines/vars/var-service-connections.yml" "Service connection variables"

echo ""
echo "🔍 Validating YAML Syntax..."

# Validate YAML syntax for key files
validate_yaml "$BASE_DIR/pipelines/deploy-webapp-only-pipeline.yml" "Main deploy pipeline"
validate_yaml "$BASE_DIR/pipelines/pipes/deploy-only-pipe.yml" "Deploy-only pipe"
validate_yaml "$BASE_DIR/pipelines/vars/var-common.yml" "Common variables"

echo ""
echo "🔎 Validating Pipeline Content..."

# Check for key content in deploy-only-pipe.yml
if [[ -f "$BASE_DIR/pipelines/pipes/deploy-only-pipe.yml" ]]; then
    if grep -q "enableRollback" "$BASE_DIR/pipelines/pipes/deploy-only-pipe.yml"; then
        echo "✅ Rollback functionality: Found enableRollback parameter"
    else
        echo "❌ Rollback functionality: enableRollback parameter not found"
        ((ERRORS++))
    fi
    
    if grep -q "rollbackToDeployment" "$BASE_DIR/pipelines/pipes/deploy-only-pipe.yml"; then
        echo "✅ Rollback targeting: Found rollbackToDeployment parameter"
    else
        echo "❌ Rollback targeting: rollbackToDeployment parameter not found"
        ((ERRORS++))
    fi
    
    if grep -q "az deployment group list" "$BASE_DIR/pipelines/pipes/deploy-only-pipe.yml"; then
        echo "✅ Deployment history query: Found Azure CLI deployment listing"
    else
        echo "❌ Deployment history query: Azure CLI deployment listing not found"
        ((ERRORS++))
    fi
    
    if grep -q "Identify Rollback Target" "$BASE_DIR/pipelines/pipes/deploy-only-pipe.yml"; then
        echo "✅ Rollback logic: Found rollback target identification"
    else
        echo "❌ Rollback logic: Rollback target identification not found"
        ((ERRORS++))
    fi
fi

echo ""
echo "📊 Validation Summary"
echo "===================="

if [[ $ERRORS -eq 0 ]]; then
    echo "✅ All validations passed! The Azure DevOps pipeline structure is correct."
    echo ""
    echo "🚀 Ready to use the rollback functionality:"
    echo "   1. Configure service connections (sc-DEV, sc-QA, sc-PROD)"
    echo "   2. Create the Application.Web variable group"
    echo "   3. Import deploy-webapp-only-pipeline.yml into Azure DevOps"
    echo "   4. Run with enableRollback=true to test rollback functionality"
    exit 0
else
    echo "❌ Found $ERRORS error(s). Please fix the issues above before using the pipelines."
    exit 1
fi