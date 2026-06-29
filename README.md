# PHP Helpers

A small set of cross-platform helpers for managing PHP-FPM versions. They work on
both **macOS (Homebrew)** and **Linux (Debian/Ubuntu, apt)** — each command detects
your OS and does the right thing. After installing you get four commands on your
PATH: `switch-php`, `install-php`, `xdebug-enable`, and `xdebug-disable`.

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

### Xdebug php.ini

To use Xdebug for step-debugging, add the following to your `php.ini`:

```ini
[Xdebug]
xdebug.mode=debug
xdebug.start_with_request=trigger
```

On macOS the file lives at `$(brew --prefix)/etc/php/<version>/php.ini`; on Linux
at `/etc/php/<version>/fpm/php.ini`.

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
xdebug-enable      # uncomment the Xdebug zend_extension line and restart FPM
xdebug-disable     # comment it back out and restart FPM
```

Both default to the currently active PHP version, or accept a version argument
(e.g. `xdebug-enable 8.3`).

## Notes

- Versions are given as `MAJOR.MINOR` (e.g. `8.3`); other formats are rejected.
  A `.php-version` file is read from its first line and trimmed of whitespace.
- `switch-php` verifies the target is installed **before** unlinking anything, so
  switching to a missing version fails safely (your current PHP stays linked) and
  tells you to `install-php <version>` first.
