# ical-guy

[![CI](https://github.com/itspriddle/ical-guy/actions/workflows/ci.yml/badge.svg)](https://github.com/itspriddle/ical-guy/actions/workflows/ci.yml)
[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-FA7343.svg)](https://swift.org)
[![macOS 14+](https://img.shields.io/badge/macOS-14+-000000.svg)](https://developer.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> I'm not your buddy, guy.

A modern Swift CLI for querying macOS calendar events. Built with EventKit as a replacement for the now-unmaintained icalBuddy.

Supports text and JSON output, ANSI colors, meeting detection (Zoom, Google Meet, Teams, WebEx), and TOML configuration.

Requires macOS 14 (Sonoma) or later.

## Install

### Homebrew

```
brew install itspriddle/brews/ical-guy
```

### From source

```
git clone https://github.com/itspriddle/ical-guy.git
cd ical-guy
make install
```

### From GitHub release

Download the universal binary from the [releases page](https://github.com/itspriddle/ical-guy/releases), extract, and move to your PATH:

```
tar -xzf ical-guy-v0.3.1-macos-universal.tar.gz
mv ical-guy /usr/local/bin/
```

## Usage

On first run, macOS will prompt for calendar access. If denied, grant it in **System Settings > Privacy & Security > Calendars**.

### Output format

Output format is auto-detected: **text** when stdout is a terminal, **JSON** when piped. Override with `--format`:

```sh
# Force JSON output to terminal
ical-guy events --format json

# Force text output when piping
ical-guy events --format text | less -R
```

Colors are enabled by default and adapt to terminal capabilities (truecolor, 256-color, 16-color). Disable with `--no-color` or by setting the `NO_COLOR` environment variable.

### List calendars

```
$ ical-guy calendars
Home (calDAV, iCloud)
US Holidays (subscription, Subscribed Calendars)
```

### Query events

```
$ ical-guy events
```

With no options, returns today's events:

```
Sunday, Feb 15, 2026
  11:00 AM - 12:00 PM  Galentine's Brunch  [Family]
  2:00 PM - 3:00 PM  Team Standup  [Work]
    Meeting: https://meet.google.com/abc-defg-hij
    Attendees:
      - Alice Smith <alice@example.com> (accepted)
      - Bob Jones <bob@example.com> (you)
    Recurs: Every weekday
```

### Events options

```
$ ical-guy events --help
OPTIONS:
  --format <format>       Output format: json or text (auto-detects based on TTY).
  --no-color              Disable colored output.
  --from <from>           Start date (ISO 8601, 'today', 'tomorrow', 'yesterday', 'today+N').
  --to <to>               End date (same formats as --from).
  --include-calendars     Only include these calendars (comma-separated titles).
  --exclude-calendars     Exclude these calendars (comma-separated titles).
  --exclude-all-day       Exclude all-day events.
  --limit <limit>         Maximum number of events to output.
```

### Meetings

The `meeting` command group provides quick access to meetings with detected video call URLs:

```sh
# Show current meeting
ical-guy meeting now

# Show next upcoming meeting
ical-guy meeting next

# Open current meeting URL in browser
ical-guy meeting open

# Open next meeting URL in browser
ical-guy meeting open --next

# List today's meetings (events with video call URLs)
ical-guy meeting list
```

Meeting subcommands support `--include-calendars` and `--exclude-calendars` for filtering, and `--format`/`--no-color` for output control (except `meeting open`).

### Week number

The `week` command prints the Calendar.app week number for a given date:

```sh
# Current week number (zero-padded)
$ ical-guy week
08

# Week number for a specific date
$ ical-guy week 2026-03-01

# Offset by weeks
$ ical-guy week --next 2
$ ical-guy week --prev 1

# Start/end dates of the week (Sunday and Saturday)
$ ical-guy week --start-date
$ ical-guy week --end-date

# Unpadded week number
$ ical-guy week --no-pad

# Full JSON output
$ ical-guy week --format json
{
  "endDate" : "2026-02-21",
  "startDate" : "2026-02-15",
  "week" : 8,
  "year" : 2026
}
```

### Examples

```sh
# Today's events (default)
ical-guy events

# This week
ical-guy events --from today --to today+7

# Tomorrow, work calendar only, no all-day events
ical-guy events --from tomorrow --to tomorrow --include-calendars Work --exclude-all-day

# Specific date range
ical-guy events --from 2024-03-15 --to 2024-03-22

# JSON output piped to jq
ical-guy events --format json | jq '[.[] | select(.meetingUrl != null) | {title, meetingUrl}]'

# Next 5 events
ical-guy events --from today --to today+30 --limit 5

# Open current meeting in browser
ical-guy meeting open
```

### Meeting URL extraction

The `meetingUrl` field is automatically populated when a Google Meet, Zoom, Microsoft Teams, or WebEx URL is found in an event's `url`, `location`, or `notes` fields (checked in that priority order). If no meeting URL is detected, the field is `null`.

### Date formats

| Format | Example | Description |
|---|---|---|
| `today` | `--from today` | Start of today |
| `tomorrow` | `--from tomorrow` | Start of tomorrow |
| `yesterday` | `--from yesterday` | Start of yesterday |
| `today+N` | `--to today+7` | N days from today |
| `today-N` | `--from today-3` | N days before today |
| `now` | `--from now` | Current date/time |
| ISO 8601 | `--from 2024-03-15` | Specific date |

### JSON output

When using `--format json` (or piping), events include rich structured data:

```json
[
  {
    "id": "E3A4B5C6-...",
    "title": "Team Standup",
    "startDate": "2024-03-15T14:00:00Z",
    "endDate": "2024-03-15T14:30:00Z",
    "isAllDay": false,
    "location": "Conference Room B",
    "notes": "Weekly sync",
    "url": null,
    "meetingUrl": "https://meet.google.com/abc-defg-hij",
    "calendar": {
      "id": "A1B2C3D4-...",
      "title": "Work",
      "type": "calDAV",
      "source": "iCloud",
      "color": "#1BADF8"
    },
    "attendees": [
      {
        "name": "Alice Smith",
        "email": "alice@example.com",
        "status": "accepted",
        "role": "required",
        "isCurrentUser": false
      }
    ],
    "organizer": {
      "name": "Bob Jones",
      "email": "bob@example.com"
    },
    "recurrence": {
      "isRecurring": true,
      "description": "Every weekday"
    },
    "status": "confirmed",
    "availability": "busy",
    "timeZone": "America/New_York",
    "creationDate": "2024-01-15T10:00:00Z",
    "lastModifiedDate": "2024-03-10T08:30:00Z"
  }
]
```

## Configuration

ical-guy supports an optional TOML config file at `~/.config/ical-guy/config.toml` (or `$XDG_CONFIG_HOME/ical-guy/config.toml`). CLI flags always take precedence over config values.

```toml
[defaults]
format = "text"                          # "text" or "json"
exclude-all-day = false
include-calendars = ["Work", "Personal"]
exclude-calendars = ["US Holidays"]

[text]
show-calendar = true
show-location = true
show-attendees = true
show-meeting-url = true
show-notes = false
```

## Development

Requires Swift 6.0+ and Xcode (for running tests).

```
make help

  build        Build debug binary
  release      Build release binary
  universal    Build universal (arm64 + x86_64) release binary
  test         Run tests
  clean        Remove build artifacts
  install      Install to PREFIX (default: /usr/local)
  uninstall    Remove installed binary
  deps         Install dependencies via Homebrew
  lint         Run SwiftLint
  format       Run swift-format
```

## License

MIT
