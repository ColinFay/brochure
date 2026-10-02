## Resubmission

This is a resubmission. Following the review:

- `golem_hook()` no longer writes to the working directory: every file is now
  written under the `path` it receives from `golem::create_golem()`, which has
  no default.
- The example, the vignette and the tests that call `golem::create_golem()` now
  create the app in `tempdir()`.

## R CMD check results

0 errors | 0 warnings | 0 note

- This is a new release.
