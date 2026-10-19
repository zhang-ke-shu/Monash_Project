# FIT5202 A1 Interview Quick Sheet

## 30-second story

> I processed 72.9 million parking rows and 10.96 million traffic rows in PySpark with explicit schemas, four local cores and the Melbourne timezone. I preserved raw values for validation, found 408 negative-duration records, and excluded them only from duration metrics. I used left broadcast joins for the 38-row area and 126-row street lookups, then aggregated parking and traffic into matched ten-minute blocks. My monthly-report baseline scanned the 8.6 GiB parking input twice. The optimised plan scanned it once and derived the monthly benchmark with a window, producing the same 120 rows while reducing runtime from 403.00 to 195.50 seconds.

## Numbers

- Parking: **72,912,582** rows; traffic: **10,956,114** rows.
- **69** parking input partitions; most **128.1 MiB**; final residual **69.1 MiB / 580,174 rows**.
- Negative duration: **408**; minimum **-493,288.88 min**.
- Device **17595** / Bay **6519**: **95** negative-duration rows.
- Lookup sizes: area **38**, street **126**; unmatched records **0 / 0**.
- Matched ten-minute blocks: **577,947**.
- Mean parking / traffic: **24.50 / 1,094.76**; both above: **128,312 (22.20%)**.
- Monthly report: **24 months / 120 rows**; DF vs SQL `exceptAll`: **0 / 0**.
- Runtime: **403.00 → 195.50 s**; **51.49% reduction; 2.06× speed-up**.

## Three reasoning chains

### Cleaning

raw string → preserve raw column → safe parse/cast → count non-null raw becoming null → keep the row globally → exclude only when the relevant metric needs the invalid field.

### Joins and shuffle

- Lookup enrichment: **left** keeps all parking facts; **broadcast** tiny dimensions; no large fact-table shuffle.
- Parking–traffic: aggregate each source to `(AreaId, BlockStart)` first; **inner** keeps matched comparison blocks; both large branches need `Exchange` and sort-merge join.

### Optimisation

baseline = two full scans + two aggregates + month join → optimised = one full scan + one area-month aggregate + `sum(counts) over Month` → same weighted benchmark, no second scan/join.

## Boundary answers

- Peak: weekdays `2..6`; `[07:00, 09:00)` and `[16:00, 18:30)`.
- `COUNT(InViolation)` ignores nulls; `COUNT(*)` does not.
- `local[4]` = four concurrent tasks, not four partitions.
- `cache()` is lazy; an action materialises it.
- `toPandas()` was used only after aggregation to **38** or **24** rows.
- `row_number()` plus `AreaId` tie-break gives exactly five rows per month.
- Monthly benchmark = `sum violations / sum valid denominators`; never average area rates.

## Four danger points

1. **Spark UI caption mismatch:** admit that captions retained earlier ephemeral Job/Stage IDs after screenshots were refreshed. Point to stable job descriptions and metrics. Do not argue.
2. **Timing limitation:** Spark cache was cleared, but OS cache/JVM warm-up and one-run variability remain. Plan evidence supports the result.
3. **Longest stay:** some extreme means have very small samples; propose minimum count, median or outlier validation.
4. **Midnight outlier:** possible timestamp/default/batch behaviour; investigate exact minutes, areas and dates before claiming a cause.

## Physical plan in one breath

> Scan and filter the required columns, broadcast the tiny lookup, partially aggregate, exchange by the grouping keys, complete the aggregate, join or window on Month, rank the top five, and finally repartition and sort for ordered output. AQE coalesces small shuffle partitions using runtime statistics.

## If asked to execute

> Would you like me to rerun this specific action, or the complete lineage from the raw input? The complete lineage scans the 8.6 GiB parking file, so I can start it and explain the Spark UI while it runs.

Do not Run All. Keep notebook, Spark UI Jobs and this sheet open. Join 5–10 minutes early.
