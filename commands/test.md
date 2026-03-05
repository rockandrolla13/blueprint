Generate tests for this code. $ARGUMENTS

Determine the right testing approach:

1. Read the target code. Classify each public function:
   - Pure function (deterministic, no side effects) → property-based test
   - Stateful or IO-dependent → characterization test
   - Already tested → skip unless coverage is thin

2. For pure functions with type hints:
   Run /hypothesis on the target if available. If not, write
   Hypothesis tests manually using st.from_type where possible.

3. For stateful/IO functions:
   Write characterization tests that capture current behaviour:
   - Call with representative inputs
   - Assert on current outputs (capture reality, not intent)
   - Label clearly: "# Characterization test — captures existing behaviour"

4. After writing all tests, run them. For each failure:
   - Is it a real bug in the code? Flag it with a CR-BUG Finding ID.
   - Is the test wrong? Fix the test.

5. Present a summary:
   - Functions tested / total public functions
   - Test type per function (property-based / characterization / existing)
   - Bugs found (if any)
   - Coverage estimate

Do not modify any source code. Only create test files.
