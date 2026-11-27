# AGENTS.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Document What Isn't Self-Evident

Comment the why, not the what. Skip filler.
No docstrings restating the signature. No section banners or change logs in code.
Match the comment density of surrounding code.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

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

This Mac (Apple M1) cannot use nested virtualization (requires M3+) and has no Docker Desktop. `docker` / `docker compose` talk to [socktainer](https://socktainer.github.io), a Docker Engine API (v1.51) on top of Apple's `container` CLI, so each container is its own lightweight VM. `DOCKER_HOST` is set in `~/.zshrc-local`; socktainer runs as a brew service (`brew services start socktainer`).

- `run/exec/logs/ps`, `--restart`, `--privileged`, volumes, `build` and `docker compose` (service-name DNS, healthchecks, ports) work. Compatibility is partial; if an endpoint is missing, fall back to the `container` CLI.
- `docker build` hangs with `no host or :authority header present` when the builder is `container-builder-shim` 0.13.3+. socktainer 1.6.1 is built against container 1.6.1, whose builder client only works with shim <= 0.13.2, so `~/.config/container/config.toml` pins `[build] image` to 0.13.2 (applied after `container system stop && container system start`, then `container builder delete --force`). Drop the pin once a socktainer release is built against container >= 1.7.1.
- Containers have no outbound network while NordVPN is connected (DNS resolves, every connection times out). Disconnect it before builds or package installs.
- `--network host` is accepted but each container still gets its own VM IP, so containers cannot share `127.0.0.1` and there is no `docker0`. `--network none` still leaves an `eth0`.
- If a test needs several processes on one network (shared `127.0.0.1`, host networking), run them in one container, or run them directly in `linux-test` (below).

Use the `linux-test` container machine (Alpine 3.22) only when a full Linux VM is needed rather than a container. It has no Docker on purpose; never install Docker in it.

- Run commands with `container machine run --root -n linux-test -- ...`. The Mac home is mounted at its real path; `$HOME` inside is `/root`.
- Caveat: `machine run -- sh -c "a && b"` breaks quoting — run compound commands via script files under the home mount
- Caveat: `ubuntu:24.04` won't boot as a machine (init exit 127) — use Alpine for machines
- Caveat: run `machine run` sessions one at a time. Two concurrent sessions corrupt each other's output (it looks like broken shell quoting) and can kill the running peer with SIGTERM (exit 143). While a long run is going, don't start a second `machine run` — read its background output file instead, or chain the steps into a single invocation.
- Space freed inside the machine returns to the Mac only after `fstrim -v /` inside it.