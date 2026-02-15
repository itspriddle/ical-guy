# ical-guy

A modern Swift CLI for querying macOS calendar events, outputting JSON. Built with EventKit and designed as a replacement for the now-unmaintained icalBuddy.

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
tar -xzf ical-guy-v0.1.0-macos-universal.tar.gz
mv ical-guy /usr/local/bin/
```

## Usage

On first run, macOS will prompt for calendar access. If denied, grant it in **System Settings > Privacy & Security > Calendars**.

### List calendars

```
$ ical-guy calendars
[
  {
    "color" : "#306793",
    "id" : "A9AEFD3D-...",
    "source" : "iCloud",
    "title" : "Home",
    "type" : "calDAV"
  },
  {
    "color" : "#CC73E1",
    "id" : "3F8D50DE-...",
    "source" : "Subscribed Calendars",
    "title" : "US Holidays",
    "type" : "subscription"
  }
]
```

### Query events

```
$ ical-guy events
```

With no options, returns today's events. Output is a JSON array:

```json
[
  {
    "id" : "E3A4B5C6-...",
    "title" : "Team Standup",
    "startDate" : "2024-03-15T14:00:00Z",
    "endDate" : "2024-03-15T14:30:00Z",
    "isAllDay" : false,
    "location" : "Conference Room B",
    "notes" : "Weekly sync",
    "url" : null,
    "calendar" : {
      "id" : "A1B2C3D4-...",
      "title" : "Work",
      "type" : "calDAV",
      "source" : "iCloud",
      "color" : "#1BADF8"
    },
    "attendees" : ["Alice Smith", "Bob Jones"],
    "isRecurring" : true,
    "status" : "confirmed"
  }
]
```

Output is pretty-printed when stdout is a TTY, compact when piped.

### Options

```
$ ical-guy events --help
USAGE: ical-guy events [--from <from>] [--to <to>] [--include-calendars <include-calendars>]
                       [--exclude-calendars <exclude-calendars>] [--exclude-all-day] [--limit <limit>]

OPTIONS:
  --from <from>           Start date (ISO 8601, 'today', 'tomorrow', 'yesterday', 'today+N').
  --to <to>               End date (same formats as --from).
  --include-calendars     Only include these calendars (comma-separated titles).
  --exclude-calendars     Exclude these calendars (comma-separated titles).
  --exclude-all-day       Exclude all-day events.
  --limit <limit>         Maximum number of events to output.
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

# Pipe to jq for further filtering
ical-guy events | jq '[.[] | select(.isRecurring == true)]'

# Next 5 events
ical-guy events --from today --to today+30 --limit 5
```

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
  lint         Run SwiftLint
  format       Run swift-format
```

## License

MIT
