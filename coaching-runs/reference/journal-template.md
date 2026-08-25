# The Journal Template

One file per run day. The front matter is the machine-read part; the
contract for it lives in `reference/plan-contract.md`. Everything
below the front matter is the narrative. This example is synthetic.

```markdown
---
date: 2030-01-16
day: W2D2
workout: w2-thu
activity: 10000009
distanceKm: 7.31
durationMin: 47.5
backfilled: false
carry:
  - "Note: legs heavy; gate Saturday on feel"
---

# W2D2 — Easy 7km Z2

## Verdict

Clean easy run. The prescription held.

## Structure

47:30 total against the 45-50min window. No structured steps.

## Zones

Average HR 138, max 149; the whole run sat inside the live Z2 band.

## Drift and weather

Pace level through the second half at level HR. Dew point 21C,
pre-dawn class.

## Body and perception

7.4h sleep, HRV in band, RPE 30 against feel 80. Caffeine taken.

## Other activities

None.

## Rulings raised

None.
```

Rules for the body:

- Keep every heading, even when its section says "None." — an absent
  heading reads as an unexamined lead.
- State again, under the front matter `carry` key, every carry from
  the last entry that stays live. An unstated carry dies.
- Facts the athlete corrected go in corrected form only. Do not keep
  the wrong first version in the entry.
