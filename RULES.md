# RULES | 規則

## Leave Policy | 休假政策

### AnnualTotal (per year) | 年假總額（每年）

AnnualTotal(year) = AnnualDays(year) + CarryForwardFromLastYear + CompensatoryThisYear
年度總額(year) = 年度天數(year) + 上年度結轉 + 當年補償

- AnnualDays(year) / 年度天數
  - First year (pro‑rata): baseAnnualDays × daysEmployedInYear/365, capped to [0, baseAnnualDays]. / 第一年度（按比例）：baseAnnualDays × daysEmployedInYear/365，且介於 [0, baseAnnualDays]。
  - Subsequent years: min(maxAnnualDays, baseAnnualDays + seniorityYears × annualIncrement). / 其後年度：min(maxAnnualDays, baseAnnualDays + seniorityYears × annualIncrement)。
  - SeniorityYears = max(0, year − (hireYear + 1)). Example: join 2022 → 2023 seniority=0, 2024=1, 2025=2. / 資歷年數：max(0, year − (hireYear + 1))。例：2022 入職 → 2023 資歷=0、2024=1、2025=2。
- CarryForwardFromLastYear / 上年度結轉
  - Snapshot at year rollover; no expiry, unlimited carry-forward. / 年度切換時快照；不設到期，結轉不限年限。
- CompensatoryThisYear / 當年補償
  - Sum of admin-issued grants (decimal allowed, e.g., 2.5). / 管理員發放的補償總和（可含小數，如 2.5）。

Example (n=7.5, increment=+1/year, cap m=16.5) / 範例（n=7.5，每年+1，上限 m=16.5）：

- Join 01/Nov/2022: AnnualDays(2022) = 7.5 × 61/365 ≈ 1.25
- 2023: 7.5
- 2024: 8.5
- 2025: 9.5

### Annual Leave (HK EO Compliance) | 年假（香港僱傭條例）

- Taking rules: / 休假規則：
  - Annual leave should be taken consecutively; splitting is allowed upon employee request. No automated handling for cases such as entitlement > 10 days; these are reviewed case-by-case by Admin. / 年假以連續放取為原則；如員工要求可分拆。對於例如年假權益>10天等情況，系統不作自動處理，由管理員逐案判斷。
- Payment in lieu: / 以薪代假：
  - Case-by-case by Admin; the system does not enforce or compute automatic pay-in-lieu conversions. / 由管理員逐案處理；系統不自動強制或計算以薪代假。
- System validation: / 系統校驗：
  - Do not auto-enforce split or pay-in-lieu rules; optionally show advisory notes. / 不自動強制分拆或以薪代假規則；可選擇性顯示提示資訊。
  - Statutory floor: entitlement must not be lower than EO requirements by years of service (7→14 days ladder). / 法定底線：實得年假不得低於僱傭條例按年資規定之階梯（7→14 天）。

#### Statutory Annual Leave Ladder (EO) | 法定年假階梯（僱傭條例）

| Years of Service / 年資 | Statutory Days / 法定天數 |
| ---------------------- | ------------------------: |
| 1–2                   |                         7 |
| 3                      |                         8 |
| 4                      |                         9 |
| 5                      |                        10 |
| 6                      |                        11 |
| 7                      |                        12 |
| 8                      |                        13 |
| 9+                     |                        14 |

Note: Minimum statutory reference. / 附註：法定最低參考。

#### Admin-Configurable Contractual Leave Ladder | 管理員可設定合同年假階梯

Removed: Not applicable under current policy. / 已移除：依現行政策不再適用。

### Paid Sick Leave | 有薪病假

- Each employee has SickLeavePaidDays per year (e.g., 4.5). / 每位員工每年有 SickLeavePaidDays（例如 4.5）。
- Allocation order when Sick leave Approved: / 病假獲批後的扣減次序：
  - Deduct from SickPaid balance up to remaining paid entitlement. / 先由病假有薪餘額中扣減至上限。
  - Excess Sick days are deducted from AnnualTotal (treated as Annual leave usage). / 超出部分由年假總額中扣減（視作年假使用）。

### Negative Balance Leave (Overdrawn Leave) | 負結餘年假（透支年假）

- Employees may submit leave even if RemainingDays would go below zero, within caps. / 在上限內，員工可於餘額將為負時提出請假申請。
- Caps (configurable): per-type and per-year total. / 上限（可配置）：按類型及按年度總量。
- Any negative-balance approval requires Admin review; audit required. / 任何負結餘批准均需管理員複核並留有審計紀錄。

### Units | 單位

- Employee requests are whole-day only (no half-day). / 員工請假僅按整天計（不支援半天）。
- Admin compensatory grants can be decimal (e.g., 2.5). / 管理員補償天數可為小數（例如 2.5）。

## System Behavior | 系統行為

- Validation / 驗證
  - Frontend warns on potential negative; allow submit. / 前端對可能為負的餘額發出警示，仍允許提交。
  - Backend enforces caps at approval time. / 後端於審批時強制執行上限規則。
- Database / 數據庫
  - `tb_LeaveBalances.RemainingDays` may be negative. / `tb_LeaveBalances.RemainingDays` 可為負值。
  - Views use `tb_LeaveRequestDates` aggregates for ranges and counts. / 檢視以 `tb_LeaveRequestDates` 聚合計算區間與天數。
- Stored Procedures / 儲存過程
  - Submit: allow negative if within caps; log intent. / 提交：如在上限內允許負值並記錄意圖。
  - Approve: compute approved counts; enforce caps; write audit. / 審批：計算核准天數、強制上限並寫入審計。
- Configuration / 組態
  - Per-leave-type caps and annual total caps configurable. / 可配置各假類上限與年度總上限。

## Data Model Additions | 數據模型新增

- tb_Users (add) / 新增
  - HireDate DATE
  - SickLeavePaidDays DECIMAL(4,1) NOT NULL DEFAULT 4.5
- tb_CompensatoryGrants (new) / 新增
  - GrantID INT IDENTITY PK, UserID INT FK, Year INT, Days DECIMAL(5,2), Reason NVARCHAR(200), CreatedBy INT FK, CreatedDate DATETIME DEFAULT GETDATE()
- tb_YearOpeningBalances (new) / 新增
  - UserID INT FK, Year INT, AnnualCarryForward DECIMAL(5,1), SnapshotDate DATETIME, UNIQUE(UserID, Year)
- tb_LeaveTypeRules (optional) / 選用
  - LeaveTypeID INT PK, BaseDays DECIMAL(5,1), AnnualIncrement DECIMAL(4,1), MaxDays DECIMAL(5,1), ProRataFirstYear BIT, AllowDecimals BIT

### Holidays Source | 公眾假期來源

- Real-time Hong Kong public holidays are sourced from 1823 (HKSARG):
  - EN: `https://www.1823.gov.hk/common/ical/en.json`
  - 繁: `https://www.1823.gov.hk/common/ical/tc.json`
- Database table `tb_Holidays` includes metadata fields for sync:
  - `SourceUID` NVARCHAR(64), `SourceProvider` NVARCHAR(50), `LastSyncedAt` DATETIME
- Stored procedure `sp_UpsertHolidays_TVP` merges by `HolidayDate`; bilingual names maintained.

## Views/Reports | 檢視／報表

- v_AnnualEntitlement: AnnualDays, CarryForward, Compensatory, AnnualTotal / 年度權益：年度天數、結轉、補償、年度總額
- v_SickBalance: Sick paid entitlement vs used / 病假結餘：有薪病假權益與已用比對
- v_LeaveTotals: RemainingDays incl. negatives / 假期總覽：包含為負的剩餘天數

## Audit & Security | 審計與安全

- All compensatory grants and negative approvals audited. / 對所有補償發放與負結餘批准進行審計。
- Optional rate limits/escalations configurable. / 可配置速率限制／升級處理。

---

## Backend Notes | 後端注意事項

- AnnualTotal formula: AnnualDays + CarryForwardFromLastYear + CompensatoryThisYear。
- Carry-forward: unlimited, no expiry; computed via `dbo.usp_RecalcYearOpeningBalances(@Year)` 每年結轉；計算為（上年結轉 + 上年年度天數 + 上年補償 − 上年已用），結果不得為負。
- Views:
  - `v_AnnualEntitlement`: 使用 `tb_YearOpeningBalances` 之當年結轉 + 當年補償 + 當年年度天數。
  - `v_LeaveTotals`: 顯示 AnnualTotal、AnnualUsed、AnnualRemaining。
- Procedures:
  - `usp_RecalcYearOpeningBalances`: 可重入、按年運行；不設到期。
- Contractual ladders: not used/maintained.
