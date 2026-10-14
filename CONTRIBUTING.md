# Contributing to Foqos

For setup help or troubleshooting, start with [SUPPORT.md](SUPPORT.md).

## Before opening an issue or pull request

- Search open and closed issues and pull requests. Add useful new evidence to an existing report
  instead of opening a duplicate.
- For a substantial feature or refactor, describe the problem and proposed scope in an issue before
  investing in an implementation. Maintainer review time is limited, and proposals may be declined.
- Keep each contribution focused on one verified problem or agreed feature.

## Verify your contribution

You are responsible for understanding and checking everything you submit, including AI-assisted work.
Do not publish unverified automated audits, speculative optimization batches, or agent experiments.
Keep experiments local until you have reviewed and verified their results.

Bug reports should include observed behavior and steps to reproduce. Performance or memory reports
should include measurements, the device/build used, and a reproducible workload. Explain the user
impact; a code pattern alone does not demonstrate a performance problem. Pull requests should explain
what changed and how you verified the behavior, including any checks you could not run.

## Development checks

Follow the repository's existing Swift conventions and update documentation when behavior changes.
Run `make lint` (or `make lint-fix`) and `make build` before submitting. Include any environment or
signing limitation in the pull request. See [README.md](README.md#development) for setup and commands.

Unverified reports, duplicate proposals, and contributions outside the project's scope may be closed
without a detailed review. Contributions do not guarantee a response or acceptance.
