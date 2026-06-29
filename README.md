# PHP Helpers

A small set of cross-platform helpers for managing PHP-FPM versions. They work on
both **macOS (Homebrew)** and **Linux (Debian/Ubuntu, apt)** — each command detects
your OS and does the right thing. After installing you get these commands on your
PATH: `switch-php`, `install-php`, `xdebug-enable`, `xdebug-disable`, and
`xdebug-run`.

## Requirements

- **macOS:** [Homebrew](https://brew.sh). PHP versions come from Homebrew **core**
  (e.g. `php`, `php@8.4`, `php@8.3`).
- **Linux:** `apt` and `update-alternatives` (Debian/Ubuntu).

## Installation

```bash
bash install.sh
```

This copies the commands into `~/.local/bin` and adds that directory to your PATH
in the right shell rc (`~/.zshrc` for zsh, `~/.bashrc` for bash). It's safe to
re-run. Restart your shell (or `source` your rc file) afterwards.

No manual `php.ini` editing is required — `install-php`, `switch-php`, and the
Xdebug commands configure everything for you.

## Usage

### Switch PHP

```bash
switch-php 8.3
```

On macOS this links the `php@8.3` Homebrew formula; on Linux it uses
`update-alternatives`. If no version is given, the script looks for a
`.php-version` file in the current directory, and otherwise prompts you (showing
the installed versions).

### Install PHP

```bash
install-php 8.3
```

On macOS this runs `brew install php@8.3` (Homebrew core) and installs Xdebug for
that version via `pecl`. On Linux it installs the `php8.3-*` apt packages
(including `php8.3-xdebug`).

### Enable / Disable Xdebug

```bash
xdebug-enable      # turn on step-debugging (mode=debug) and restart FPM
xdebug-disable     # turn it off (mode=off) and restart FPM
```

These manage a single tool-owned file,
`$(brew --prefix)/etc/php/<version>/conf.d/zz-xdebug.ini` (on Linux, the per-SAPI
`conf.d` dirs), so your `php.ini` is never edited. `xdebug-enable` writes a ready
-to-use debug config:

```ini
xdebug.mode=debug
xdebug.start_with_request=trigger   ; debug only when triggered (no hijacking)
xdebug.client_host=localhost
xdebug.client_port=9003
```

Both commands default to the currently active PHP version, or accept one
(e.g. `xdebug-enable 8.3`). With `trigger`, a plain `php …` runs normally; a debug
session starts only when triggered, so Xdebug never blocks unrelated commands.

**To debug**, point your IDE/editor to listen on port **9003**, then:

```bash
xdebug-run php listings.test      # CLI: triggers a debug session for this run
```

`xdebug-run` just sets `XDEBUG_TRIGGER=1` and runs your command. For web requests,
your IDE's browser extension (the "Xdebug helper" bookmarklet/cookie) is the
trigger — no extra step.

## Notes

- Versions are given as `MAJOR.MINOR` (e.g. `8.3`); other formats are rejected.
  A `.php-version` file is read from its first line and trimmed of whitespace.
- `switch-php` verifies the target is installed **before** unlinking anything, so
  switching to a missing version fails safely (your current PHP stays linked) and
  tells you to `install-php <version>` first.
