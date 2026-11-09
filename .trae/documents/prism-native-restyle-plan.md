# Prism 原生化改造方案（对齐 Money 风格）

## Context

`Prism/` 是一个 Sales/CRM 风格的 demo App（Inbox / Deals / Skills 三页），它的视觉实现是**全套自绘**：隐藏标题栏 + AppDelegate 改窗口 chrome、手写 `HStack` 侧栏（160pt，可拖拽折叠）、硬编码 sRGB 色板（`DealPalette`、`SkillToolPalette`）、全项目固定 `.system(size:)` 字号、手写表格与手写滚动条。任何改动都要在大段自绘代码里找样式，且无法适配深浅色。

同仓库的 `Money/` 是本轮新写的原生 macOS App，风格即目标：`NavigationSplitView` + 原生 `List(selection:)` 侧栏、`.navigationTitle`、语义字体、`Color.gray.opacity(0.12)` 圆角卡片、`Form(.grouped)` 输入页、系统滚动条与选中态高亮。

本次目标：**把 Prism 的风格、排版、字体改造成 Money 那样的原生样貌，功能与信息架构不变**。已确认三项决策：① 完全原生化；② Inbox 用三栏 `NavigationSplitView`；③ Deals 表格换成原生 `Table`。不改 `Money/`。

## 目标形态：复用 Money 的既有写法

- 侧栏：[RootView.swift](file:///Users/tiny/Workspace/xcode/Prism/Money/Views/RootView.swift#L46-L55) 的 `NavigationSplitView { List(…, selection:) { Label(title, systemImage:).tag(…) }.navigationSplitViewColumnWidth(…) }`。
- 页面：[OverviewView.swift](file:///Users/tiny/Workspace/xcode/Prism/Money/Views/OverviewView.swift#L20-L44) 的 `ScrollView { VStack(alignment:.leading, spacing:20) { cards }.padding(24) }`、`.padding(20).frame(maxWidth:.infinity, alignment:.leading).background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))`、`.navigationTitle(…)`、`.monospacedDigit()`、`.foregroundStyle(.secondary)`、`Divider()`。
- 输入页：`Form { Section { … } }.formStyle(.grouped)`。

## 文件改动总览

**新建**
- `Prism/Theme/AppTheme.swift`：唯一的颜色映射文件 —— 语义 token（`separator` / `controlBackground` 等）+ 多色 Accent 调色板 + `accent(forTool:)` + `stageColor(_:)`。

**改写**
- `Prism/PrismApp.swift`：删除 `import AppKit`、`@NSApplicationDelegateAdaptor`、整个 `PrismAppDelegate`、`.windowStyle(.hiddenTitleBar)`。
- `Prism/ContentView.swift`：`HStack` 自绘根布局 → `NavigationSplitView` 容器；侧栏逻辑内联为 `sidebar` 子视图；`skillStore` 计数改 `.badge(Int?)`。
- `Prism/Views/DealsView.swift`：手写表格 → 原生 `Table`；阶段/标签页 → `.segmented` Picker；搜索 → `.searchable`。
- `Prism/Views/InboxView.swift`：`InboxListView` → `List(selection:)`；`InboxDetailView` 头部改 `.toolbar`、空态改 `ContentUnavailableView`。
- `Prism/Views/SkillsView.swift`：去掉 `FadingScrollBar`；头部/计数/rescan 移入 `.navigationTitle` + `.toolbar`；卡片语义化。
- `Prism/Views/SkillDetailView.swift`、`Prism/Components/AvatarView.swift`：语义字体/色。
- `Prism/Models/Deal.swift`、`Prism/Models/InboxConversation.swift`：仅把 `color` / `tint` 的赋值来源从 `DealPalette.*` 换为 `AppTheme.Accent`（字段仍是 `Color`）。

**删除**
- `Prism/Theme/DealPalette.swift`、`Prism/Theme/SkillToolPalette.swift`（收敛进 AppTheme）。
- `Prism/Views/SidebarView.swift`（含 `ExpandSidebarButton`，仅 ContentView 引用）。
- `Prism/Components/FadingScrollBar.swift`（含 `ScrollMetrics` / `ScrollMetricsKey`，仅 SkillsView 引用）。

**保留不动**：`Models/SkillItem.swift`、`Models/SkillScanner.swift`、`Store/SkillStore.swift`、`Item.swift`。

## 颜色迁移表

| 旧 | 新 |
|---|---|
| `DealPalette.ink` | `Color.primary` |
| `.muted` | `.foregroundStyle(.secondary)` |
| `.line` | `Color(nsColor: .separatorColor)` 或直接用 `Divider()` |
| `.frame` | `Color(nsColor: .controlBackgroundColor)` |
| `.blue/.purple/.amber/.red/.green` | `.blue/.purple/.orange/.red/.green`（系统语义色，自动适配深浅色） |
| 各页 `.background(.white)` | `Color(nsColor: .textBackgroundColor)` 或删除（交系统绘制） |
| 侧栏硬编码蓝灰 `Color(red:0.91…)` | 删除（原生 List 侧栏自带材质） |
| `AvatarView` 灰底 `#F0F0F5` | `Color(nsColor: .quaternaryLabelColor)` + `.foregroundStyle(.secondary)` |
| `SkillToolPalette.colors(for:scheme:)` | `AppTheme.accent(forTool:)` 返回单个系统色，用 `.foregroundStyle(c)` + `.background(c.opacity(0.15))`，`scheme` 参数与 `@Environment(\.colorScheme)` 一并删除 |
| `DealsView.stageColor` 内联硬编码 | 移入 `AppTheme.stage(_:)` |

`Deal.color` 不再当行背景，只用于 Company 单元格首字母色块（`RoundedRectangle.fill(deal.color.gradient)`）。

## 字号迁移表

| 旧 pt | 语义样式 |
|---|---|
| 8 / 9 | `.caption2` |
| 10 | `.caption` |
| 11 | `.subheadline` |
| 12 | `.callout` |
| 13 | `.body` |
| 15 | `.title3` |
| 17 | `.title2` |
| 20 / 21 | `.title2` / `.title` |
| 29（页标题） | 删除，改由 `.navigationTitle(…)` 承载 |
| 56（空态图标） | `ContentUnavailableView` |

数字/金额/概率一律加 `.monospacedDigit()`；`weight:.semibold` 的标题改用 `.headline` / `.title3`。

## 关键实现要点

### 1. 窗口（PrismApp.swift）
删 AppDelegate（其唯一职责是窗口 chrome，无其它副作用）、删 `.hiddenTitleBar`、删 `ContentView` 里的 `.ignoresSafeArea(.container, edges: .top)` 与任何让位红绿灯的 `padding(.leading, …)`。保留 `sharedModelContainer`（含 `Item.self`）与 `.modelContainer(…)`。

### 2. ContentView：按 section 条件切换栏数（避免空栏）
```swift
enum NavSection: String, CaseIterable, Identifiable { case inbox, deals, skills }  // 提供 title / symbol

if (section ?? .inbox) == .inbox {
    NavigationSplitView { sidebar } content: {
        InboxListView(selection: $conversationID, searchText: $searchText)
            .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
    } detail: { InboxDetailView(conversation: …) }
} else {
    NavigationSplitView { sidebar } detail: {
        switch section { case .deals: DealsView(…); case .skills: SkillsView(…); default: EmptyView() }
    }
}
```
- 三栏只在 Inbox 出现，Deals/Skills 走两栏，无空栏。
- `sidebar`：`List(NavSection.allCases, selection: $section) { Label(…).tag(…).badge(badge(for:)) }`；`badge` 返回 `Int?`（skills 且 `skillStore.isLoaded` 时给 `skills.count`，否则 `nil` 自动隐藏）。
- 删除 `isSidebarCollapsed` / `sidebarWidth` / 拖拽手柄；折叠交给系统 sidebar toggle。
- 加 `.navigationSplitViewStyle(.balanced)`；`.task { skillStore.scanIfNeeded() }` 保留。
- 副作用：切换 section 会重建 split view，列宽复位，属可接受。

### 3. DealsView：原生 Table
- `Table(rows, selection: $selectedDeals, sortOrder: $sortOrder)`；`Deal.id` 是 `UUID`，与现有 `selectedDeals: Set<UUID>` 直接匹配，多选（⌘/⇧）为系统原生高亮。
- 列：Company（首字母色块 + 公司/明细两行）、Stage（胶囊）、Owner（`AvatarView` + 姓名）、Value（`.currency(code:"USD").precision(.fractionLength(0))`）、Win probability、Next step、Last touch。
- 带 `value: \.keyPath` 的列自动点表头排序；`value: Int` / 其余 `String` 均 `Comparable`，无需自定义 Comparator。
- 删除 `minWidth 1190` 横向滚动、手写表头与 `headerCell` / `dealRow`。
- 阶段/标签页 `tabButton` → `Picker(…).pickerStyle(.segmented).labelsHidden()`；搜索 → `.searchable(text:prompt:)`；`New deal` 的 `.alert` 与工具栏 `plus` 按钮保留；底部 `metric(label:value:)` 汇总保留为 Table 下方卡片（沿用 Money 卡片写法）。
- 页面加 `.navigationTitle("交易")`。

### 4. Inbox
- `InboxListView` → `List(conversations, selection: $selection)`（`selection: InboxConversation.ID?`）；行内 `HStack{ 图标(带 tint) + 标题/预览 + Spacer + 时间 }`，未读用 `.badge(unread)`（0 传 nil）。删除 `.frame(width: 270)`、`.overlay` 分隔线、手写选中底色与硬编码背景。
- `InboxDetailView`：头部图标移入 `.toolbar`，标题 `.headline` + `.secondary` 副标题，气泡用 `Color(nsColor: .controlBackgroundColor)`，空态换 `ContentUnavailableView("选择会话", systemImage: "bubble.left.and.bubble.right")`。

### 5. Skills / SkillDetail / Avatar
- `SkillsView`：`FadingScrollBar { … }` → `ScrollView`；页面标题 `.navigationTitle("技能")`，`N skills` 计数与 rescan、folder 按钮移入 `.toolbar`；卡片 `RoundedRectangle(cornerRadius: 12)` + `Color(nsColor: .controlBackgroundColor)`；工具胶囊改用 `AppTheme.accent(forTool:)`；空态 `ContentUnavailableView`。保留 `LazyVGrid`（`adaptive, min 245, spacing 12`）。
- `SkillDetailView`：保留 `VStack + Divider`，字体改语义样式，正文 `.font(.system(.body, design: .monospaced))`，去掉 `.background(.white)`。
- `AvatarView`：`Color(nsColor: .quaternaryLabelColor)` 底 + `.secondary` 前景 + `.caption2.weight(.semibold)`。

## 风险与注意点

1. 删除 `DealPalette` 前，先同步替换 `Deal.samples`（21 条）、`InboxConversation.samples` 里的所有 `DealPalette.*` 引用，否则编译失败。
2. 删除 `.ignoresSafeArea(top)` 后布局整体下移属预期；务必同批删掉所有为隐藏标题栏让位的 `padding`。
3. `.searchable` 会挂在窗口 toolbar 上：Inbox 的挂 content 栏、Deals 的挂 detail 栏，避免两个搜索框并列。
4. 删 `FadingScrollBar.swift` / `SidebarView.swift` 前确认引用已清零（已核对：前者仅 SkillsView，后者仅 ContentView）。
5. `SkillToolPalette` 的 `scheme` 参数删除后，`SkillsView` / `SkillDetailView` 里的 `@Environment(\.colorScheme)` 若不再使用要一并删除，避免未使用告警。
6. `Table` 排序依赖 `id` 稳定；`Deal.samples` 是静态常量，满足。
7. 深色模式：替换掉全部 `.white` 与硬编码浅色后自动适配。

## 验证

1. 构建 Prism：`xcodebuild -project Prism.xcodeproj -target Prism -configuration Debug build`（或 `-scheme Prism`），需 BUILD SUCCEEDED。
2. 确认未误伤：`xcodebuild -project Prism.xcodeproj -target Money -configuration Debug build` 仍成功；`git status` 显示的改动/新增/删除全部位于 `Prism/` 目录下，`Money/` 零改动。
3. 运行 `build/Debug/Prism.app` 冒烟，逐项对照改造前行为：
   - 窗口有原生标题栏，红绿灯可用，系统可折叠侧栏。
   - 侧栏三项切换正常；Skills 计数徽标显示。
   - Inbox：三栏；选中会话驱动右侧详情；未读徽标。
   - Deals：表头点击排序、⌘/⇧ 多选高亮、分段筛选、搜索过滤、New deal 弹窗、底部汇总。
   - Skills：扫描计数正确、rescan、工具胶囊配色可区分、卡片点击弹 sheet、Esc 关闭、folder 按钮打开 Finder。
   - 切换系统深/浅色，配色正常。
