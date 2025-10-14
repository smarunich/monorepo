# Testing Quick Reference

## Quick Start

```bash
# Run all tests
./test-enterprise-gateway-demo.sh

# Run specific test suite
./test-enterprise-gateway-demo.sh --unit
./test-enterprise-gateway-demo.sh --integration

# Verbose mode for debugging
./test-enterprise-gateway-demo.sh --all -v
```

## Test Coverage Map

### Unit Tests (30 tests)
- ✅ `get_backend_for_namespace()` - Backend mapping
- ✅ `get_business_service_for_namespace()` - Service rotation
- ✅ `get_target_port_for_namespace()` - Port resolution
- ✅ `get_app_selector_for_namespace()` - Selector mapping
- ✅ `get_cloud_annotations()` - Cloud provider configs
- ✅ `get_gateway_annotations_for_namespace()` - Gateway annotations
- ✅ `get_backend_image()` - Image resolution

### Broken Services Tests (16 tests) - CRITICAL
- ✅ Normal error rates (4 tests)
- ✅ High error rates when enabled (4 tests)
- ✅ Environment isolation (4 tests)
- ✅ Array rotation logic (4 tests)

### Integration Tests (15 tests)
- ✅ Command-line parsing
- ✅ YAML generation
- ✅ Preview mode (--skip-apply)
- ✅ Broken services flag
- ✅ Error handling
- ✅ Demo scenario execution

## Critical Test Cases

### Broken Services Mode

**Test:** Verify error rates are correctly applied

```bash
# Should inject high error rates for failover testing
BROKEN_SERVICES=true

Expected Results:
- market-data-gateway in prod:     50% error rate
- trading-engine-proxy in staging: 70% error rate
- compliance-validator in dev:     60% error rate
- settlement-processor in test:    80% error rate
```

**Test:** Verify services are NOT broken in wrong environment

```bash
# market-data-gateway should only be broken in prod
BROKEN_SERVICES=true

Expected Results:
- market-data-gateway in staging: Normal rate (0.02)
- market-data-gateway in dev:     Normal rate (0.03)
- market-data-gateway in test:    Normal rate (0.05)
```

### Array Rotation Logic

**Test:** Verify correct service-to-environment mapping

```bash
Namespace Index → Business Service
0 (prod)     → market-data-gateway
1 (staging)  → trading-engine-proxy
2 (dev)      → compliance-validator
3 (test)     → settlement-processor
```

## Common Test Scenarios

### Test Script Changes

```bash
# After modifying enterprise-gateway-demo.sh
./test-enterprise-gateway-demo.sh --all

# If tests fail, run with verbose
./test-enterprise-gateway-demo.sh --all -v 2>&1 | tee test-failure.log
```

### Test New Feature

```bash
# 1. Add function to enterprise-gateway-demo.sh
# 2. Add unit test to test-enterprise-gateway-demo.sh
# 3. Run tests
./test-enterprise-gateway-demo.sh --unit

# 4. Add integration test if needed
./test-enterprise-gateway-demo.sh --integration
```

### Debug Failing Test

```bash
# Run with verbose output
./test-enterprise-gateway-demo.sh --all -v

# Check test output directory
ls -la test_output/

# Review generated YAML
cat test_output/generated_yaml.txt
```

## Expected Test Output

### Success
```
=================================================================
TEST RESULTS SUMMARY
=================================================================

Total Tests Run:     61
Tests Passed:        61
Tests Failed:        0

Pass Rate:           100.00%

========================================
   ALL TESTS PASSED SUCCESSFULLY!
========================================
```

### Failure
```
=================================================================
TEST RESULTS SUMMARY
=================================================================

Total Tests Run:     61
Tests Passed:        59
Tests Failed:        2

Failed Tests:
  ✗ market-data-gateway in prod should have 0.50 error rate (50%, broken mode)
  ✗ YAML generation should include gateway annotations

Pass Rate:           96.72%

========================================
   SOME TESTS FAILED
========================================
```

## Assertion Functions

```bash
# Equality check
assert_equals "expected" "$actual" "Test description"

# Non-empty check
assert_not_empty "$value" "Value should not be empty"

# Substring check
assert_contains "$haystack" "needle" "Should contain substring"

# Regex match
assert_matches_regex "$value" "^[0-9]+$" "Should be numeric"

# File existence
assert_file_exists "/path/to/file" "File should exist"

# Exit code
assert_exit_code 0 $? "Command should succeed"
```

## Troubleshooting

### bc not found
```bash
# macOS
brew install bc

# Linux
sudo apt-get install bc
```

### Tests timing out
```bash
# Increase timeout in test script
# Or run specific test suite
./test-enterprise-gateway-demo.sh --unit  # Faster
```

### Mock commands not working
```bash
# Clean up and retry
rm -rf test_output/
./test-enterprise-gateway-demo.sh --all
```

### bc floating-point issues
```bash
# Test bc installation
echo "0.01 * 2" | bc -l
# Should output: 0.02 or .02 (both handled by tests)
```

## Test File Locations

```
api-demo/
├── enterprise-gateway-demo.sh              # Target script
├── test-enterprise-gateway-demo.sh         # Test framework
├── TEST_FRAMEWORK_README.md                # Full documentation
├── TESTING_QUICK_REFERENCE.md              # This file
└── test_output/                            # Generated during tests
    ├── functions.sh                        # Extracted functions
    ├── mock_bin/                           # Mock executables
    │   ├── kubectl
    │   └── openssl
    ├── generated_yaml.txt                  # Sample output
    └── *.log                               # Test logs
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Run Tests
  run: |
    cd api-demo
    ./test-enterprise-gateway-demo.sh --all
```

### GitLab CI
```yaml
test:
  script:
    - cd api-demo
    - ./test-enterprise-gateway-demo.sh --all
```

### Jenkins
```groovy
stage('Test') {
    steps {
        dir('api-demo') {
            sh './test-enterprise-gateway-demo.sh --all'
        }
    }
}
```

## Test Metrics

| Metric | Value |
|--------|-------|
| Total Tests | 61 |
| Unit Tests | 30 |
| Broken Services Tests | 16 |
| Integration Tests | 15 |
| Pass Rate Target | 100% |
| Coverage Target | 90%+ |
| Execution Time | ~30-60s |

## Important Notes

1. **Always use `--skip-apply`** in integration tests to avoid creating actual Kubernetes resources
2. **bc is required** for floating-point arithmetic in broken services tests
3. **Mocks are automatic** - test framework handles kubectl and openssl mocking
4. **Verbose mode** (`-v`) is helpful for debugging but produces lengthy output
5. **Array rotation is critical** - ensures correct service-to-environment mapping for broken services

## Additional Resources

- Full documentation: `TEST_FRAMEWORK_README.md`
- Main demo script: `enterprise-gateway-demo.sh`
- Test script: `test-enterprise-gateway-demo.sh`
- CI/CD workflow: `.github/workflows/test-enterprise-demo.yml`

## Support

For issues or questions:
1. Review test output with verbose mode
2. Check `test_output/` directory for generated files
3. Ensure bc is installed and working
4. Verify script permissions (`chmod +x`)
