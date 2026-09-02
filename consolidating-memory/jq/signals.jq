# signals.jq — the user's own words from Claude Code transcripts.
# Read with `jq -R`, so that each input is one raw line of a JSONL file
# and a line that is not JSON (the truncated tail of a live session) is
# skipped instead of stopping the run. Argument: $since, an ISO-8601
# timestamp; older utterances are dropped. Output: one tab-separated
# line per utterance — timestamp, project, session, text — with the
# newlines inside the text folded to " ¶ ".

def authored:
  .type == "user"
  and ((.isMeta // false) | not)
  and ((.isSidechain // false) | not);

# The text of a string-shaped message, or the text blocks of an
# array-shaped one. A tool result is not something the user said.
def spoken:
  .message.content
  | if type == "string" then .
    elif type == "array" then [ .[] | select(.type == "text") | .text ] | join("\n")
    else "" end;

# Records that Claude Code files under the user's name but that did not
# come from the user's hands: slash-command echoes, task notifications,
# system reminders, local-command output, interruption markers, and
# compaction summaries. Every wrapper opens with an angle bracket, so a
# genuine message that opens with one is dropped too; that is the
# trade-off, and it is rare.
def machine_made:
  startswith("<")
  or startswith("[Request interrupted")
  or startswith("This session is being continued from a previous conversation");

# The milliseconds of a timestamp add nothing to a reader.
def to_the_second: .[0:19] + "Z";

# The first block of a session id is enough to tell sessions apart.
def session_prefix: .[0:8];

def project_name: (.cwd // "?") | split("/") | last;

def folded: gsub("\r?\n"; " ¶ ");

def trimmed: gsub("^\\s+|\\s+$"; "");

fromjson? // empty
| select(authored)
| select((.timestamp // "") >= $since)
| (spoken | trimmed) as $text
| select(($text | length) > 0 and ($text | machine_made | not))
| [ (.timestamp | to_the_second),
    project_name,
    ((.sessionId // "?") | session_prefix),
    ($text | folded) ]
| @tsv
