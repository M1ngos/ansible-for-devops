#!/bin/bash
# Automated playbook runner with report generation

PLAYBOOK=${1:-docker.yml}
INVENTORY=${2:-inventory.ini}
TIMESTAMP=$(date +%Y%m%d-%H%M)
REPORT_DIR="reports/$(basename $PLAYBOOK .yml)"
REPORT_FILE="$REPORT_DIR/run-$TIMESTAMP.yml"

mkdir -p "$REPORT_DIR"

echo "Running: ansible-playbook $PLAYBOOK -i $INVENTORY"
echo "Generating report: $REPORT_FILE"
echo ""

# Run playbook with JSON output
ansible-playbook $PLAYBOOK -i $INVENTORY -v 2>&1 | tee /tmp/ansible-output-$TIMESTAMP.log

# Parse results and generate report
echo ""
echo "=== Generating Report ==="

# Count results
TOTAL=$(grep -c "PLAY RECAP" /tmp/ansible-output-$TIMESTAMP.log)
SUCCESS=$(grep -oP '\w+ : ok=\d+' /tmp/ansible-output-$TIMESTAMP.log | wc -l)
FAILED=$(grep -oP '\w+ : .*failed=\d+' /tmp/ansible-output-$TIMESTAMP.log | grep -v "failed=0" | wc -l)
UNREACHABLE=$(grep -oP '\w+ : .*unreachable=\d+' /tmp/ansible-output-$TIMESTAMP.log | grep -v "unreachable=0" | wc -l)

# Generate YAML report
cat > "$REPORT_FILE" << EOF
# Playbook Run Report
# Date: $(date -Iseconds)
# Playbook: $PLAYBOOK

## Summary
- Total hosts: $((SUCCESS + FAILED + UNREACHABLE))
- Successful: $SUCCESS
- Failed: $FAILED
- Unreachable: $UNREACHABLE

## Results by Host
EOF

# Parse per-host results
grep -E "^\w+ +: " /tmp/ansible-output-$TIMESTAMP.log | while read line; do
    HOST=$(echo $line | awk '{print $1}')
    OK=$(echo $line | grep -oP 'ok=\d+' | cut -d= -f2)
    FAILED_COUNT=$(echo $line | grep -oP 'failed=\d+' | cut -d= -f2)
    
    if [ "$FAILED_COUNT" -gt 0 ]; then
        echo "- $HOST: FAILED (ok=$OK, failed=$FAILED_COUNT)" >> "$REPORT_FILE"
    else
        echo "- $HOST: SUCCESS (ok=$OK)" >> "$REPORT_FILE"
    fi
done

echo ""
echo "Report saved to: $REPORT_FILE"
echo "View with: cat $REPORT_FILE"

# Cleanup
rm -f /tmp/ansible-output-$TIMESTAMP.log
