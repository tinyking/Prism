# 个人记账软件「Money」开发方案

## 一、摘要

在 `Prism` 仓库内新增一个**独立的 macOS App target「Money」**，用于实现 `docs/money.md` 描述的个人记账软件。

第一版（V1）只做**最小闭环**：`记一笔 → 看余额 → 看月度统计 → 导出备份`。

技术栈：SwiftUI + SwiftData + Swift Charts，**不引入任何第三方依赖**。

---

## 二、现状分析（基于实际勘察）

### 2.1 仓库结构

```
/Users/tiny/Workspace/xcode/Prism/
├── Prism.xcodeproj/          # 唯一工程，含 3 个 target：Prism / PrismTests / PrismUITests
├── Prism/                    # App 源码（PBXFileSystemSynchronizedRootGroup，文件夹自动同步）
├── PrismTests/ PrismUITests/
└── docs/money.md             # 需求文档（本次输入）
```

关键事实：

- **只有一个 Xcode 工程** `Prism.xcodeproj`，`Prism` target 是 macOS App（`SDKROOT = macosx`，`MACOSX_DEPLOYMENT_TARGET = 27.0`，`SWIFT_VERSION = 5.0`）。
- 源码目录使用 **`PBXFileSystemSynchronizedRootGroup`**（Xcode 16+ 文件夹同步组）：放进 `Prism/` 的 `.swift` 自动参与编译，**无需在 pbxproj 里逐个登记文件**。因此新增 target 时必须为新 App 单独建一个**同步组目录**，否则代码会被编进 Prism。
- 已接入 **SwiftData**：[PrismApp.swift](file:///Users/tiny/Workspace/xcode/Prism/Prism/PrismApp.swift#L16-L27) 里已有 `ModelContainer(Schema([...]))` 的用法，可直接复用这套约定。
- Prism 的分层约定：`Theme/ Models/ Store/ Components/ Views/`，`Store` 层使用 `@Observable`（见 `Prism/Store/SkillStore.swift`）。
- 目标 target 的构建配置（用于复制）：`DEVELOPMENT_TEAM = 3Y4444LF66`、`ENABLE_APP_SANDBOX = NO`、`ENABLE_HARDENED_RUNTIME = YES`、`GENERATE_INFOPLIST_FILE = YES`、`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`、`SWIFT_APPROACHABLE_CONCURRENCY = YES`。

### 2.2 money.md 需求取舍

文档给了 4 大类功能 + 三版节奏。**V1 只取最小闭环所需的子集**，其余进路线图：

| 功能 | V1 | 说明 |
|---|---|---|
| 记账（收入/支出/转账） | ✅ | 金额、日期、分类、账户、备注 |
| 账户管理 + 余额 | ✅ | 现金/银行卡/支付宝/微信/信用卡 |
| 分类（一级） | ✅ | 预置常用分类，可增删 |
| 账单列表（筛选/编辑/删除） | ✅ | 按时间/账户/分类筛选 + 关键词搜索 |
| 月度收支统计 + 分类占比图 | ✅ | Swift Charts |
| CSV 导出备份 | ✅ | NSSavePanel |
| 登录/本地加密 | ❌ | 进 V1.5 |
| 预算、周期记账、提醒 | ❌ | 进 V2 |
| 多端同步、OCR、语音、家庭账本 | ❌ | 进 V2/V3 |
| 二级分类、标签、多币种 | ❌ | 进 V1.5/V3 |

---

## 三、总体设计

### 3.1 目标文件树

```
Money/                          # 仓库根目录下，与 Prism/ 平级（独立 App target）
├── MoneyApp.swift              # @main + ModelContainer
├── Models/
│   ├── Account.swift           # 账户
│   ├── Category.swift          # 分类
│   └── Entry.swift             # 一笔记录（收入/支出/转账）
├── Store/
│   ├── LedgerMath.swift        # 纯函数：余额、月度汇总、分类占比
│   └── SeedData.swift          # 首次启动预置账户与分类
├── Support/
│   └── CSVExport.swift         # 导出 CSV
├── Views/
│   ├── RootView.swift          # 侧栏导航骨架
│   ├── OverviewView.swift      # 净资产 + 各账户余额
│   ├── NewEntryView.swift      # 记一笔
│   ├── EntryListView.swift     # 账单列表（筛选/搜索/改删）
│   ├── ReportView.swift        # 月度统计（折线 + 饼图）
│   └── SettingsView.swift      # 导出备份
└── Assets.xcassets/            # AccentColor + AppIcon（占位）
```

### 3.2 数据模型（SwiftData）

**核心约定：金额一律用「整数分」存储（`Int`），杜绝浮点误差**（money.md 第六节明确要求）。

```swift
// Entry.swift
enum EntryKind: String, Codable, CaseIterable { case expense, income, transfer }

@Model final class Entry {
    var amountCents: Int          // 恒为正数
    var kindRaw: String           // EntryKind.rawValue
    var date: Date
    var note: String
    var createdAt: Date

    var account: Account?         // 支出/收入账户；转账时为转出账户
    var toAccount: Account?       // 仅转账时非空
    var category: Category?       // 转账时为空
}
```

```swift
// Account.swift
@Model final class Account {
    var name: String
    var kindRaw: String           // 现金/银行卡/支付宝/微信/信用卡
    var openingBalanceCents: Int  // 期初余额
    var sortOrder: Int
}
```

```swift
// Category.swift
@Model final class Category {
    var name: String
    var kindRaw: String           // expense / income
    var symbol: String            // SF Symbol 名
    var sortOrder: Int
}
```

关系删除规则统一用 `.nullify`（删账户/分类不级联删账单，符合 money.md「删除账户前要处理关联账单」的谨慎原则；V1 在删除时弹二次确认）。

### 3.3 业务规则（写进 `LedgerMath`）

1. **转账不计入收入或支出**（money.md 明确警告）。月度收入/支出只统计 `expense` / `income`。
2. 账户余额 = `期初余额 + 收入 − 支出 + 转入 − 转出`。
3. 日期归属统一用**当前日历的本地时区**，月度区间用 `Calendar.dateInterval(of: .month, for:)`，避免时区/边界错位。
4. 净资产 = 全部账户余额之和（信用卡余额可为负）。

`LedgerMath` 全部为**无副作用的纯静态函数**，输入 `[Entry]`，输出数值/数组，便于单元测试。

### 3.4 UI 骨架

`RootView` 用 `NavigationSplitView`：左侧导航（概览 / 记一笔 / 账单 / 统计 / 设置），右侧内容区按选中项切换。

- 视觉上沿用 macOS 原生风格，**不复制 Prism 的隐藏标题栏自绘方案**（那是 Prism 的特例，V1 无需重复其复杂度）。

---

## 四、实施步骤

### Step 1：工程接入（新增 Money target）

修改 [project.pbxproj](file:///Users/tiny/Workspace/xcode/Prism/Prism.xcodeproj/project.pbxproj)，**镜像现有 Prism target 的对象结构**，新增以下对象（UUID 用新的唯一 24 位十六进制串）：

1. `PBXFileReference`：`Money.app`（加入 `Products` 组）
2. `PBXFileSystemSynchronizedRootGroup`：`Money`（加入主 `PBXGroup` 的 children）
3. `PBXSourcesBuildPhase` / `PBXFrameworksBuildPhase` / `PBXResourcesBuildPhase`（各一个，`files = ()`）
4. `PBXNativeTarget`：`name = Money`、`productType = com.apple.product-type.application`、`fileSystemSynchronizedGroups = (Money 组)`
5. `XCBuildConfiguration` × 2（Debug/Release）+ `XCConfigurationList`，构建配置**照抄 Prism target**，仅改：
   - `PRODUCT_BUNDLE_IDENTIFIER = cn.wangjianchao.prism.Money`
   - `ASSETCATALOG_COMPILER_APPICON_NAME` / `GLOBAL_ACCENT_COLOR_NAME` 指向 Money 自己的 Assets
6. 更新 `PBXProject.attributes.TargetAttributes`（加 Money）与 `targets` 列表
7. 创建 `Money/Assets.xcassets`（`AccentColor`、`AppIcon` 空占位）与 `Money/MoneyApp.swift`（最小可运行）

> 不使用 XcodeGen/Tuist 等外部工具，避免重写整个工程、破坏现有同步组结构。
> 命令行构建用 `-target Money`（无需先有 scheme）。

### Step 2：数据模型

按 §3.2 创建 `Account.swift` / `Category.swift` / `Entry.swift`。
`MoneyApp.swift` 的 `ModelContainer` schema 注册三个模型。

### Step 3：业务层

- `LedgerMath.swift`：`balance(of:)`、`monthSummary(_:)`、`expenseBreakdownByCategory(_:)`、`netWorth(_:)`。
- `SeedData.swift`：首次启动（库为空时）写入默认账户（现金/微信/支付宝）与常用分类（餐饮/交通/购物/居住/工资等）。

### Step 4：UI

按 §3.4 逐个实现 `RootView` → `OverviewView` → `NewEntryView` → `EntryListView` → `ReportView`。
`NewEntryView` 支持三种类型切换，转账时第二账户选择器才出现。

### Step 5：导出

`CSVExport.swift`：把全部 `Entry` 序列化为 CSV（`日期,类型,金额,账户,目标账户,分类,备注`），经 `NSSavePanel` 落盘。
金额导出为**元（两位小数）**，避免用户看到分。

### Step 6：构建与验证

见 §六。

---

## 五、关键决策与假设

| # | 决策 | 理由 |
|---|---|---|
| 1 | 代码放在仓库根 `Money/`，**不放** `Prism/` 下 | `Prism/` 是 Prism target 的同步组，放进去会被编进 Prism |
| 2 | 手改 `project.pbxproj` 新增 target | 无外部依赖，保留现有同步组机制 |
| 3 | 金额用 `Int` 分 | money.md 明确要求，避免浮点误差 |
| 4 | 转账不计收支 | money.md 明确要求 |
| 5 | 不复制 Prism 的自绘标题栏 | V1 降复杂度，用系统窗口 |
| 6 | 不做登录/加密 | 属于「最小闭环」之外，进 V1.5 |
| 7 | 关系删除用 `.nullify` + 二次确认 | 防误删导致账单悬空 |

**假设**：默认账户与分类由 `SeedData` 预置；V1 单人单机、无多币种、日期用本地时区；`docs/money.md` 的其余功能按 §三路线图推进。

---

## 六、验证方式

1. `xcodebuild -list -project Prism.xcodeproj` → 能看到 `Prism` 与 `Money` 两个 target。
2. `xcodebuild -project Prism.xcodeproj -target Money -configuration Debug build` → **BUILD SUCCEEDED**。
3. `xcodebuild -project Prism.xcodeproj -scheme Prism build` → 仍 **BUILD SUCCEEDED**（确认未破坏原 target）。
4. 运行 `Money.app` 手动冒烟：
   - 记一笔 100 元支出 → 对应账户余额减 100，月度支出 +100；
   - 记一笔 5000 元收入 → 余额与月度收入正确变化；
   - 记一笔账户 A→B 转账 → **A、B 余额变化，但月度收支不变**（关键校验点）；
   - 切到统计页 → 月度收支与分类占比图与录入一致；
   - 导出 CSV → 打开文件，金额为元、行数与账单数一致。
5. 单元测试（可选）：为 `LedgerMath` 加纯函数测试（余额、转账不计收支、月度边界）。

---

## 七、后续路线图（本次不实现）

- **V1.5**：登录/本地加密、二级分类、标签、预算与超支提醒。
- **V2**：周期记账、提醒、信用卡账单日/还款日、报表同比环比、搜索筛选增强。
- **V3**：OCR/语音记账、账单导入自动分类、多端同步、家庭账本、多币种。
