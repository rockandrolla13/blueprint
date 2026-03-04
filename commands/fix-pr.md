Fix PR review errors. $ARGUMENTS

1. Read the PR review comments or CI feedback provided
2. Run code-review on ONLY the files mentioned in the review
3. For each review comment, map it to a code-review Finding ID (CR-*)
4. Group fixes by file, not by reviewer comment
5. Fix one file at a time. After each file:
   - Run the relevant tests
   - Show the diff
   - Wait for my approval before moving to the next file
6. After all fixes, run code-review again on the changed files
   to verify no new issues were introduced

If a reviewer comment is ambiguous or I disagree with it, flag it
and ask me whether to fix it or push back.

Do not touch files not mentioned in the review.
