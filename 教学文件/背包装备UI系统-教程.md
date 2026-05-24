# 教程：背包与装备系统 + UI 框架

## 架构概览

本系统分三层：**数据层** → **管理单例** → **UI层**

```
ItemData (.tres 资源)         → 物品的数据表
    ↓
InventoryManager (Autoload)   → 背包数组 + 装备字典，处理装卸逻辑
    ↓
    ├─── InventoryUI (面板)     → B键开关
    │    ├─── EquipmentSlotUI ×3（武器/护甲/电池）
    │    └─── SlotUI ×16（背包格子）
    └─── 信号驱动刷新
```

**交互流程：**
- 点击背包中物品 → 自动装到对应装备槽（武器→武器槽，护甲→护甲槽，电池→电池槽）
- 双击已装备物品 → 卸下回到背包
- B 键 → 切换背包面板显示/隐藏

**文件清单：**

| 文件 | 作用 |
|------|------|
| `scripts/item_data.gd` | 物品数据资源类 |
| `scripts/inventory_manager.gd` | 背包/装备管理单例 |
| `resource/equipment/pickaxe.tres` | 矿稿物品数据 |
| `scenes/ui/slot_ui.tscn` | 背包格子组件 |
| `scenes/ui/equipment_slot_ui.tscn` | 装备槽组件 |
| `scenes/ui/inventory_ui.tscn` | 背包主面板 |
| `scenes/ui/inventory_ui.gd` | 面板控制脚本 |

---

## 第一步：创建项目目录结构

在 FileSystem 面板中新建文件夹：
- 右键项目根目录 → **新建 → 文件夹** → 命名为 `ui`（放到 `scenes/ui/` 下）

> 实际路径：右键 `scenes` → 新建文件夹 → `ui`

---

## 第二步：创建物品数据资源类（ItemData）

**2.1 新建脚本**

1. 右键 `scripts` 文件夹 → **新建 → 脚本...**
2. 配置：
   - **继承**：`Resource`
   - **类名**：`ItemData`
   - **路径**：`res://scripts/item_data.gd`
3. 点击 **创建**

**2.2 编写代码**

打开 `scripts/item_data.gd`，输入：

```gdscript
class_name ItemData
extends Resource

enum ItemType { WEAPON, ARMOR, BATTERY, CONSUMABLE }

@export var item_name: String = ""
@export var item_type: ItemType = ItemType.WEAPON
@export var description: String = ""
@export var icon_color: Color = Color.WHITE
@export var icon: Texture2D

# 武器属性
@export var attack: int = 1  # 攻击力
@export var attack_speed: float = 1.0  # 攻速
```

> `icon` 字段用于存放 PNG 贴图。后续有新物品时只需新建 .tres 并设置 icon 即可。

---

## 第三步：创建矿稿物品资源

**3.1 创建 .tres 文件**

1. 右键 `resource/equipment` 文件夹 → **新建 → 资源...**
2. 搜索 `ItemData`，选中 → 点击 **创建**
3. 命名为 `pickaxe.tres`，保存

**3.2 填写属性**

选中 `pickaxe.tres`，在右侧 **检查器** 中填写：

| 属性 | 值 |
|------|-----|
| Item Name | `矿稿` |
| Item Type | `WEAPON` |
| Description | `一把趁手的矿稿，能敲碎大部分矿石` |
| Icon Color | 选一个灰色/银色 |
| Attac | `5` |
| Attack Speed | `1.2` |
| Icon | 加载 `pick_axe.png` |

> 后续再加护甲和电池的 .tres 资源，操作完全一样。

---

## 第四步：创建 InventoryManager 自动加载单例

**4.1 新建脚本**

1. 右键 `scripts` 文件夹 → **新建 → 脚本...**
2. 配置：
   - **继承**：`Node`
   - **类名**：留空（自动加载不需要 class_name）
   - **路径**：`res://scripts/inventory_manager.gd`
3. 点击 **创建**

**4.2 编写代码**

```gdscript
extends Node

# 信号：背包或装备发生变化时通知 UI 刷新
signal inventory_changed
signal equipment_changed

const BACKPACK_SIZE := 16

# 背包：存的是 ItemData，空位为 null
var backpack: Array = []
# 装备：按槽位类型存储
var equipment: Dictionary = {
	"weapon": null,
	"armor": null,
	"battery": null
}


func _ready() -> void:
	backpack.resize(BACKPACK_SIZE)
	# 初始测试：放一个矿稿进背包
	add_item(load("res://resource/equipment/pickaxe.tres"))


func add_item(item: ItemData) -> bool:
	for i in range(BACKPACK_SIZE):
		if backpack[i] == null:
			backpack[i] = item
			inventory_changed.emit()
			return true
	return false  # 背包已满


func remove_item(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < BACKPACK_SIZE:
		backpack[slot_index] = null
		inventory_changed.emit()


func equip(slot_index: int) -> void:
	var item := backpack[slot_index] as ItemData
	if item == null:
		return

	# 确定装备槽位类型
	var slot_key := _get_equip_slot(item.item_type)
	if slot_key == "":
		return

	# 如果该槽位已有装备，先换回背包空位（不走 add_item，避免重复发信号）
	if equipment[slot_key] != null:
		for i in range(BACKPACK_SIZE):
			if backpack[i] == null:
				backpack[i] = equipment[slot_key]
				break

	# 装备新物品
	equipment[slot_key] = item
	backpack[slot_index] = null

	inventory_changed.emit()
	equipment_changed.emit()


func unequip(slot_key: String) -> void:
	var item := equipment[slot_key] as ItemData
	if item == null:
		return

	if not add_item(item):
		return  # 背包满，无法卸下

	equipment[slot_key] = null
	equipment_changed.emit()
	# add_item 已发送 inventory_changed，这里不重复发


func _get_equip_slot(type: ItemData.ItemType) -> String:
	match type:
		ItemData.ItemType.WEAPON:
			return "weapon"
		ItemData.ItemType.ARMOR:
			return "armor"
		ItemData.ItemType.BATTERY:
			return "battery"
	return ""
```

**4.3 注册为自动加载**

1. 菜单 **项目 → 项目设置...** → **自动加载** 标签页
2. **路径** → 选 `res://scripts/inventory_manager.gd`
3. **节点名称** → 保持 `InventoryManager`
4. 点击 **添加**

---

## 第五步：创建 UI 组件

> 本节 UI 场景使用 TextureRect 做图标占位，先跑通逻辑，后续再换美术素材。

---

### 5.1 背包格子组件 SlotUI

**创建场景：**

1. 右键 `scenes/ui` → **新建 → 场景**
2. 根节点选 `PanelContainer`（自带背景和边框能力）
3. 根节点改名为 `SlotUI`
4. 场景保存为 `res://scenes/ui/slot_ui.tscn`

**搭建节点：**

```
SlotUI (PanelContainer)
└── VBoxContainer
    ├── TextureRect    ← 物品图标
    └── Label          ← 物品名称
```

具体操作：
1. 选中 SlotUI 根节点，在检查器中展开 **Theme Overrides → Panel**，勾选 `panel` 并新建 `StyleBoxFlat`：
   - **Bg Color**：深灰 `#333333`
   - **Border Width**：2px，颜色 `#555555`
   - **Corner Radius**：4
2. 右键 SlotUI → 添加子节点 → `VBoxContainer`
3. 右键 VBoxContainer → 添加子节点 → `TextureRect`，命名为 `IconPlaceholder`
   - **Expand Mode**：Ignore Size（贴图不改变格子大小）
   - **Stretch Mode**：Keep Aspect Centered（等比居中缩放）
   - **Min Size**：设为 48×48
4. 右键 VBoxContainer → 添加子节点 → `Label`，命名为 `ItemName`
   - **Text**：留空（代码赋值）
   - **Horizontal Alignment**：Center
   - **Autowrap Mode**：Word
   - **Layout → Container Sizing** → 取消勾选 `Expand` 垂直，Min Size 垂直设为 20

**创建脚本：**

1. 选中 SlotUI 根节点 → 点击脚本图标 → **新建脚本**
2. **继承**：`PanelContainer`
3. **路径**：`res://scenes/ui/slot_ui.gd`

```gdscript
class_name SlotUI
extends PanelContainer

signal slot_clicked(slot_index: int)

var slot_index: int = -1


func set_item(item: ItemData) -> void:
	if item == null:
		%IconPlaceholder.texture = null
		%ItemName.text = ""
	else:
		%IconPlaceholder.texture = item.icon
		%ItemName.text = item.item_name


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		slot_clicked.emit(slot_index)
```

> 给 IconPlaceholder 和 ItemName 节点设置 `%` 唯一名称（右键节点 → **设为唯一名称(场景)** ），代码中 `%IconPlaceholder` 才能生效。

---

### 5.2 装备槽组件 EquipmentSlotUI

**创建场景：**

1. 右键 `scenes/ui` → **新建 → 场景**
2. 根节点选 `PanelContainer`，改名为 `EquipmentSlotUI`
3. 保存为 `res://scenes/ui/equipment_slot_ui.tscn`

**搭建节点：**

```
EquipmentSlotUI (PanelContainer)
└── VBoxContainer
    ├── Label          ← 槽位类型名（武器/护甲/电池）
    ├── TextureRect    ← 装备图标占位
    └── Label          ← 物品名称
```

1. 主题样式跟 SlotUI 类似，但背景色用稍深色 `#2a2a2a`，边框 `#666666`
2. TextureRect 的 Expand Mode 设为 Ignore Size，Stretch Mode 设为 Keep Aspect Centered，Min Size 设为 56×56（比背包格子略大）

**创建脚本：** `res://scenes/ui/equipment_slot_ui.gd`

```gdscript
class_name EquipmentSlotUI
extends PanelContainer

signal equip_slot_double_clicked(slot_key: String)

@export var slot_key: String = ""
@export var slot_label: String = ""


func _ready() -> void:
	%HolderName.text = slot_label


func set_equipment(item: ItemData) -> void:
	if item == null:
		%EquipmentPlaceholder.texture = null
		%ItemName.text = "空"
	else:
		%EquipmentPlaceholder.texture = item.icon
		%ItemName.text = item.item_name


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click:
		equip_slot_double_clicked.emit(slot_key)
```

---

### 5.3 背包主面板 InventoryUI

**创建场景：**

1. 右键 `scenes/ui` → **新建 → 场景**
2. 根节点选 `PanelContainer`，改名为 `InventoryUI`
3. 保存为 `res://scenes/ui/inventory_ui.tscn`

**搭建节点：**

```
InventoryUI (PanelContainer, 半透明背景)
├── MarginContainer（留边距）
│   └── VBoxContainer
│       ├── Label "装备"（标题）
│       ├── HBoxContainer "EquipmentRow"
│       │   ├── EquipmentSlotUI（武器）
│       │   ├── EquipmentSlotUI（护甲）
│       │   └── EquipmentSlotUI（电池）
│       ├── HSeparator（分割线）
│       ├── Label "背包"（标题）
│       └── GridContainer "BackpackGrid"
│           └── [16个 SlotUI]
```

操作步骤：

**5.3.1 根节点样式**

选中 InventoryUI，检查器 → Theme Overrides → Panel → 新建 StyleBoxFlat：
- **Bg Color**：`#1a1a1acc`（深色半透明）
- **Border Width**：2，颜色 `#444444`
- **Corner Radius**：8
- **Content Margin**：四边各 16

**5.3.2 布局结构**

1. 右键 InventoryUI → 添加 `MarginContainer`（用来自动留边距）
2. 右键 MarginContainer → 添加 `VBoxContainer`
3. 在 VBoxContainer 下依次添加：
   - `Label` → Text=`== 装备 ==`，Horizontal Alignment=Center
   - `HBoxContainer` → 命名为 `EquipmentRow`
   - `HSeparator`
   - `Label` → Text=`== 背包 ==`，Horizontal Alignment=Center
   - `GridContainer` → 命名为 `BackpackGrid`

**5.3.3 配置 BackpackGrid**

选中 BackpackGrid，检查器：
- **Columns**：`4`
- **Theme Overrides → Constants**：H Separation=4, V Separation=4

**5.3.4 实例化子组件**

- 把 `slot_ui.tscn` 从 FileSystem 拖到 BackpackGrid 下，拖 **16 次**（或拖一次后 Ctrl+D 复制）
- 把 `equipment_slot_ui.tscn` 从 FileSystem 拖到 EquipmentRow 下，拖 **3 次**
- 分别选中三个装备槽实例，检查器中设：
  - 第一个：Slot Key=`weapon`，Slot Label=`武器`
  - 第二个：Slot Key=`armor`，Slot Label=`护甲`
  - 第三个：Slot Key=`battery`，Slot Label=`电池`

> 如果拖入时报错或放错位置，在场景树中手动拖拽节点调整父子关系。

**5.3.5 确保场景唯一名称无误**

检查以下节点是否设置了唯一名称（节点名旁有 `%`）：
- 所有 SlotUI 实例内的 `IconPlaceholder` 和 `ItemName`
- 所有 EquipmentSlotUI 实例内的 `IconPlaceholder`、`ItemName`、`SlotLabel`
- 唯一名称在**组件场景内部**设置，不是在主面板里设

---

## 第六步：编写 InventoryUI 控制脚本

选中 InventoryUI 根节点 → 新建脚本，路径 `res://scenes/ui/inventory_ui.gd`：

```gdscript
extends PanelContainer


func _ready() -> void:
	hide()
	_refresh_all()
	InventoryManager.inventory_changed.connect(_refresh_all)
	InventoryManager.equipment_changed.connect(_refresh_all)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		visible = not visible
		if visible:
			_refresh_all()


func _refresh_all() -> void:
	_refresh_backpack()
	_refresh_equipment()


func _refresh_backpack() -> void:
	var grid := $MarginContainer/VBoxContainer/BackpackGrid
	for i in grid.get_child_count():
		var slot := grid.get_child(i) as SlotUI
		slot.slot_index = i
		if i < InventoryManager.backpack.size():
			slot.set_item(InventoryManager.backpack[i])
		if not slot.slot_clicked.is_connected(_on_slot_clicked):
			slot.slot_clicked.connect(_on_slot_clicked)


func _refresh_equipment() -> void:
	var row := $MarginContainer/VBoxContainer/EquipmentRow
	for child in row.get_children():
		var slot := child as EquipmentSlotUI
		var item := InventoryManager.equipment.get(slot.slot_key) as ItemData
		slot.set_equipment(item)
		if not slot.equip_slot_double_clicked.is_connected(_on_equip_slot_double_clicked):
			slot.equip_slot_double_clicked.connect(_on_equip_slot_double_clicked)


func _on_slot_clicked(index: int) -> void:
	InventoryManager.equip(index)


func _on_equip_slot_double_clicked(slot_key: String) -> void:
	InventoryManager.unequip(slot_key)
```

---

## 第七步：注册输入动作 + 集成到主场景

### 7.1 注册 toggle_inventory 输入

1. **项目 → 项目设置 → 输入映射** 标签页
2. 输入框输入 `toggle_inventory` → 按 **添加**
3. 点击新动作右侧的 **+** → 选择 **键** → 按 `B` 键 → 确定

### 7.2 将面板挂载到主场景

打开关卡场景（如 `scenes/main.tscn`），将 `inventory_ui.tscn` 从 FileSystem 拖入场景树。

> 如果是主关卡场景，先新建一个 `CanvasLayer` 节点（保证 UI 永远在最上层），再把 `InventoryUI` 拖到它下面。

### 7.3 运行测试

| 操作 | 预期效果 |
|------|----------|
| 按 B 键 | 背包面板打开 |
| 再按 B 键 | 背包面板关闭 |
| 面板打开时 | 背包第一格显示矿稿（色块 + "矿稿"文字） |
| 点击背包中的矿稿 | 矿稿从背包消失，武器槽显示矿稿 |
| 双击武器槽 | 矿稿卸下回到背包 |
| 装备栏三个槽 | 分别显示 "武器" "护甲" "电池" 标签 |
| 背包格 | 4列×4行，共16格 |

---

## 常见问题排查

| 现象 | 可能原因 | 解决 |
|------|---------|------|
| 按 B 没反应 | 未在输入映射中添加 `toggle_inventory` | 回到第七步 7.1 |
| 面板打开但全是空的 | `_ready()` 中 `hide()` 后 `_refresh_all()` 没执行 | 检查 InventoryUI 脚本第 4 行 |
| 点击格子报错 | SlotUI 中 `%IconPlaceholder` 未设置唯一名称 | 在 slot_ui.tscn 中右键 IconPlaceholder → 设为唯一名称 |
| 矿稿没出现在背包第一格 | InventoryManager 的 `_ready` 中 load 失败 | 确认 `resource/equipment/pickaxe.tres` 存在 |
| 装/卸后不刷新 | 信号未连接 | 检查 InventoryUI 的 `_ready()` 中 `connect` 调用 |
| 贴图溢出格子 | TextureRect 的 Expand Mode 没设为 Ignore Size | 选中 TextureRect → Expand Mode → Ignore Size |
| 找不到类型 SlotUI | slot_ui.gd 缺少 `class_name` | 在脚本第一行加 `class_name SlotUI` |
| equipment.get 类型报错 | `:=` 推到 Variant | 加 `as ItemData`：`var item := ... as ItemData` |
| equipment 字典报错 | key 大小写不一致 | 统一用小写 `"weapon"/"armor"/"battery"` |
