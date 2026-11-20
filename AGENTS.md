# Repository instructions

Follow the relevant routes in
https://github.com/vhco-pro/docs/blob/0c108237fcd004e8636c0a2ca191436abd7bb7bd/AGENTS.md,
including the GitHub Actions convention for this repository's action and workflows.

This composite action publishes a PowerShell module for an exact stable release tag. It does not
check out, compute a version, tag or build anything else. PowerShell comes from
`vhco-pro/setup-pwsh-action`; the release workflow that calls this action decides the version.

Run `pwsh -File <pwsh-ci-action>/ci.ps1 -Path .` or let `test.yml` run `vhco-pro/pwsh-ci-action`:
it formats, analyzes and runs the Pester tests in `tests/`, including an end-to-end publish to a
local folder repository. `test.yml` also runs the action itself against a local repository twice.
