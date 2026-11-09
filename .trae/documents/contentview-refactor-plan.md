# ContentView.swift 按页面拆分方案

## Context

`Prism/ContentView.swift` 目前 916 行，把主题色板、数据模型、技能扫描逻辑、根布局、四个页面级视图、详情 sheet、自定义滚动条全部塞在一个文件里。`ContentView` 本体占 557 行（230–787），后续改动需要在大文件里反复定位。

目标：**行为零变化**，仅按“内容归属”把代码搬到不同文件，并建立子目录分类。`ContentView` 退化为根布局 + 共享状态（约 110 行）。

已确认的三项决策：

1. 粒度：按页面完整拆分
2. 目录：建子目录分类
3. Skills 状态：抽成 `SkillStore`（`@Observable`），侧栏与 Skills 页共享

前置事实（已核查）：

- 工程使用 `PBXFileSystemSynchronizedRootGroup`（`project.pbxproj` 32–48 行），**新增 .swift 文件放进 `Prism/` 会自动参与编译，无需改 pbxproj**。
- 部署目标 macOS 27.0，Swift 5 语言模式，`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`。
- 现有辅助类型全部是 **file 级 `private`**（等价 fileprivate）。跨文件后必须提升为 internal，否则编译报错。这是本次拆分的主要机械性改动。
- 全项目无 `// MARK:`，文件头注释统一为 `//  <File>.swift\n//  <Target>\n//  Created by 王建朝 on <date>.`，沿用即可。

## 目标文件结构

```
Prism/
├── ContentView.swift                 根布局 + 共享状态（~110 行）
├── PrismApp.swift                    不动
├── Theme/
│   ├── DealPalette.swift             DealPalette + Color(hex:)
│   └── SkillToolPalette.swift        SkillToolPalette
├── Models/
│   ├── Deal.swift                    Deal + Deal.samples
│   ├── InboxConversation.swift       InboxConversation + samples
│   ├── SkillItem.swift               SkillItem
│   └── SkillScanner.swift            SkillScanner + String.nilIfEmpty
├── Store/
│   └── SkillStore.swift              @Observable 技能扫描状态
├── Components/
│   ├── AvatarView.swift              跨页面共用的头像圆片
│   └── FadingScrollBar.swift         ScrollMetrics / ScrollMetricsKey / FadingScrollBar
└── Views/
    ├── SidebarView.swift             侧栏 + 拖拽调宽 + 收起/展开按钮
    ├── InboxView.swift               InboxListView + InboxDetailView
    ├── DealsView.swift               DealsView（概览/阶段/标签页/表格/汇总）
    ├── SkillsView.swift              SkillsView + SkillCard
    └── SkillDetailView.swift         技能详情 sheet
```

## 各文件职责与接口

### Theme/
`DealPalette`(enum) + `Color(hex:)` 合并到 `DealPalette.swift`；`SkillToolPalette` 单独一个文件。两者去掉 `private`。

### Models/
`Deal`、`InboxConversation`、`SkillItem` 各自成文件，保留各自的 `static let samples`，去掉 `private`。
`SkillScanner.swift`：整个 `enum SkillScanner`（含内嵌 `Source`、`sources`、`scan`、`parse`、`yamlValue`）+ `extension String { var nilIfEmpty }`。`nilIfEmpty` 仅此处使用，不另立文件。

### Store/SkillStore.swift
把 `ContentView` 的四个 `@State`（`skills` / `skillsLoaded` / `isScanningSkills` / `skillScanMessage`）与 `scanSkills()`（541–550）内聚进来：

```swift
@Observable
final class SkillStore {
    var skills: [SkillItem] = []
    var isLoaded = false
    var isScanning = false
    var message: String?

    func scanIfNeeded()   // !isLoaded 时才扫
    func scan()           // 原 scanSkills 的实现
}
```

`scan()` 里的工程根目录推导需要改写（见下方“必须处理的坑”）。

### Views/SidebarView.swift
```swift
struct SidebarView: View {
    @Binding var selectedNav: String
    @Binding var isSidebarCollapsed: Bool
    @Binding var sidebarWidth: CGFloat
    let skillsCount: Int?          // store.isLoaded ? store.skills.count : nil
}
```
内含：顶部（收起按钮 + App 图标 + "Prism"）、`navItem` 列表、底部用户信息、右侧 `sidebarResizeHandle`。
`sidebarDragStart` 从 ContentView 移入本项目部 `@State`（纯交互态，无需外泄）。
`expandSidebarButton`（296–315）改名为 `ExpandSidebarButton` 放在**同一文件**，作为收起态下的独立小视图，接收 `@Binding var isSidebarCollapsed`。

### Views/InboxView.swift
```swift
struct InboxListView: View {
    @Binding var searchText: String
    @Binding var selectedConversation: InboxConversation?
    let conversations: [InboxConversation]
}
struct InboxDetailView: View { let conversation: InboxConversation }
```
搜索框保持在这个列表里（现状即如此，`searchText` 同时影响 Deals/Skills 的过滤，属既有行为，不做修正）。

### Views/DealsView.swift
```swift
struct DealsView: View {
    @Binding var selectedTab: String
    @Binding var selectedDeals: Set<UUID>
    @Binding var showingNewDeal: Bool
    let deals: [Deal]
}
```
内含 `overview`、`stageOverview`、`dealTabs`、`dealTable`、`summaryFooter` 及局部私有成员 `tabButton` / `filterPill` / `headerCell` / `dealRow` / `stageColor` / `stepIcon` / `metric`（这些只在本页使用，不下沉到 Components）。
`stages` 常量数组（247–251）从 ContentView 移入本文件作为私有常量。
`New deal` 的 `.alert` 一并从 `body` 移入本页（触发者即本页的 overview）。

### Views/SkillsView.swift
```swift
struct SkillsView: View {
    @Binding var searchText: String
    let store: SkillStore
    @State private var selectedSkill: SkillItem?
}
```
内含 `skillsContent`、技能卡片、`filteredSkills`（由 `store.skills` + `searchText` 计算）、技能详情 `.sheet`、以及 `.task { store.scanIfNeeded() }`。
技能详情 sheet 从根 `body` 移到这里（行为等价），`SkillDetailView` 单独成文件。

### ContentView.swift（保留）
- 共享状态：`selectedTab`、`searchText`、`selectedDeals`、`selectedNav`、`selectedConversation`、`isSidebarCollapsed`、`sidebarWidth`、`@State private var skillStore = SkillStore()`
- 三个过滤计算属性：`filteredDeals`（需 `selectedTab` + `searchText`）、`filteredConversations`（`searchText`）
  - `filteredSkills` 移入 SkillsView（需要 store）
- `body`：`HStack { 侧栏? ; VStack { 展开按钮? ; HStack { InboxListView? ; detailContent } } }`
- `detailContent`：按 `selectedNav` 分发到 `InboxDetailView` / `SkillsView` / `DealsView`
- `stages`、`showingNewDeal`、`selectedSkill`、四个 skills 状态**全部移出**，但不再通过 Binding 透传，改为各页内部状态或 SkillStore
- 顶部 `.background` / `.ignoresSafeArea` 保持不动

## 必须处理的坑

1. **`SkillScanner` 的工程根目录推导会失效（唯一的运行期语义变更）**
   现状（ContentView.swift 546–547）：
   ```swift
   let sourceFile = URL(fileURLWithPath: #filePath)
   let projectRoot = sourceFile.deletingLastPathComponent().deletingLastPathComponent()
   ```
   依赖“文件位于 `Prism/` 下、上两级即仓库根”。文件挪到 `Prism/Models/` 后上两级变成 `Prism/`，`projectPaths` 会指向错误目录，技能扫描结果从 103 条掉到只剩全局路径。
   **改法**：改为向上查找工程标记，与文件位置无关：
   ```swift
   static var projectRoot: URL {   // 放在 SkillScanner
       var url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
       while url.path != "/" {
           if FileManager.default.fileExists(atPath: url.appendingPathComponent("Prism.xcodeproj").path) { return url }
           url.deleteLastPathComponent()
       }
       return URL(fileURLWithPath: #filePath).deletingLastPathComponent()
   }
   ```

2. **访问级别**：所有被搬动的类型去掉 file 级 `private`（`DealPalette`、`SkillToolPalette`、`Deal`、`InboxConversation`、`SkillItem`、`SkillScanner`、`SkillDetailView`、`FadingScrollBar`、`ScrollMetrics`、`ScrollMetricsKey`、`Color(hex:)`、`String.nilIfEmpty`）。仅单文件内使用的成员保持 `private`。

3. **`FadingScrollBar` 的 `.scrollIndicators(.never)` 必须保留**（`.hidden` 在“始终显示滚动条”的系统设置下不生效），三件套（`ScrollMetrics`/`ScrollMetricsKey`/`FadingScrollBar`）一起搬。

4. **侧栏几何常量不要动**：收起/展开按钮均为 `.padding(.leading, 76)` + `.frame(height: 32)`，与红绿灯中心 y=16 对齐；`sidebarWidth` 限制 140–320。

5. `@Observable` 需要 `import Observation`（或依赖 SwiftUI 的再导出，显式导入更稳）。

## 实施步骤

1. 新建 `Theme/`、`Models/`、`Store/`、`Components/`、`Views/` 目录，按上表落地文件，逐个从 ContentView.swift 剪切对应行区间。
2. 同步提升访问级别、补文件头注释。
3. 改写 `SkillScanner.projectRoot`；把 skills 状态与扫描逻辑搬进 `SkillStore`。
4. 重写 `ContentView.swift` 为根布局 + 共享状态，接上各子视图。
5. 编译，修掉残余的可见性/参数错误。

## 验证方式

1. **编译**：
   ```
   xcodebuild -project /Users/tiny/Workspace/xcode/Prism/Prism.xcodeproj -scheme Prism \
     -configuration Debug -derivedDataPath /tmp/PrismDD build
   ```
   要求 `BUILD SUCCEEDED` 且无新增 warning。

2. **逐页像素比对（行为零变化的客观判据）**
   改动前先对三个页面各抓一次窗口位图（做法：临时把 `selectedNav` 默认值改为目标页 → 构建 → `open` 应用 → `screencapture -l <windowID>`），改动后同样抓一次，逐页比对差异应为 0。
   重点核对 Skills 页：技能卡片数量与侧栏计数徽标（应为 103）必须与改动前一致——这是 `projectRoot` 改写是否正确的直接证据。

3. **人工抽查**（自动化无法覆盖）：侧栏拖拽调宽、收起/展开动画、Skills 页滚动条淡入淡出、技能详情 sheet、Deals 页多选与标签页筛选。

4. 收尾：还原临时改动、重新构建，并 `pkill -x Prism` 清干净实例。
