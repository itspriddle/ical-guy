# ical-guy

[![CI](https://github.com/itspriddle/ical-guy/actions/workflows/ci.yml/badge.svg)](https://github.com/itspriddle/ical-guy/actions/workflows/ci.yml)
[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-FA7343.svg)](https://swift.org)
[![macOS 14+](https://img.shields.io/badge/macOS-14+-000000.svg)](https://developer.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> I'm not your buddy, guy.

A modern Swift CLI for querying macOS calendar events and reminders. Built with EventKit as a replacement for the now-unmaintained icalBuddy.

Supports text and JSON output, ANSI colors, meeting detection (Zoom, Google Meet, Teams, WebEx), reminders, and TOML configuration.

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
tar -xzf ical-guy-v0.10.0-macos-universal.tar.gz
mv ical-guy /usr/local/bin/
```

## Usage

On first run, macOS will prompt for calendar access. Grant it in **System Settings > Privacy & Security > Calendars**. Reminder commands will separately prompt for reminders access (**Privacy & Security > Reminders**).

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
  --format <format>           Output format: json or text (auto-detects based on TTY).
  --no-color                  Disable colored output.
  --group-by <mode>           Group output: none, date, or calendar.
  --show-empty-dates          Show dates with no events (implies --group-by date).
  --from <from>               Start date (ISO 8601, 'today', 'tomorrow', 'yesterday', 'today+N', or natural language).
  --to <to>                   End date (same formats as --from).
  --include-calendars         Only include these calendars (comma-separated titles).
  --exclude-calendars         Exclude these calendars (comma-separated titles).
  --include-cal-types         Only include these calendar types (comma-separated).
  --exclude-cal-types         Exclude these calendar types (comma-separated).
  --exclude-all-day           Exclude all-day events.
  --limit <limit>             Maximum number of events to output.
  --template <path>           Path to a .mustache template file for event rendering.
  --time-format <pattern>     Time format string (ICU pattern, e.g. "HH:mm" for 24-hour).
  --date-format <pattern>     Date format string (ICU pattern, e.g. "yyyy-MM-dd").
  --show-uid                  Show event UIDs in text output.
  --bullet <string>           Bullet prefix for each event (e.g. "→ ").
  --separator <string>        Separator between events (e.g. "---").
  --indent <string>           Indentation for detail lines (default: 4 spaces).
  --truncate-notes <n>        Truncate notes to N characters (0 = no limit).
  --truncate-location <n>     Truncate location to N characters (0 = no limit).
```

### Grouping

Events can be grouped by date or calendar using `--group-by`:

```sh
# Group by date (auto-activates for multi-day ranges)
ical-guy events --from today --to today+3

# Explicitly group by calendar
ical-guy events --from today --to today+7 --group-by calendar

# Show empty dates (implies --group-by date)
ical-guy events --from today --to today+7 --show-empty-dates

# Flat list with no grouping
ical-guy events --group-by none
```

Grouping auto-detection: multi-day ranges default to `--group-by date`, single-day ranges default to `--group-by none`. The `--show-empty-dates` flag implies `--group-by date`.

Reminders can also be grouped by list:

```sh
ical-guy reminders list --group-by calendar
```

### Calendar type filtering

Filter events by calendar type using `--include-cal-types` / `--exclude-cal-types`. Valid types: `local`, `calDAV`, `exchange`, `subscription`, `birthday`, `icloud`.

```sh
# Only show calDAV calendar events
ical-guy events --include-cal-types calDAV

# Exclude birthday and subscription calendars
ical-guy events --exclude-cal-types birthday,subscription

# Only iCloud-sourced calendars (calDAV calendars with iCloud source)
ical-guy events --include-cal-types icloud
```

The `icloud` type is a virtual alias that matches calDAV calendars with an iCloud source. Type matching is case-insensitive.

These flags are also available on `conflicts` and `free` commands and can be set in the config file.

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

### Conflicts

The `conflicts` command detects double-booked events in a date range:

```sh
# Check today for conflicts
ical-guy conflicts

# Check the next week
ical-guy conflicts --from today --to today+7

# Include all-day events in conflict detection
ical-guy conflicts --include-all-day

# Filter by calendar
ical-guy conflicts --include-calendars Work
```

Text output groups conflicts by day:

```
Monday, Feb 16, 2026
  CONFLICT (2 events, 10:00 AM - 11:30 AM)
    10:00 AM - 11:00 AM  Team Standup  [Work]
    10:30 AM - 11:30 AM  1:1 with Alice  [Work]

Found 1 conflict.
```

Events are automatically excluded from conflict detection if they are canceled, marked as "free" availability, or if you declined the invitation. All-day events are excluded by default (opt in with `--include-all-day`).

### Free time

The `free` command finds open time slots within working hours for deep work planning:

```sh
# Today's free time
ical-guy free

# Free time for the next 5 days
ical-guy free --from today --to today+5

# Free time from now (clips today to remaining time)
ical-guy free --from now

# Custom working hours and minimum slot duration
ical-guy free --work-start 08:00 --work-end 18:00 --min-duration 60

# Filter by calendar
ical-guy free --exclude-calendars "US Holidays"
```

Text output shows free slots with duration tiers:

```
Monday, Feb 16, 2026  (3h 30m free)
  9:00 AM - 10:00 AM  1h  [focus]
  11:30 AM - 2:00 PM  2h 30m  [deep work]

Summary: 3h 30m free across 1 day
Working hours: 9:00 AM - 5:00 PM, minimum slot: 30 minutes
```

Duration tiers: **deep work** (2h+), **focus** (1-2h), **short** (30-60m), **brief** (<30m). The same scheduling filters as `conflicts` are applied (canceled, free-availability, and declined events are excluded).

Defaults can be configured in the TOML config file (see Configuration).

### Birthdays

The `birthdays` command lists upcoming birthdays from the Contacts birthday calendar:

```sh
# Upcoming birthdays (next 30 days)
ical-guy birthdays

# Birthdays in a specific range
ical-guy birthdays --from today --to today+90

# Limit results
ical-guy birthdays --limit 5

# JSON output
ical-guy birthdays --format json
```

Text output groups birthdays by date:

```
Monday, Feb 16, 2026
  John Smith
  Jane Doe

Thursday, Feb 19, 2026
  Bob Jones
```

### Reminders

The `reminders` command group provides read-only access to macOS Reminders:

```sh
# List incomplete reminders (default)
ical-guy reminders

# List completed reminders
ical-guy reminders list --completed

# List all reminders (completed and incomplete)
ical-guy reminders list --all

# Filter by due date range
ical-guy reminders list --from today --to today+7

# Filter by reminder list
ical-guy reminders list --include-lists "Work,Shopping"
ical-guy reminders list --exclude-lists "Birthdays"

# Sort and limit
ical-guy reminders list --sort-by priority --limit 10

# List available reminder lists
ical-guy reminders lists
```

Text output shows a checkbox, title, list name, due date, and priority:

```
[ ] Buy groceries  [Shopping]  due: Feb 20, 2026  !high
[ ] Call dentist  [Personal]  due: Feb 22, 2026
[x] Send report  [Work]
```

Reminder subcommands support `--format`/`--no-color` for output control.

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

# Upcoming birthdays in the next 90 days
ical-guy birthdays --from today --to today+90

# High priority reminders due this week
ical-guy reminders list --from today --to today+7 --sort-by priority

# All reminders as JSON piped to jq
ical-guy reminders list --all --format json | jq '[.[] | select(.isCompleted == false)]'

# Check for conflicts this week
ical-guy conflicts --from today --to today+7

# Find free time for deep work today
ical-guy free --from now --min-duration 60

# Free time for the week as JSON
ical-guy free --from today --to today+5 --format json

# This week's events grouped by calendar
ical-guy events --from today --to today+7 --group-by calendar

# Show empty dates in a range
ical-guy events --from today --to today+7 --show-empty-dates

# Reminders grouped by list
ical-guy reminders list --group-by calendar
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
| Natural language | `--from "june 10 at 6pm"` | English date phrases (e.g. "next friday", "march 1, 2026") |

### JSON output

When using `--format json` (or piping), events include rich structured data. The JSON structure depends on the `--group-by` mode:

**Flat (default, `--group-by none`):** A JSON array of event objects.

**Grouped by date (`--group-by date`):** An array of date group objects:

```json
[
  {
    "date": "2024-03-15",
    "events": [...]
  }
]
```

**Grouped by calendar (`--group-by calendar`):** An array of calendar group objects:

```json
[
  {
    "calendar": { "id": "...", "title": "Work", ... },
    "events": [...]
  }
]
```

Each event object contains:

```json
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
```

Reminders with `--group-by calendar` produce an array of list group objects:

```json
[
  {
    "list": { "id": "...", "title": "Shopping", ... },
    "reminders": [...]
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
include-cal-types = ["calDAV"]           # filter by calendar type
exclude-cal-types = ["subscription"]
group-by = "date"                        # "none", "date", or "calendar"
show-empty-dates = true

[text]
show-calendar = true
show-location = true
show-attendees = true
show-meeting-url = true
show-notes = false
show-uid = false

[free]
min-duration = 30                        # Minimum free slot in minutes
work-start = "09:00"                     # Working hours start (HH:MM)
work-end = "17:00"                       # Working hours end (HH:MM)

[templates]
time-format = "HH:mm"                   # ICU time format (default: "h:mm a")
date-format = "yyyy-MM-dd"              # ICU date format (default: "EEEE, MMM d, yyyy")
event = "{{startTime}} - {{title}}"     # Inline Mustache template for events
event-file = "my-template.mustache"     # External template file (overrides inline)
date-header = "{{#bold}}=== {{formattedDate}} ==={{/bold}}"
calendar-header = "{{#calendarColor}}{{title}}{{/calendarColor}}"
bullet = "→ "                           # Bullet prefix for each event
indent = "  "                           # Indentation for detail lines
separator = "---"                       # Separator between events
truncate-notes = 80                     # Truncate notes to N characters
truncate-location = 40                  # Truncate location to N characters
```

Template files are loaded from `~/.config/ical-guy/templates/` (relative paths) or from absolute paths. CLI `--template` flag takes precedence over `event-file`, which takes precedence over `event` inline.

### Templates

Text output uses [Mustache](https://mustache.github.io/) templates. Customize event rendering with inline templates in `config.toml`, external `.mustache` files, or the `--template` CLI flag.

Available template variables:

| Variable | Description |
|---|---|
| `{{title}}` | Event title |
| `{{startTime}}` / `{{endTime}}` | Formatted start/end time |
| `{{startDate}}` / `{{endDate}}` | Formatted start/end date |
| `{{relativeStart}}` / `{{relativeEnd}}` | Relative time (e.g. "in 30 minutes") |
| `{{location}}` | Event location |
| `{{notes}}` | Event notes |
| `{{meetingUrl}}` | Detected meeting URL |
| `{{status}}` | Event status (e.g. "confirmed") |
| `{{availability}}` | Availability (e.g. "busy") |
| `{{id}}` | Event UID |
| `{{calendar.title}}` | Calendar name |
| `{{calendar.color}}` | Calendar hex color |
| `{{organizer.name}}` / `{{organizer.email}}` | Organizer info |
| `{{recurrence.description}}` | Recurrence rule |

Boolean sections for conditional rendering:

| Section | Description |
|---|---|
| `{{#isAllDay}}...{{/isAllDay}}` | All-day events |
| `{{#isRecurring}}...{{/isRecurring}}` | Recurring events |
| `{{#hasLocation}}...{{/hasLocation}}` | Has location |
| `{{#hasMeetingUrl}}...{{/hasMeetingUrl}}` | Has meeting URL |
| `{{#hasAttendees}}...{{/hasAttendees}}` | Has attendees |
| `{{#showCalendar}}...{{/showCalendar}}` | Display toggle (config-controlled) |

ANSI formatting lambdas (disabled with `--no-color`):

| Lambda | Description |
|---|---|
| `{{#bold}}text{{/bold}}` | Bold text |
| `{{#dim}}text{{/dim}}` | Dimmed text |
| `{{#calendarColor}}text{{/calendarColor}}` | Calendar's color |

Iterate attendees with `{{#attendees}}...{{/attendees}}`, using `{{name}}`, `{{email}}`, `{{status}}`, and `{{{displayString}}}` inside the loop.

Example templates:

```mustache
{{! Minimal one-line }}
{{startTime}} {{title}}

{{! Detailed with relative time }}
{{#bold}}{{title}}{{/bold}} — {{relativeStart}}
{{#hasLocation}}  @ {{location}}{{/hasLocation}}
```

See `man ical-guy` for the full template reference.

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
