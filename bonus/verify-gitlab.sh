#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

echo -e "${BLUE}========================================${RESET}"
echo -e "${BLUE}GitLab Configuration Verification${RESET}"
echo -e "${BLUE}========================================${RESET}\n"

# Check if GitLab is installed
if ! helm list -n gitlab 2>/dev/null | grep -q gitlab; then
    echo -e "${RED}✗ GitLab is not installed${RESET}"
    exit 1
fi

echo -e "${GREEN}✓ GitLab is installed${RESET}\n"

# Check edition
echo -e "${BLUE}Checking GitLab Edition:${RESET}"
EDITION=$(helm get values gitlab -n gitlab 2>/dev/null | grep -A1 "^global:" | grep edition | awk '{print $2}')
if [ "$EDITION" == "ce" ]; then
    echo -e "${GREEN}✓ Using Community Edition (ce)${RESET}"
else
    echo -e "${YELLOW}⚠ Using Enterprise Edition (ee) - should be CE for optimization${RESET}"
fi

# Check running images
echo -e "\n${BLUE}Checking running images:${RESET}"
EE_IMAGES=$(kubectl get pods -n gitlab -o jsonpath='{.items[*].spec.containers[*].image}' 2>/dev/null | tr ' ' '\n' | grep -c "\-ee:")
CE_IMAGES=$(kubectl get pods -n gitlab -o jsonpath='{.items[*].spec.containers[*].image}' 2>/dev/null | tr ' ' '\n' | grep -c "\-ce:")

if [ "$CE_IMAGES" -gt 0 ] && [ "$EE_IMAGES" -eq 0 ]; then
    echo -e "${GREEN}✓ All images are Community Edition (-ce)${RESET}"
elif [ "$EE_IMAGES" -gt 0 ]; then
    echo -e "${YELLOW}⚠ Found $EE_IMAGES Enterprise Edition images (-ee)${RESET}"
    echo -e "${YELLOW}  Run 'make uninstall && make all' to switch to CE${RESET}"
fi

# Check disabled components
echo -e "\n${BLUE}Checking disabled components:${RESET}"

# KAS
if kubectl get pods -n gitlab 2>/dev/null | grep -q "gitlab-kas"; then
    echo -e "${RED}✗ KAS is running (should be disabled)${RESET}"
else
    echo -e "${GREEN}✓ KAS is disabled${RESET}"
fi

# Minio
if kubectl get pods -n gitlab 2>/dev/null | grep -q "gitlab-minio"; then
    echo -e "${RED}✗ Minio is running (should be disabled)${RESET}"
else
    echo -e "${GREEN}✓ Minio is disabled${RESET}"
fi

# Registry
if kubectl get pods -n gitlab 2>/dev/null | grep -q "gitlab-registry"; then
    echo -e "${RED}✗ Registry is running (should be disabled)${RESET}"
else
    echo -e "${GREEN}✓ Registry is disabled${RESET}"
fi

# Runner
if kubectl get pods -n gitlab 2>/dev/null | grep -q "gitlab-runner"; then
    echo -e "${RED}✗ Runner is running (should be disabled)${RESET}"
else
    echo -e "${GREEN}✓ Runner is disabled${RESET}"
fi

# Check pod count
echo -e "\n${BLUE}Pod count:${RESET}"
POD_COUNT=$(kubectl get pods -n gitlab --no-headers 2>/dev/null | wc -l)
echo -e "  Total pods: ${YELLOW}$POD_COUNT${RESET}"

if [ "$POD_COUNT" -le 12 ]; then
    echo -e "${GREEN}✓ Pod count is optimized (≤12 expected)${RESET}"
else
    echo -e "${YELLOW}⚠ Pod count is high ($POD_COUNT > 12)${RESET}"
    echo -e "${YELLOW}  Expected: ~8-10 pods with optimizations${RESET}"
    echo -e "${YELLOW}  Recommendation: Run 'make uninstall && make all'${RESET}"
fi

# Check resource limits
echo -e "\n${BLUE}Checking resource limits:${RESET}"
SIDEKIQ_MEM=$(helm get values gitlab -n gitlab 2>/dev/null | grep -A5 "sidekiq:" | grep -A2 "limits:" | grep memory | awk '{print $2}')
WEBSERVICE_MEM=$(helm get values gitlab -n gitlab 2>/dev/null | grep -A5 "webservice:" | grep -A2 "limits:" | grep memory | awk '{print $2}')

echo -e "  Sidekiq memory limit: ${YELLOW}$SIDEKIQ_MEM${RESET} (should be ≥1G)"
echo -e "  Webservice memory limit: ${YELLOW}$WEBSERVICE_MEM${RESET} (should be ≥1.5G)"

# Summary
echo -e "\n${BLUE}========================================${RESET}"
echo -e "${BLUE}Summary:${RESET}"
echo -e "${BLUE}========================================${RESET}"

ISSUES=0
if [ "$EDITION" != "ce" ]; then ((ISSUES++)); fi
if [ "$EE_IMAGES" -gt 0 ]; then ((ISSUES++)); fi
if kubectl get pods -n gitlab 2>/dev/null | grep -q "gitlab-kas\|gitlab-minio\|gitlab-registry"; then
    ((ISSUES++))
fi
if [ "$POD_COUNT" -gt 12 ]; then ((ISSUES++)); fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ GitLab is fully optimized!${RESET}"
else
    echo -e "${YELLOW}⚠ Found $ISSUES optimization issue(s)${RESET}"
    echo -e "${YELLOW}To fix: cd /home/sxmon/Documents/IOT/bonus && make uninstall && make all${RESET}"
fi

echo ""
