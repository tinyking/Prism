# Prism 顶栏（Top Bar）实现方案

## 1. 需求

窗口右侧内容需要顶格显示，窗口顶部不能出现一条独立的工具条区域（即系统的 titlebar / toolbar 带）。

## 2. 方案演进

| 版本 | 做法 | 结果 |
| --- | --- | --- |
| v1 系统 toolbar | `.windowStyle(.hiddenTitleBar)` + `.windowToolbarStyle(.unified)`，在 `ContentView` 上挂 `.toolbar { ... }` | macOS 仍会为 toolbar 保留一条带状区域，内容被 safe area 压到下方，顶部出现灰色条带 |
| v2 内容内顶栏 | 去掉 `.toolbar`，根视图 `.ignoresSafeArea(.container, edges: .top)`，右侧加一条 40pt 的自绘顶栏 | 系统条带消失，但右侧仍多出一条 40pt 行，不算真正顶格 |
| v3 当前方案 | 完全去掉顶栏，右侧直接以页面自身头部（Deals / Skills / Inbox）起步，原顶栏功能就近安置 | 右侧内容真正顶格，无任何独立条带 |

## 3. 当前实现

### 3.1 窗口层：无标题栏 + 全尺寸内容

`Prism/PrismApp.swift`：

```swift
var body: some Scene {
    WindowGroup {
        ContentView()
    }
    .modelContainer(sharedModelContainer)
    .windowStyle(.hiddenTitleBar)
}

private static func configure(_ window: NSWindow) {
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.titlebarSeparatorStyle = .none
    window.styleMask.insert(.fullSizeContentView)
    window.isMovableByWindowBackground = true
    window.contentView?.needsLayout = true
}
```

各属性作用：

- `.windowStyle(.hiddenTitleBar)`：不显示标题栏，只保留左上角红绿灯。
- `titlebarAppearsTransparent = true` + `fullSizeContentView`：让内容视图铺满整个窗口（含标题栏区域）。
- `titlebarSeparatorStyle = .none`：去掉标题栏下方分割线。
- `isMovableByWindowBackground = true`：内容盖住标题栏后，仍可按住空白背景拖动窗口。

### 3.2 全出血布局

`Prism/ContentView.swift`，根视图：

```swift
var body: some View {
    HStack(spacing: 0) {
        if isSidebarCollapsed { collapsedSidebar } else { sidebar }
        if selectedNav == "Inbox" { inboxList }
        detailContent
    }
    .background(DealPalette.frame.ignoresSafeArea())
    .ignoresSafeArea(.container, edges: .top)
    // alert / sheet / task ...
}
```

关键点：只设置 `fullSizeContentView` 不足以让 SwiftUI 内容顶到窗口上沿，内容仍会被标题栏 safe area 向下推；必须再加 `.ignoresSafeArea(.container, edges: .top)`。

同时各列背景也向上延伸，避免露出根视图的灰色底：

```swift
// 侧边栏
.background { Color(red: 0.91, green: 0.93, blue: 0.96).ignoresSafeArea(edges: .top) }

// 会话列表
.background { Color(red: 0.985, green: 0.985, blue: 0.99).ignoresSafeArea(edges: .top) }
```

右侧详情自身是白色背景（`detailContent` 的 `.background(.white)`），顶格后直接铺到窗口上沿。

### 3.3 红绿灯避让

内容铺满后，会与左上角红绿灯（约 `x: 12–66, y: 14–26`）重叠，需要留白：

- 侧边栏展开时：侧栏顶部工作区标题行 `padding(.top, 30)`，让 Logo 行落在红绿灯下方。
- 侧边栏收起时：左侧渲染 72pt 窄栏（宽度覆盖红绿灯横向范围），展开按钮 `padding(.top, 30)`。

```swift
private var collapsedSidebar: some View {
    VStack(spacing: 0) {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { isSidebarCollapsed = false }
        } label: {
            Image(systemName: "sidebar.right")
                .font(.system(size: 12))
                .foregroundStyle(DealPalette.muted)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Expand sidebar")
        .padding(.leading, 12)
        .padding(.top, 30)
        .frame(maxWidth: .infinity, alignment: .leading)
        Spacer(minLength: 0)
    }
    .frame(width: 72)
    .background { Color(red: 0.91, green: 0.93, blue: 0.96).ignoresSafeArea(edges: .top) }
    .overlay(alignment: .trailing) { DealPalette.line.frame(width: 1) }
}
```

### 3.4 原顶栏控制项的去向

| 原顶栏元素 | 现位置 |
| --- | --- |
| 面包屑（Pipeline › Deals / Workspace › Skills） | 删除（页面自身标题已表意） |
| 侧栏折叠时的搜索框 | 删除（默认状态下本来没有该入口） |
| 侧栏折叠 / 展开按钮 | 折叠按钮在侧栏顶部标题行；展开按钮在 72pt 窄栏 |
| 通知铃铛、Q4 徽标 | Deals 页目标卡片上方（右上角） |
| New deal 按钮 | Deals 大标题右侧 |

侧栏顶部折叠按钮：

```swift
Spacer(minLength: 0)
Image(systemName: "chevron.down")
    .font(.system(size: 9, weight: .semibold))
    .foregroundStyle(DealPalette.muted)
Button {
    withAnimation(.easeInOut(duration: 0.2)) { isSidebarCollapsed = true }
} label: {
    Image(systemName: "sidebar.left")
        .font(.system(size: 11))
        .foregroundStyle(DealPalette.muted)
}
.buttonStyle(.plain)
.help("Collapse sidebar")
```

Deals 页头部（`overview`）：

```swift
HStack(spacing: 12) {
    Text("Deals")
        .font(.system(size: 29, weight: .semibold, design: .rounded))
        .tracking(-0.7)
    Button { showingNewDeal = true } label: {
        Label("New deal", systemImage: "plus")
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 10)
            .frame(height: 26)
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.88, green: 0.88, blue: 0.90), lineWidth: 1))
    }
    .buttonStyle(.plain)
}
```

## 4. 注意事项

1. **SwiftUI `.toolbar` 一定会占用一条区域**：`windowToolbarStyle` 只能改样式，不能消除条带；要真正顶格必须移除 `.toolbar`。
2. **`fullSizeContentView` ≠ 内容顶格**：它只让内容可以铺到标题栏下面，SwiftUI 仍会按 safe area 内缩，必须显式 `ignoresSafeArea(.container, edges: .top)`。
3. **拖动窗口**：内容盖住标题栏后，需 `isMovableByWindowBackground = true`，否则没有可拖拽的标题栏。
4. **红绿灯坐标**：约 `x: 12–66, y: 14–26`。左侧内容要么下移（顶部 padding ≥ 30），要么右移（前导 ≥ 72），否则会重叠。
5. **背景要一起顶格**：只让内容 ignore safe area 而背景不 ignore，会在顶部露出根视图底色，看起来仍像一条工具条。
6. **页面高度补偿**：去掉顶栏后，各页面原有 `padding(.top, …)`（如 Deals 22、Skills 24）即为首个内容的间距，不要重复叠加 30pt 红绿灯留白（红绿灯只影响最左侧一列）。

## 5. 如需恢复顶栏

- 优先用 `.safeAreaInset(edge: .top)` 自绘顶栏，而不是系统 `.toolbar`，这样可控高度与背景。
- 或做成 `overlay(alignment: .top)` 的悬浮层，但需为页面头部预留相应 padding，避免遮挡。
- 若必须使用系统 toolbar，则接受其带状区域，并让工具栏背景与内容背景一致，减少“多一条”的视觉感。