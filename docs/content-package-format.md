# FidelLearn Content Package Format Specification

## 1. Package Structure
Offline educational packages are distributed as `.flpkg` (versioned ZIP archives or SQLite manifest bundles) containing metadata, questions, choices, explanations, and diagrams.

```text
package_g12_math_v1.0.flpkg (or json asset)
├── manifest.json                    # Package metadata, grade, stream, version, checksum
├── content.json                     # Structured subjects, units, topics, questions, choices, explanations
└── assets/                          # Optional embedded SVG or compressed WebP diagrams
    └── diagrams/
        └── math_g12_u1_q4.svg
```

---

## 2. Manifest Schema (`manifest.json`)
```json
{
  "package_id": "pkg_g12_math_nat_2026",
  "name_en": "Grade 12 Mathematics (Natural Science)",
  "name_am": "የ12ኛ ክፍል ሂሳብ (የተፈጥሮ ሳይንስ)",
  "grade": 12,
  "stream": "natural",
  "version": 1,
  "min_app_version": "1.0.0",
  "total_questions": 20,
  "size_bytes": 1048576,
  "publisher": "FidelLearn Original Demonstration",
  "license": "demo_evaluation",
  "attribution": "FidelLearn verified demonstration package",
  "published_at": "2026-08-21T00:00:00Z",
  "checksum_sha256": "abcdef..."
}
```

---

## 3. Publisher & Extreme Series Partnership Preparedness
Every package and question record supports metadata attributes:
- `publisher`: e.g. `"Extreme Series Books"` (enabled only with official license)
- `license_identifier`: e.g. `"EXTREME-2026-ETH-G12"`
- `attribution_text`: e.g. `"Verified solution powered by Extreme Series Books"`
- `source_book`: `"Extreme Mathematics Grade 12"`
- `source_page`: `142`
- `license_valid_until`: `"2027-12-31T23:59:59Z"`
- `allowed_platforms`: `["android", "windows", "web"]`

*Note: In the demonstration seed dataset, all items are strictly marked with `"FidelLearn original demonstration content"` and partner attribution flags are set to false.*
