# 游戏代码开发方法论

> 整理于 Godot 背包系统开发过程中。这些原则不需要一次全记住——每多写一个脚本，自然会体会到几条。需要时回来翻对应的章节。

---

## 一、记忆管理：写太多记不住怎么办

这是开发过程中最实际的问题。你不缺方法论，缺的是**怎么在忘记的时候快速查回来**。

### 方法一：MCP / Claude Code（最省力）

记不清的时候直接问我，我来帮你查：

- "ItemData 有哪些属性？" → 我读 `item_data.gd` 列出 `@export`
- "equipment_slot_ui 的信号名叫什么？" → 我查脚本告诉你
- "InventoryManager 的背包变量是 Dictionary 还是 Array？" → 我读代码回答

你不用离开编辑器，也不用打断工作流。这是把记忆力卸载给工具的第一选择。

### 方法二：场景面板 + 检查器

在编辑器左侧场景面板选中一个节点，右侧检查器会列出它所有的 `@export` 变量。选中 `.tres` 资源文件同理。这是不需要读代码就能看属性的最快方式。

使用场景：你想知道一个节点有哪些可配置项（`slot_key`、`slot_label` 等），选中即看。

### 方法三：脚本编辑器的大纲面板（Outline）

打开任一 `.gd` 文件，编辑器侧栏的「大纲」面板会列出当前脚本的：

- 所有函数（`_ready`、`add_item`、`equip`...）
- 所有信号（`inventory_changed`、`equipment_changed`...）
- 所有变量（`backpack`、`equipment`...）

点击直接跳转到对应行。**这是你的代码目录，比 grep 快。**

### 方法四：Ctrl + 点击跳转定义

按住 Ctrl 点击方法名、变量名、类名，编辑器自动跳转到定义位置。

```gdscript
InventoryManager.inventory_changed.connect(_refresh_all)
#  Ctrl+点击 ↑                                Ctrl+点击 ↑
#  跳到 signal inventory_changed              跳到 func _refresh_all()
```

同一个名字被一百个地方引用，但你只需要一次 Ctrl+点击就能找到源头。

### 方法五：TODO / FIXME 标记

不是注释，是**给自己留的便条**。Godot 会自动高亮这些标记：

```gdscript
# TODO: 卸装备时需要同时移除对应的属性加成
# FIXME: 背包满了的情况下双击可能触发空槽取物品
# HACK: 暂时用 ColorRect 占位，替换贴图后删掉这段
```

在脚本编辑器底部面板 → 「待办事项」标签页，会自动收集所有脚本里的 TODO/FIXME/HACK。

---

## 二、面向对象编程（OOP）核心

### 封装 Encapsulation

**谁的数据谁管，不越界。**

```gdscript
# ❌ 坏写法：外部直接操作背包数组
InventoryManager.backpack[0] = null

# ✅ 好写法：通过方法操作
InventoryManager.remove_item(0)
```

为什么要这样：哪天改了 `backpack` 的实现（比如从 Array 改成 Dictionary），如果所有地方都直接操作数组，每处都要改。如果都通过 `add_item` / `remove_item`，只需改这两个方法内部，外面的调用者完全感知不到。

封装不是把变量藏起来，而是**对外提供稳定的行为接口，让内部的实现可以自由变化。**

### 单一职责 Single Responsibility

**一个函数/一个类只做一件事。**

判断标准：用"因为……所以……"能否一句话说清它的职责。

```gdscript
_refresh_backpack()    → "因为背包数据变了，所以要重新显示格子" ✅ 一句话说清
_refresh_equipment()   → "因为装备变了，所以要更新装备栏显示"    ✅ 一句话说清

handle_event()         → "因为事件来了……" 所以什么？说不清 → 太杂了，该拆 ❌
process_turn()         → "因为轮到我了……" 然后呢？说不清 → 做太多了 ❌
```

经验法则：**如果函数名里出现了"和"字，就该拆分。**

### 组合优于继承 Composition over Inheritance

**"有什么"胜过"是什么"。**

Godot 本身就是这个哲学的典范：`CharacterBody2D` 通过添加子节点 `CollisionShape2D`、`AnimatedSprite2D` 组合出完整角色，而不是靠层层继承。

```gdscript
# ❌ 继承：为了有背包功能创造一个 InventoryCharacter 类
class_name InventoryCharacter
extends CharacterBody2D
# 然后继承树上再加 HasHealth、CanAttack、CarriesInventory……
# 某天发现"商人也要有背包但不打架"，整棵树塌了

# ✅ 组合：把能力做成独立节点，挂上去用
# Player (CharacterBody2D)
#   ├─ CollisionShape2D        ← 碰撞
#   ├─ AnimatedSprite2D        ← 图像
#   ├─ HealthComponent         ← 血量（独立节点）
#   └─ InventoryComponent      ← 背包（独立节点）
```

---

## 三、架构模式

### 信号解耦 Signal-based Decoupling

**发送者不管谁接收，接收者不管谁发送。**

这是 Godot 最核心的设计哲学：

```gdscript
# InventoryManager 只管发信号 —— 它不知道 UI 的存在
signal inventory_changed

func add_item(item) -> bool:
    ...
    inventory_changed.emit()  # "我更新了，谁想知道谁自己知道"


# UI 面板自己连接 —— 它不知道是谁触发了变化
func _ready():
    InventoryManager.inventory_changed.connect(_refresh_all)
```

好处：
- `InventoryManager` 脱离 UI 也能独立运行和测试
- UI 换风格、换节点、换框架，数据层不动
- 多个接收者（背包面板、装备面板、快捷栏）监听同一个信号，各刷新各的

**判断标准**：一个类里如果出现了 `get_node("../../SomeUI/Panel")` 这种向上跨越多层去找其他模块的写法，就该用信号替代。

### 观察者模式 Observer Pattern

信号就是观察者模式的 Godot 实现。多个观察者监听同一个信号，信号发出，所有观察者自动更新。你不需要写循环通知。

### MVC（Model-View-Controller）

你的背包代码天然符合 MVC，理解这个分层有助于知道"新功能该写在哪"：

| 层 | 职责 | 你的代码 | 变化时的影响 |
|---|---|---|---|
| **Model** | 数据 + 核心逻辑 | `InventoryManager`（背包数组、装备字典、增删换装方法） | 改数据结构只影响这一层 |
| **View** | 纯显示 | `SlotUI`、`EquipmentSlotUI`（ColorRect、Label、文字颜色） | 换美术只改这一层 |
| **Controller** | 协调数据与显示 | InventoryUI 根节点脚本（读 Model 数据喂给 View） | 改交互逻辑只改这一层 |

**新功能的归属练习**：不加代码前先问自己——"这是数据变了？（Model）还是显示方式变了？（View）还是交互变了？（Controller）"问完就知道写在哪了。

---

## 四、编码实践原则

### 自顶向下分解 / 分治 Top-down Decomposition（Divide and Conquer）

**把复杂问题拆成更小的子问题，直到每个子问题简单到几行就能搞定。**

你的背包刷新逻辑不是一口气写完的，而是这样拆出来的：

```
_ready()
  ├─ hide()                               ← 一行，简单
  ├─ _refresh_all()                       ← 写了调用再跳去实现
  │    ├─ _refresh_backpack()             ← 再跳去实现
  │    │    └─ 遍历 16 格，调用 slot.set_item()
  │    └─ _refresh_equipment()            ← 再跳去实现
  │         └─ 遍历装备槽，调用 slot.set_equipment()
  └─ 连接信号
```

**关键原则：先写调用，后写实现。** 写 `_ready()` 时 `_refresh_all()` 还不存在？没事，先写着，用到再说。这叫 **Stub（桩）驱动**——先用桩函数占位，再回头填内容。

### DRY - Don't Repeat Yourself

**同样的逻辑不要写两遍。** 出现了两次就抽成函数，出现了三次就更该抽。

```gdscript
# ❌ 刷新装备和刷新背包各写一套遍历
func _refresh_equipment():
    for key in ["weapon", "armor", "battery"]:
        var item = InventoryManager.equipment[key]
        var slot = _find_equip_slot(key)
        slot.set_equipment(item)

func _refresh_backpack():
    for i in range(16):
        var item = InventoryManager.backpack[i]
        var slot = _find_backpack_slot(i)
        slot.set_item(item)
```

这里 `_find_equip_slot(key)` 和 `_find_backpack_slot(i)` 虽然实现不同，但"找槽 → 设数据"的模式是重复的。如果 16 个格子是用 `for` 循环统一创建的，就不需要手动写 16 遍引用。

**但注意**：DRY 的前提是"真正重复的逻辑"——不要把两个碰巧长得像但原因不同的代码强行合并。合并了反而耦合。

### KISS - Keep It Simple, Stupid

**用最简单的方案解决当前问题，不预测"未来可能需要"。**

```gdscript
# ❌ 过度设计：万一以后背包要分页呢？先留个参数
func add_item(item, page: int = 0, slot: int = -1):
    var offset = page * PAGE_SIZE
    ...

# ✅ 现在的需求就是 16 格，直接写
func add_item(item: ItemData) -> bool:
    for i in range(BACKPACK_SIZE):
        if backpack[i] == null:
            backpack[i] = item
            inventory_changed.emit()
            return true
    return false
```

等真需要分页了再改，那时候你更清楚需求，写法也更准确。提前猜的"未来需求"十个有九个猜错。

### 尽早返回 Early Return

**先过滤掉特殊情况，正常逻辑平铺。**

```gdscript
# ❌ 嵌套深，核心逻辑被缩进埋在最里面
func equip(slot_index: int) -> void:
    if slot_index >= 0 and slot_index < BACKPACK_SIZE:
        var item = backpack[slot_index]
        if item != null:
            var slot_key = _get_equip_slot(item.item_type)
            if slot_key != "":
                # 终于到核心逻辑了，已经三层缩进
                ...

# ✅ 先处理例外，核心逻辑平铺在外面
func equip(slot_index: int) -> void:
    if slot_index < 0 or slot_index >= BACKPACK_SIZE:
        return                         # 越界，不处理
    var item = backpack[slot_index]
    if item == null:
        return                         # 空槽，不处理
    var slot_key = _get_equip_slot(item.item_type)
    if slot_key == "":
        return                         # 不能装备的类型
    # ↓ 核心逻辑从这里开始平铺，一目了然
    ...
```

把 `if-return` 看成"把关"——不合格的请求在门口就挡回去，合格的才允许进来被处理。

### 命名即注释 Naming as Documentation

**好的命名让注释变得多余。**

```gdscript
# ❌ 需要注释解释每一步在做什么
# 遍历背包，找到空格子，把物品放进去，然后通知UI
for i in range(16):
    if b[i] == null:           # b 是什么？哪来的？
        b[i] = ni               # ni 又是什么？
        ic.emit()               # ic？
        return true

# ✅ 命名自己说清了一切
for slot_index in range(BACKPACK_SIZE):
    if backpack[slot_index] == null:
        backpack[slot_index] = new_item
        inventory_changed.emit()
        return true
```

要点：
- 变量名用名词：`backpack`、`slot_index`、`item_data`
- 函数名用动词开头：`add_item`、`remove_item`、`refresh_all`
- 布尔变量用 `is_` / `has_` / `can_` 开头：`is_empty`、`has_weapon`、`can_equip`
- 信号用过去式或状态变化命名：`inventory_changed`、`equipment_changed`

---

## 五、游戏开发专属模式

### 状态驱动 State-Driven

**游戏里一切变化都是状态变化，UI 只是状态的投影。**

```
玩家点击装备 →
  InventoryManager.equip(slot_index)     ← 改变状态
  → backpack / equipment 数据变了        ← 状态变化
  → signal emitted                       ← 通知发生了状态变化
  → UI._refresh_all()                    ← UI 被动响应，重新读取状态
```

核心思想：**不要手动控制画面上的每个像素，而是让画面跟随状态自动变化。** 你是"状态的管理者"，不是"像素的指挥者"。

### 数据与表现分离 Data / Display Separation

**ItemData 和 SlotUI 是完全独立的两层。**

```gdscript
# 数据层 —— 只管数据长什么样
class_name ItemData
extends Resource
@export var item_name: String
@export var icon_color: Color
@export var attack: int

# 表现层 —— 只管怎么显示数据
func set_item(item: ItemData) -> void:
    if item == null:
        %IconPlaceholder.color = Color(0.15, 0.15, 0.15, 0.5)
        %ItemName.text = ""
    else:
        %IconPlaceholder.color = item.icon_color
        %ItemName.text = item.item_name
```

好处：
- 数据结构可以独立测试（创建一个 ItemData 不需要 UI）
- 显示逻辑可独立替换（把 ColorRect 换成 TextureRect，ItemData 不用改）
- 一个数据可以同时显示在多个地方（背包里和装备栏里显示同一把剑）

### Greyboxing（灰盒占位）

**先用色块、文字、方块做完所有逻辑，最后换美术素材。**

你的教程里面用 ColorRect + Label 搭背包界面，用 icon_color 替代图标，这就是 greyboxing。这是专业游戏开发的标准做法，不是凑合。

好处：
- 美术素材可能几周后才到，代码不能等
- 先用色块跑通逻辑，发现设计问题了再改，不浪费素材
- 最终替换时只需改 View 层，逻辑全部不动

### 帧循环意识

`_process(delta)` 是每帧执行，放耗时的操作会掉帧。有变化才需要更新的逻辑用信号触发：

```gdscript
# ❌ 每帧都刷新，即使背包几小时没变
func _process(delta):
    _refresh_all()

# ✅ 只有数据真变了才刷新
InventoryManager.inventory_changed.connect(_refresh_all)
```

**经验法则**：能用 `connect` 解决的，不用 `_process`。

---

## 六、软件工程通用原则

### YAGNI - You Ain't Gonna Need It

**不要写你现在用不到的代码。**

写教程最容易犯这个：做到"显示装备"这一步，心里想着"但以后还要做拖拽卸装备、右键用物品、快捷键……"，顺手加了一堆半成品。结果后面需求变了，之前写的全删。

**只写当前这一步要的逻辑。** 等做到那一步再写，会更清楚该怎么写。

### 童子军规则 Boy Scout Rule

**每次动代码时，让它比你发现时更干净一点。**

看到拼写错误 `doubel_clicked` → 顺手改成 `double_clicked`。看到缩进不对 → 顺手对齐。看到多余的 `print` 调试 → 顺手删掉。

不需要专门抽时间"重构"。每次 30 秒的小改进，累积下来代码就不腐烂。

### 最不意外原则 Principle of Least Astonishment

**代码的行为应该符合阅读者的直觉，而不是出人意料。**

```gdscript
# ❌ 令人意外：叫 remove_item 结果什么都没删（因为索引 -1）
func remove_item(slot_index: int) -> void:
    if slot_index < 0 or slot_index >= BACKPACK_SIZE:
        return
    ...

# ✅ 不意外：越界时至少打印一个警告
func remove_item(slot_index: int) -> void:
    if slot_index < 0 or slot_index >= BACKPACK_SIZE:
        push_warning("remove_item: slot_index %d out of range" % slot_index)
        return
    ...
```

---

## 七、GDScript / Godot 特定写法习惯

### @export — 暴露接口，隐藏实现

```gdscript
@export var slot_key: String = ""       # 编辑器可见，可配置 ← 这是接口
@export var slot_label: String = ""     # 同上

var _backpack: Array = []               # 下划线开头 = 私有，外部不该直接访问
func _refresh_all() -> void:            # 下划线开头 = 内部方法
```

规则：
- `@export` = "这是给编辑器用的配置入口"
- `_` 前缀 = "这是内部实现，外部别碰"
- 无前缀的公开方法 = "这是类对外的契约，改名要三思"

### 类型声明 — 给自己画地图

```gdscript
# ❌ 不加类型，写 event. 时不知道有什么属性可用
func _gui_input(event):
    # 自动补全也帮不了你

# ✅ 加了类型，写 event. 补全就知道有哪些属性和方法
func _gui_input(event: InputEvent) -> void:
    # 自动补全弹出 InputEvent 的所有属性
```

虽然 GDScript 是动态类型，但声明类型能帮你：
- 写代码时获得准确的自动补全
- 传错类型时编辑器立即标红提醒
- 三个月后回来看代码也能看懂参数是什么

### `is` 与类型检查 — 分辨基类的多种子类

```gdscript
func _gui_input(event: InputEvent) -> void:
    # event 可能是鼠标、键盘、手柄……用 is 判断"实际是哪一种"
    if event is InputEventMouseButton:
        # 在这个 if 里面，event 就是鼠标事件
        # 可以安全使用 double_click、button_index 等专属属性
```

`InputEvent` 是基类，`InputEventMouseButton` 是子类。参数类型只能写 `InputEvent`（所有输入通用），但 `is` 能让你在运行时知道它实际上是什么，然后安全地访问子类专属属性。

### 信号声明规范

```gdscript
# 信号名用过去式或状态变化
signal inventory_changed        # 表示"背包已变化"
signal equipment_changed        # "装备已变化"
signal slot_clicked(slot_index) # "某格被点击了" — 带参数指明是哪个
```

---

## 核心速查

1. **先写调用，后写实现** — 函数还不存在？先写调用，再跳去定义
2. **一个函数做一件事** — 函数名里出现"和"字就该拆
3. **数据变了才通知 UI** — 信号连接，不用 `_process` 轮询
4. **尽早返回** — 特殊情况挡在门口，核心逻辑平铺
5. **记不清了用 MCP** — 让我帮你查，比靠自己记忆快
