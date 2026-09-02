---
name: widget-api-migration
description: The widget API moved to api.newplatform.io/v2 on 2030-01-12; SQLite serves local development, PostgreSQL stays in production
metadata:
  type: project
---

The widget API base URL is https://api.newplatform.io/v2 since
2030-01-12 (previously https://api.oldservice.com/v1).

**Why:** Jordan moved the API to the new domain on 2030-01-12 and chose
SQLite for local development on the same day. PostgreSQL stays in
production.

**How to apply:** Point new code at the v2 URL. Use the Result types
from [[neverthrow-documentation]] for the error paths.
