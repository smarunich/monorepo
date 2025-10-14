# TSB Gateway API Demo - Test Suite

This directory contains the comprehensive test framework for the TSB Gateway API Demo Suite, with a focus on testing the `enterprise-gateway-demo.sh` script and its functionality.

## 📁 Contents

- **`test-enterprise-gateway-demo.sh`** - Main test framework (executable)
- **`TEST_FRAMEWORK_README.md`** - Complete documentation and usage guide
- **`TESTING_QUICK_REFERENCE.md`** - Quick reference for common testing tasks
- **`TEST_FRAMEWORK_SUMMARY.md`** - High-level overview and test coverage summary

## 🚀 Quick Start

```bash
# Run all tests (from api-demo directory)
./tests/test-enterprise-gateway-demo.sh

# Run unit tests only (fast, ~15s)
./tests/test-enterprise-gateway-demo.sh --unit

# Run integration tests only
./tests/test-enterprise-gateway-demo.sh --integration

# Run with verbose output
./tests/test-enterprise-gateway-demo.sh --all -v
```

## 📊 Test Coverage

### Unit Tests (30 tests)
- Function-level testing for all major bash functions
- Namespace and backend mapping validation
- Cloud provider annotation generation
- Gateway annotation configuration

### Broken Services Logic Tests (16 tests)
- **CRITICAL**: Tests the new `--broken-services` flag functionality
- Validates error rate calculation and injection
- Tests service-to-environment mapping (array rotation logic)
- Verifies environment isolation

### Integration Tests (15 tests)
- Command-line argument parsing
- Full deployment workflow validation (using --skip-apply)
- YAML generation correctness
- Error handling and edge cases

**Total: 61 tests with 100% pass rate**

## 🎯 Key Testing Areas

### 1. Normal Operations
Tests the script works correctly without the `--broken-services` flag:
- Correct namespace creation
- Proper backend deployment
- Accurate service mapping
- Valid YAML generation

### 2. Broken Services Mode (NEW)
Validates the traffic failover testing functionality:

| Service | Environment | Error Rate | Status |
|---------|-------------|------------|--------|
| market-data-gateway | prod | 50% | ✅ Tested |
| trading-engine-proxy | staging | 70% | ✅ Tested |
| compliance-validator | dev | 100% | ✅ Tested |
| settlement-processor | test | 100% | ✅ Tested |

### 3. Cloud Provider Support
- AWS annotations
- GCP annotations
- Azure annotations

### 4. Error Handling
- Invalid arguments
- Missing prerequisites
- Invalid cloud providers
- Kubernetes connection failures

## 📚 Documentation

For detailed information, see:
- **[TEST_FRAMEWORK_README.md](./TEST_FRAMEWORK_README.md)** - Complete guide with examples
- **[TESTING_QUICK_REFERENCE.md](./TESTING_QUICK_REFERENCE.md)** - Quick command reference
- **[TEST_FRAMEWORK_SUMMARY.md](./TEST_FRAMEWORK_SUMMARY.md)** - High-level overview

## 🔧 Requirements

### Local Testing
- Bash 4.0+ (or Bash 3.2+ on macOS)
- `bc` command (for floating-point arithmetic)
- Standard Unix utilities (grep, sed, awk, etc.)

### CI/CD Testing
The test suite is integrated with GitHub Actions:
- **File**: `../.github/workflows/test-enterprise-demo.yml`
- **Triggers**: Push to main/develop, pull requests
- **Jobs**: Unit tests, integration tests, security scan, broken services validation

## 🎨 Test Output

The test framework provides color-coded output:
- 🟢 **Green**: Tests passed
- 🔴 **Red**: Tests failed
- 🟡 **Yellow**: Warnings or skipped tests
- 🔵 **Blue**: Informational messages

### Example Output
```
========================================
Running Unit Tests
========================================

✓ get_backend_for_namespace returns httpbin for wealth-prod
✓ get_backend_for_namespace returns httpbingo for wealth-staging
✓ get_backend_for_namespace returns nginx for wealth-dev
✓ get_backend_for_namespace returns echo for wealth-test

...

========================================
Test Summary
========================================
Total Tests Run:     61
Tests Passed:        61
Tests Failed:        0
Pass Rate:           100.00%

ALL TESTS PASSED SUCCESSFULLY!
```

## 🧪 Adding New Tests

To add new test cases:

1. **Unit Tests**: Add to the `run_unit_tests()` function
2. **Integration Tests**: Add to the `run_integration_tests()` function
3. **Use Assertions**: Leverage the built-in assertion functions

### Example Test Function
```bash
test_my_new_function() {
    local result=$(my_function "input")
    local expected="expected_output"

    assert_equals "$result" "$expected" "my_function should return correct value"
}
```

## 🔍 Troubleshooting

### Common Issues

1. **Tests fail with "bc: command not found"**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install bc

   # macOS
   brew install bc
   ```

2. **Permission denied errors**
   ```bash
   chmod +x test-enterprise-gateway-demo.sh
   ```

3. **Tests fail in CI/CD but pass locally**
   - Check the GitHub Actions logs
   - Verify the correct paths are used
   - Ensure dependencies are installed in the workflow

### Debug Mode

Run tests with verbose output to see detailed execution:
```bash
./tests/test-enterprise-gateway-demo.sh --all -v
```

## 📈 Test Metrics

- **Total Test Cases**: 61
- **Unit Tests**: 30 (49%)
- **Broken Services Tests**: 16 (26%)
- **Integration Tests**: 15 (25%)
- **Average Execution Time**: ~30 seconds
- **Unit Tests Only**: ~15 seconds
- **Code Coverage**: 90%+ of critical functions

## 🤝 Contributing

When contributing new functionality to the demo scripts:

1. **Write tests first** (TDD approach recommended)
2. **Add unit tests** for new functions
3. **Add integration tests** for new workflows
4. **Update documentation** in this folder
5. **Verify CI/CD passes** before merging

## 📝 CI/CD Integration

The test suite is automatically run on:
- Push to `main` or `develop` branches
- Pull requests to `main`
- Changes to demo scripts or test files

Results are uploaded as artifacts and displayed in the PR summary.

## 🔗 Related Files

- Main demo script: `../enterprise-gateway-demo.sh`
- Advanced demo: `../advanced-demo.sh`
- CI/CD workflow: `../.github/workflows/test-enterprise-demo.yml`
- Project README: `../README.md`

---

For more information, see the [main project README](../README.md) or the [detailed test framework documentation](./TEST_FRAMEWORK_README.md).
