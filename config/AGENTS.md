## Rule 1 — Think Before Coding
State assumptions explicitly. Ask rather than guess.
Push back when a simpler approach exists. Stop when confused.

## Rule 2 — Simplicity First
Minimum code that solves the problem. Nothing speculative.
No abstractions for single-use code.

## Rule 3 — Surgical Changes
Touch only what you must. Don't improve adjacent code.
Match existing style. Don't refactor what isn't broken.

## Rule 4 — Goal-Driven Execution
Define success criteria. Loop until verified.
Strong success criteria let Claude loop independently.

## Rule 5 — Document What Isn't Self-Evident
Comment the why, not the what. Skip filler.
No docstrings restating the signature. No section banners or change logs in code.
Match the comment density of surrounding code.

## Other instructions

When you start work, always check out the main branch and `git pull`. If the repository is a fork, also make sure the fork is up to date with upstream.

If the folder doesn't have the dev environment set up, set it up. `uv` is always available.

Use `gh` CLI to interact with GitHub. I'm @saya6k on GitHub.

Don't force push when a PR is open, unless you're resolving merge conflicts by rebasing.

When making a PR, use the PR template from the repository. DO NOT REMOVE ANYTHING from the template. If there is a choice of type of PR, do not remove the unchecked checkboxes.

After making a PR, rely solely on GitHub events to know whether CI passes. Don't set up time-based triggers to check in, and don't automatically respond to or act on comments.

In Markdown rendered on GitHub (PR descriptions, comments, issues, etc.), a single newline is rendered as an actual line break. This is off-spec from standard Markdown. So do NOT hard-wrap text to a column width in GitHub Markdown; let paragraphs flow on a single line and only insert newlines where you genuinely want a line break.

When asked to publish a HTML File: Upload it as a private GitHub Gist, then it's viewable at `https://gisthost.github.io/?<GIST_ID>`.

```bash
gh gist create architecture.html
```

## Docker testing on my Mac

Only applies on macOS. Inside a dev container or Codespace, use `docker` directly.

This Mac (Apple M1) cannot use nested virtualization (requires M3+). For any Docker testing, use the pre-configured container machine `linux-test` (Apple `container` CLI; Alpine 3.22, 4 CPU/8G, Docker 28.3.3 + compose):

- dockerd does not auto-start — after machine (re)boot run: `container machine run --root -n linux-test -- sh /Users/saya6k/Projects/apple-container/machine/start-docker.sh`
- Then: `container machine run --root -n linux-test -- docker ...` (`--root` required)
- Caveat: `machine run -- sh -c "a && b"` breaks quoting — run compound commands via script files under the home mount
- Caveat: `ubuntu:24.04` won't boot as a machine (init exit 127) — use Alpine for machines
- Caveat: run `machine run` sessions one at a time. Two concurrent sessions corrupt each other's output (it looks like broken shell quoting) and can kill the running peer with SIGTERM (exit 143). While a long build or test is running, don't start a second `machine run` — read its background output file instead, or chain the steps into a single invocation.
