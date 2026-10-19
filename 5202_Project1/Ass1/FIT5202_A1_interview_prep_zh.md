# FIT5202 Assignment 1 Interview Preparation

## 1. 你的核心策略

你的场次是本周五（按当前日期即 2026-10-02），而且处在整体安排的中段。老师已经明确说后面的面试会逐渐增加技术严格度，所以准备重点应该是：

1. 不只是会说“我用了什么”，还要能解释“为什么这样做、Spark 实际做了什么、有什么局限”。
2. Part 3 优化是最可能被深入追问的部分，因为它同时覆盖正确性、physical plan、Spark UI、shuffle 和性能评价。
3. 老师会主导演示；你不需要做完整 presentation，但必须能在任何一个 section 被点到时迅速定位并解释。
4. 回答时先给结论，再给一条代码证据和一条 Spark UI/数值证据。每题控制在 20–45 秒。

---

## 2. 45 秒英文总览（必须背熟逻辑，不要机械背字句）

> My notebook analyses about 72.9 million parking records and 10.96 million traffic records using PySpark in local mode with four cores. I used explicit schemas and the Australia/Melbourne timezone, preserved the raw values for validation, and safely parsed timestamps and DeviceId. I found 408 negative-duration records, which I excluded only from duration-based metrics while retaining them for analyses where their arrival, location and violation fields were still valid. I enriched the parking fact data with small area and street lookup tables using left broadcast joins, and combined aggregated parking and traffic data using matched ten-minute blocks. For the monthly report, my baseline scanned the large parking data twice. I replaced the second scan and the month join with a monthly window over the area-level aggregates. The optimised query returned the same 120 rows and reduced the measured runtime from 403.00 to 195.50 seconds.

如果被打断，不要慌；老师通常只是要进入具体问题。

---

## 3. 10–12 分钟演示导航

这不是固定演讲稿，而是老师让你“briefly walk me through your work”时的备用路线。

| 时间 | 展示位置 | 只讲什么 |
|---|---|---|
| 0:00–0:45 | Notebook 顶部与 `In [1]` | 数据规模、`local[4]`、显式 schema、时区 |
| 0:45–2:00 | 1.2，`In [17]`–`In [36]` | 安全解析、保留 raw 列、408 个负时长、按查询目的处理无效记录 |
| 2:00–2:45 | 1.3，`In [37]` 与 `In [97]` | 69 partitions；大部分约 128 MiB；`local[4]` 只控制并发 |
| 2:45–4:30 | 2.2–2.5 | left broadcast lookup join；十分钟 block；inner join matched blocks；为什么有 shuffle |
| 4:30–5:30 | 2.6 两张图 | 结论、限制、不能声称因果 |
| 5:30–9:30 | 3.1–3.3 | 两种 API 等价；baseline 两次扫描；优化为一次聚合加 window；120 行完全一致；403.00 → 195.50 秒 |
| 9:30–12:00 | 老师指定内容 | 现场执行、physical plan、Spark UI 或追问 |

建议预先在 notebook 中记住这些 execution labels：

- Session/schema：`In [1]`–`In [10]`
- 清洗与验证：`In [11]`–`In [36]`
- Partition：`In [37]`、`In [97]`
- Peak 定义：`In [39]`–`In [41]`
- Lookup joins：`In [42]`–`In [46]`
- Area/bay metrics：`In [47]`–`In [55]`
- Parking–traffic：`In [56]`–`In [66]`
- Plots：`In [67]`–`In [73]`
- Monthly report：`In [74]`–`In [85]`
- Baseline：`In [86]`–`In [88]`
- Optimisation：`In [89]`–`In [95]`

---

## 4. 必须记住的数字

| 项目 | 你的结果 | 面试中的意义 |
|---|---:|---|
| Parking rows | 72,912,582 | 大事实表 |
| Traffic rows | 10,956,114 | 第二个大数据源 |
| Area lookup rows | 38 | 适合 broadcast |
| Street lookup rows | 126 | 适合 broadcast |
| Parking input partitions | 69 | 多数约 128.1 MiB；最后一个约 69.1 MiB |
| Negative-duration rows | 408（约 0.00056%） | 只从 duration 指标排除 |
| 最小 duration | -493,288.88 minutes | 不可能只由 DST 解释 |
| Device 17595 / Bay 6519 | 95 个负时长（约 23.28%） | 可能为系统性 sensor/event matching 问题 |
| Unmatched area/street | 0 / 0 | 仍选择 left join，以保留并检测不匹配事实记录 |
| Busiest area | Docklands，9,434,638 sessions | 但高 activity 不必然高 violation rate |
| Highest-turnover bay | Bay 1063，354,011 sessions | 平均 2.26 分钟，violation 0.01% |
| Longest-average-stay bay | Bay 2469，14,885.57 minutes | 只有 33 sessions，需强调样本量 |
| Matched area-time blocks | 577,947 | parking/traffic 同时存在的 blocks |
| Average parking / traffic | 24.50 / 1,094.76 | “above average”的阈值 |
| Both above average | 128,312（约 22.20%） | 不能推广到 unmatched blocks |
| Plot 1 correlation | -0.358 | 基于 38 个 area aggregates、且 x 取 log10 |
| Monthly report | 24 months，120 rows | 每月 5 行 |
| DF vs SQL mismatch | 0 / 0 | `exceptAll()` 两个方向 |
| Baseline comparison runtime | 403.00 s | 两条 full-data 分支 |
| Optimised runtime | 195.50 s | 一条 full scan + aggregate + windows |
| Improvement | 节省 207.50 s；51.49%；2.06× | 与物理计划证据一致 |

---

## 5. 高频追问与英文回答要点

### Q1. Why did you define explicit schemas instead of using `inferSchema`?

> Explicit schemas make the types deterministic and avoid a separate inference pass. They also make validation intentional. For example, I first loaded DeviceId as a string so that I could preserve the original value and detect conversion failures when safely casting it to integer.

补充点：schema inference 不是数据清洗；显式 schema 也可能把不合法的 typed value 变成 null，所以你保留 raw 字符串再做 validation。

### Q2. Why did you use `try_to_timestamp` and `try_cast`?

> They return null for invalid input instead of failing the entire Spark job. Because I retained the raw columns, I could distinguish a genuinely missing value from a non-null value that failed parsing or conversion.

### Q3. What is the difference between a missing departure and a parsing failure?

> A missing departure has a null raw value. A parsing failure has a non-null raw string but a null parsed timestamp. My validation summary counts these separately. In this dataset both counts were zero, but the logic still handles them.

### Q4. Why did you set `Australia/Melbourne` explicitly?

> Timestamp parsing, extraction of local hours and dates, and ten-minute block construction must use Melbourne local time. The explicit session timezone makes those operations reproducible and is especially important around daylight-saving transitions.

### Q5. How did you handle the 408 negative durations?

> I retained the records in the cleaned parking DataFrame because fields such as arrival, area and violation could still be valid. I excluded null or negative durations only from duration-based calculations. This avoids deleting useful records globally because of one invalid field.

### Q6. Were the negative durations caused by daylight saving?

> Some records cluster on Melbourne daylight-saving transition dates, so DST may contribute to small timing anomalies. However, durations that are days or months negative cannot be explained by a one-hour clock change. The concentration on particular devices and bays suggests incorrect sensor-event matching is the more likely general cause.

### Q7. Why are there 69 partitions if Spark runs on four cores?

> The 69 input partitions come mainly from splitting the approximately 8.6 GiB CSV using the file partition size target, which is around 128 MiB in this configuration. `local[4]` controls how many tasks can execute concurrently; it does not set the number of input partitions.

更严格的补充：实际 file partition planning 还会受 `spark.sql.files.openCostInBytes`、文件数量、最小/最大 partition 建议以及记录边界影响。你的数据是一个可切分的大 CSV，所以 `maxPartitionBytes` 是主要解释。

### Q8. What is the relationship between a job, stage, task and partition?

> An action creates one or more Spark jobs. A shuffle boundary divides a job into stages. Within a stage, Spark normally launches one task per partition. A task processes one partition for that stage.

### Q9. Was the partition workload balanced?

> Broadly yes. Most partitions were around 128.1 MiB and roughly 1.04 to 1.10 million records, while the smaller final partition had 580,174 records and about 69.1 MiB. That looks like a residual file split rather than severe key skew.

### Q10. Why use left joins for area and street lookups?

> The parking data is the fact table, so a left join preserves every parking record. If a lookup is missing, the lookup columns become null and I can report the data-quality issue. An inner join would silently discard those records. The observed unmatched counts were both zero, but that result should be measured rather than assumed.

### Q11. Why broadcast the lookup tables?

> The area and street tables contain only 38 and 126 rows. Broadcasting sends a small copy to each executor, so Spark can avoid repartitioning the 72.9 million-row parking table for those joins.

### Q12. What would make broadcast inappropriate?

> If the lookup became too large for executor memory or exceeded the broadcast threshold, broadcasting could cause memory pressure or failure. A shuffle-based join would then be safer. The decision should be based on the physical size and plan, not only the row count.

### Q13. Explain the peak-hour boundary logic.

> I converted hour and minute to minutes since midnight. A row is peak only on Spark weekdays 2 through 6 and in `[420, 540)` or `[960, 1110)`. Therefore 07:00 and 16:00 are included, while 09:00 and 18:30 are excluded exactly as specified.

### Q14. Why is the violation-rate denominator not total sessions?

> The specification defines the denominator as sessions with a valid `InViolation` value in the same period. Null is unknown, not false, so including nulls in the denominator would bias the rate downward.

### Q15. Why can the off-peak daily average be higher than the peak daily average?

> Off-peak covers many more hours. The metrics are sessions per active day, not sessions per hour, so their magnitudes should not be interpreted as equal-duration rates. A fair intensity comparison would normalise by exposure time.

### Q16. What is weak about the longest-stay ranking?

> An extreme mean can be based on very few sessions. Bay 2467, for example, has only four sessions. A production analysis could require a minimum valid-session count, show confidence intervals, use the median, or winsorise implausible durations.

### Q17. How did you construct ten-minute blocks?

> I floored the minute to the nearest lower multiple of ten and constructed `BlockStart` from year, month, day, hour and that minute. Thus a time from 00 through 09 minutes maps to the block starting at minute 00, and similarly for the other five blocks in the hour.

### Q18. Why aggregate before joining parking and traffic?

> The required grain is one row per `AreaId` and `BlockStart`. Aggregating each source to that grain first reduces the amount of data entering the join and prevents a many-to-many join between raw sensor rows.

### Q19. Why use an inner join for parking and traffic?

> The question asks for comparison across matched area-time blocks, so each retained row must contain both measures. A full or left join would introduce null measures that cannot be compared directly. The limitation is that the conclusion applies only to matched blocks and may be affected by coverage bias.

### Q20. Why were `Exchange` operations required in Part 2.5?

> The aggregations require all records with the same `AreaId` and `BlockStart` to be co-located, and the sort-merge join requires both sides to be partitioned and ordered on the join keys. Spark therefore shuffled both aggregated branches. The small area lookup was broadcast, so that final enrichment did not need a large shuffle.

### Q21. Why did Spark use a sort-merge join rather than broadcasting one traffic branch?

> Both aggregated parking and traffic branches were still substantial, so neither was treated like the tiny lookup tables. A sort-merge join is appropriate for two large equi-join inputs after repartitioning by the keys. AQE may alter details at runtime, but the formatted plan and UI showed the shuffle-based join here.

### Q22. What did AQE do in your query?

> Adaptive Query Execution used runtime shuffle statistics to coalesce the post-shuffle work. Although the planned shuffle partition count was 200, the final join stage used five tasks. AQE reduces overhead from many tiny shuffle partitions; it does not remove the need to move records to the correct keys.

### Q23. When is `cache()` actually materialised?

> `cache()` is lazy. It marks the DataFrame for caching, but an action such as `first`, `count`, `show` or `collect` performs the computation and stores the partitions. I used the cached matched blocks for repeated summary calculations, then unpersisted before the final evidence query so the Spark UI showed the complete lineage.

### Q24. Why was `toPandas()` safe in the plots?

> I never collected the 72.9 million raw rows. I first aggregated in Spark to 38 area rows for Plot 1 and 24 hourly rows for Plot 2, and only then converted those small results to pandas for plotting.

### Q25. What does the `-0.358` correlation mean, and what does it not mean?

> It is a weak-to-moderate negative association between log10 total sessions and violation rate across 38 area-level aggregates. It does not prove causation, does not describe individual sessions, and may be confounded by enforcement, restrictions, location and time of day.

### Q26. How would you explain the midnight outlier?

> Midnight had unusually high average parking sessions relative to traffic. It may reflect timestamp defaults, batch recording behaviour or a distinct overnight parking pattern. I would not claim a cause without checking the distribution of exact arrival minutes, areas and dates contributing to the midnight block.

### Q27. Why did DataFrame API and SQL produce similar physical plans?

> Both are translated into Spark logical plans and optimised by Catalyst. Because the two implementations expressed the same computation over the same prepared input, Catalyst selected the same main strategies: broadcast lookup joins, hash aggregations, exchanges, a month join, windows and a final sort.

### Q28. Why use `exceptAll()` in both directions?

> `exceptAll` compares multisets and preserves duplicate counts. One direction detects rows present too many times in A; the other detects rows present too many times in B. Zero in both directions, together with compatible schemas, demonstrates data equivalence more strongly than comparing only row counts.

### Q29. Why `row_number()` instead of `rank()`?

> The requirement is exactly five areas per month, and I supplied a deterministic tie-break using `AreaId` ascending. `row_number()` therefore gives exactly one ordering position per row. `rank()` could return more than five rows when ties share a rank.

### Q30. Explain the baseline bottleneck from the physical plan.

> The baseline has two independent branches from the same large parking source: one computes area-month metrics and the other computes the monthly benchmark. Each branch scans and processes all 72,912,582 rows and then the two aggregates are joined on Month. The shuffle outputs were small, so repeated full-data parsing and processing—not shuffle volume—was the dominant cost.

### Q31. How does the optimisation preserve the benchmark mathematically?

> The monthly benchmark is the ratio of total monthly violations to total monthly valid-violation sessions. After computing each area’s numerator and denominator, I can sum those counts over a month-partitioned window and divide the sums. This is exactly equivalent to the global ratio. I do not average the area rates, because an unweighted average of rates would be incorrect when areas have different denominators.

### Q32. What exactly did the optimisation remove?

> It removed one full parking-data scan, one large aggregation branch, and the sort-merge join that recombined area metrics with the monthly benchmark. The optimised plan performs one scan and area-month aggregation, then computes monthly totals and rankings with windows over the much smaller aggregate.

### Q33. Why is `collect()` acceptable for timing the final report?

> The action materialises the complete lineage, which is required for fair timing, but the final result contains only 120 rows, so returning it to the driver is safe. Collecting the raw dataset would not be safe.

### Q34. Was the performance experiment perfectly controlled?

> I used the same Spark session, the same complete-result `collect()` action, unpersisted the result and cleared Spark caches before each run. However, a single comparison cannot eliminate OS file cache, JVM warm-up and normal runtime variability. I therefore treat the 51.49% result as measured evidence supported by the structural plan improvement, not as a universal benchmark. A stronger experiment would alternate the query order and report the median of several runs.

### Q35. Why should the optimisation still be retained?

> It returned the same 120 ordered rows with the same schema, and the physical plan shows a genuine reduction from two full scans to one. The measured runtime also fell from 403.00 to 195.50 seconds, which is directionally consistent with removing about half of the large-source processing.

---

## 6. 你提交内容中的高风险追问

### 风险 1：Spark UI 图注编号与截图可见编号不一致

提交 PDF 中有几处明显的“重跑后编号漂移”：

- Part 1 图注写 Job 44 / Stage 60，但截图可见的是后续 Job 81 / Stage 110。
- Part 2 图注写 Jobs 68–71 / Job 71，但截图列表和详情可见的是后续编号（如 Jobs 79–85、Job 81）。
- Part 3 baseline 图注讨论 Jobs 132–148、Stages 317/318，但部分截图列表可见的是后续 job/stage 编号。

如果老师指出，不要争辩编号。建议回答：

> You are right that some captions retained the IDs from an earlier run, while the embedded screenshots were refreshed after I reran the notebook, so Spark assigned new ephemeral job and stage IDs. That is a presentation inconsistency in my submission. The relevant jobs can still be identified by the required job descriptions and by their input and task metrics, but I should have updated the captions to match the final screenshots.

然后马上指向稳定证据：required job description、69 tasks、72,912,582 records、8.6 GiB、shuffle read/write。Job/Stage ID 每次运行会变，但错误图注仍要诚实承认。

### 风险 2：Part 3 计时只有一次主要对比

不要声称“优化一定永远快 51.49%”。正确说法是：这次相同 action、清 Spark cache 条件下测得 51.49%，物理计划也证明少了一次 full scan；但 OS cache、JIT 和波动没有完全控制。

### 风险 3：Plot 1 标签有重叠

老师若问图的可读性，可以承认高活动区域的标签较拥挤。改进可用 label adjustment、只标异常点、交互 tooltip 或单独表格。不要让版式问题影响你解释统计限制。

### 风险 4：极端 long-stay average

不要把 Bay 2469 或 Bay 2467 直接解释为真实长期停车行为。先说小样本、传感器异常和极端值风险，再说需要 median、最小样本门槛或合理上限验证。

### 风险 5：老师可能要求改一行代码

最可能的现场修改：

- 把 peak 的上界改错再让你修回 `< 540` / `< 1110`。
- 把 left join 改成 inner，问会丢什么。
- 去掉 `broadcast`，让你解释 plan 中的变化。
- 把 `row_number` 改成 `rank`，问结果行数为什么可能变化。
- 要求给 longest-stay 加 `ValidDurationSessions >= 30` 的过滤。
- 要求用 `exceptAll` 比较 baseline 与 optimised，而不只是 Python row-list equality。

练习时要能在 30 秒内指出应该改哪一个 cell，但正式面试中只在老师明确要求时修改或执行。

---

## 7. Physical plan 快速读法

被要求解释 plan 时，从下往上讲数据流：

1. `Scan csv/json`：读取实际需要的列；观察 pushed filters 和 read schema。
2. `Filter` / `Project`：清洗、timestamp parsing、选择列和派生字段。
3. `BroadcastExchange` + `BroadcastHashJoin`：小 lookup 被复制到每个执行端，大 parking 表不因 lookup join 被 shuffle。
4. `HashAggregate`：先 local partial aggregate，再经过 `Exchange` 做 global aggregate。
5. `Exchange`：数据按 group/join/window keys 重新分区，是网络/磁盘移动边界。
6. `Sort` + `SortMergeJoin`：两条较大分支按相同 keys 排序后合并。
7. `Window` / `WindowGroupLimit`：按 Month 计算 totals 或 top-5 ranking。
8. 最终 `Exchange` + `Sort`：保证全局按 Month 和 MonthlyRank 输出。
9. `AdaptiveSparkPlan`：AQE 在运行时根据真实统计调整 shuffle partition 等细节。

Baseline 一句话：

> Two scans and two aggregation branches are joined on Month before ranking.

Optimised 一句话：

> One scan produces area-month aggregates, and both the monthly benchmark and the top-five ranking are derived with windows over the small aggregate.

---

## 8. 现场执行准备

### 面试前 30 分钟

- 使用与提交时相同的 Docker/Jupyter/Spark 环境和同一份 notebook。
- 确认数据路径仍为 `/home/student/fit5202_2026_s2_dataset_v2/fit5202_2026_s2_dataset_v2`。
- 启动 notebook、Spark session 和 Spark UI；不要到进 breakout room 才启动容器。
- 打开三个页签：notebook、Spark UI Jobs、本文准备笔记；屏幕分享前关闭私人窗口和通知。
- 确认 notebook 中输出仍然可见；不要为了“干净”而清空输出。
- 电源接通，关闭自动休眠，测试麦克风、摄像头、屏幕分享和网络。
- 预留可用内存；关闭大型 IDE、游戏、同步软件和多余浏览器页签。

### 不要在 12 分钟里主动做的事

- 不要从头 Run All；你的 full-data query 单次就可能需要 3–7 分钟。
- 不要主动清 kernel、清全部输出或改提交文件。
- 不要为了证明会 Spark 而展开几十行 physical plan；只指出关键节点和证据。
- 不要背诵所有结果；回答时把数值与设计选择连接起来。

### 如果老师要求 live execution

先确认范围：

> Would you like me to rerun this specific action, or the complete lineage from the raw input?

然后说明预计时间，例如：

> This action scans the 8.6 GiB parking file, so in my submitted run it took about three to seven minutes depending on the branch. I can start it now and explain the plan while it runs.

不要以“太慢”为理由拒绝；开始执行，并在等待时解释 job description、stage/task 和 Spark UI。

---

## 9. 到周五的练习安排

### 周一：理解数据流

- 不看答案，用 2 分钟画出：raw files → schemas → cleaned DataFrames → time features → lookup joins → area/bay/traffic analysis → monthly report。
- 练习 Q1–Q12。

### 周二：Part 2

- 口头解释 peak boundaries、violation denominator、active day、10-minute block 和两种 join。
- 对每张图用 30 秒说清：问题、图型、结论、限制。
- 练习 Q13–Q26。

### 周三：Part 3

- 对着 physical plan 从 Scan 讲到 final Sort。
- 手写 monthly benchmark 的分子/分母，解释为什么是“sum counts then divide”，不是平均 area rates。
- 练习 Q27–Q35。

### 周四：三次 12 分钟模拟

1. 第一次只看 notebook，重点定位速度。
2. 第二次让朋友随机打断和追问“why”。
3. 第三次全流程屏幕分享、计时、包含一次小 cell 执行。

每次结束只记录三件事：哪题答得超过 45 秒、哪个数字记错、哪个 cell 找太久。

### 周五

- 提前 30 分钟启动环境，提前 5–10 分钟进 session。
- 最后只看第 4 节数字表、第 6 节风险和第 7 节 plan 快速读法，不再临时学新内容。

---

## 10. 最后自测（不看上文，用英文回答）

1. Why can a record be valid for Task 2.3 but invalid for the duration part of Task 2.4?
2. Why does `local[4]` not imply four input partitions?
3. Why is a left broadcast join appropriate for lookup enrichment?
4. Why does the parking–traffic join require shuffling even after aggregation?
5. What selection bias is introduced by the inner join in Task 2.5?
6. Why is `COUNT(InViolation)` different from `COUNT(*)`?
7. Why would averaging area violation rates give the wrong monthly benchmark?
8. What did each direction of `exceptAll()` test?
9. Which expensive operations disappeared from the optimised plan?
10. What evidence supports retaining the optimisation, and what limitation remains in the timing experiment?
11. If the teacher points out the Spark UI caption mismatch, how will you answer?
12. Why is the midnight point interesting but not enough to make a causal claim?

如果这 12 题都能在 30–40 秒内回答，且能立即定位相应 cell，你就已经具备比较稳的中段场次应对能力。
