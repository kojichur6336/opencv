# Touch 功能接口文档

---
## 1. `Touch.tap()`

### 1.1 接口说明

`Touch.tap(x, y, [duration])` 用于 **在指定坐标执行一次完整点击**（按下并弹起）。`duration` 表示按下与弹起之间的时间间隔，单位毫秒，默认 30ms。

---

### 1.2 参数说明

| 参数位置 | 类型   | 是否必选 | 中文说明                 | 示例 |
|----------|--------|----------|--------------------------|------|
| 第 1 个  | number | 是       | 点击坐标 x               | `320` |
| 第 2 个  | number | 是       | 点击坐标 y               | `640` |
| 第 3 个  | number | 否       | 按下到弹起间隔（毫秒）   | `50` |

---

### 1.3 返回值说明

该接口 **无返回值**。

---

### 1.4 Lua 调用示例

```lua
-- 不传 duration，使用默认 30ms
Touch.tap(320, 640)
```

```lua
-- 显式指定 duration
Touch.tap(320, 640, 60)
```

---
## 2. `Touch.doubleTap()`

### 1.1 接口说明

`Touch.doubleTap(x, y)` 用于 **在指定坐标执行双击动作**。

---

### 1.2 参数说明

| 参数位置 | 类型   | 是否必选 | 中文说明 | 示例 |
|----------|--------|----------|----------|------|
| 第 1 个  | number | 是       | 点击坐标 x | `200` |
| 第 2 个  | number | 是       | 点击坐标 y | `400` |

---

### 1.3 返回值说明

该接口 **无返回值**。

---

### 1.4 Lua 调用示例

```lua
Touch.doubleTap(200, 400)
```

---
## 3. `Touch.longPress()`

### 1.1 接口说明

`Touch.longPress(x, y, [duration])` 用于 **在指定坐标按下并保持一段时间后抬起**。`duration` 为按住时间，单位毫秒，默认 2000ms。

---

### 1.2 参数说明

| 参数位置 | 类型   | 是否必选 | 中文说明               | 示例 |
|----------|--------|----------|------------------------|------|
| 第 1 个  | number | 是       | 坐标 x                 | `300` |
| 第 2 个  | number | 是       | 坐标 y                 | `500` |
| 第 3 个  | number | 否       | 按住时间（毫秒）       | `1500` |

---

### 1.3 返回值说明

该接口 **无返回值**。

---

### 1.4 Lua 调用示例

```lua
-- 使用默认 2000ms
Touch.longPress(300, 500)
```

```lua
-- 指定按住时间
Touch.longPress(300, 500, 1200)
```

---
## 4. `Touch.zoom()`

### 1.1 接口说明

`Touch.zoom(x, y, w, h, scale, [angle], [duration])` 用于 **模拟双指从中心向边缘张开进行放大**。`scale` 建议大于 1.0，`angle` 为旋转角度（弧度），`duration` 为动作持续时间（秒）。

---

### 1.2 参数说明

| 参数位置 | 类型   | 是否必选 | 中文说明                 | 示例 |
|----------|--------|----------|--------------------------|------|
| 第 1 个  | number | 是       | 区域左上角 x             | `0` |
| 第 2 个  | number | 是       | 区域左上角 y             | `0` |
| 第 3 个  | number | 是       | 区域宽度 w               | `sw` |
| 第 4 个  | number | 是       | 区域高度 h               | `sh` |
| 第 5 个  | number | 是       | 缩放比例（建议 > 1.0）   | `2.0` |
| 第 6 个  | number | 否       | 旋转角度（弧度）         | `0.0` |
| 第 7 个  | number | 否       | 动作持续时间（秒）       | `0.5` |

---

### 1.3 返回值说明

该接口 **无返回值**。

---

### 1.4 Lua 调用示例

```lua
-- 使用 Device.width / Device.height
local sw = Device.width()
local sh = Device.height()
Touch.zoom(0, 0, sw, sh, 2.0)
```

```lua
-- 指定角度与持续时间
local sw, sh = Device.size()
Touch.zoom(0, 0, sw, sh, 1.8, 0.0, 0.6)
```

---
## 5. `Touch.pinch()`

### 1.1 接口说明

`Touch.pinch(x, y, w, h, scale, [angle], [duration])` 用于 **模拟双指向中心靠拢进行缩小**。`scale` 建议小于 1.0，`angle` 为旋转角度（弧度），`duration` 为动作持续时间（秒）。

---

### 1.2 参数说明

| 参数位置 | 类型   | 是否必选 | 中文说明                 | 示例 |
|----------|--------|----------|--------------------------|------|
| 第 1 个  | number | 是       | 区域左上角 x             | `0` |
| 第 2 个  | number | 是       | 区域左上角 y             | `0` |
| 第 3 个  | number | 是       | 区域宽度 w               | `sw` |
| 第 4 个  | number | 是       | 区域高度 h               | `sh` |
| 第 5 个  | number | 是       | 缩放比例（建议 < 1.0）   | `0.6` |
| 第 6 个  | number | 否       | 旋转角度（弧度）         | `0.0` |
| 第 7 个  | number | 否       | 动作持续时间（秒）       | `0.5` |

---

### 1.3 返回值说明

该接口 **无返回值**。

---

### 1.4 Lua 调用示例

```lua
-- 使用 Device.width / Device.height
local sw = Device.width()
local sh = Device.height()
Touch.pinch(0, 0, sw, sh, 0.6)
```

```lua
-- 指定角度与持续时间
local sw, sh = Device.size()
Touch.pinch(0, 0, sw, sh, 0.5, 0.0, 0.5)
```

---
## 6. `Touch.down()`

### 1.1 接口说明

`Touch.down(fingerId, x, y, [mask])` 用于 **锁定指定手指 ID 并执行按下**。该操作为静态按下，不返回流对象。

---

### 1.2 参数说明

| 参数位置 | 类型    | 是否必选 | 中文说明                 | 示例 |
|----------|---------|----------|--------------------------|------|
| 第 1 个  | integer | 是       | 手指 ID（必须非 0）      | `1` |
| 第 2 个  | number  | 是       | 按下坐标 x               | `300` |
| 第 3 个  | number  | 是       | 按下坐标 y               | `600` |
| 第 4 个  | integer | 否       | 额外 HID 标志位          | `0` |

---

### 1.3 返回值说明

该接口 **无返回值**。

---

### 1.4 Lua 调用示例

```lua
-- down/move/up 成组示例：画一个圆
local sw, sh = Device.size()
local cx = sw * 0.5
local cy = sh * 0.5
local r  = math.min(sw, sh) * 0.25

local fingerId = 1
local steps = 60

Touch.down(fingerId, cx + r, cy)

for i = 1, steps do
    local t = (i / steps) * (2 * math.pi)
    local x = cx + r * math.cos(t)
    local y = cy + r * math.sin(t)
    Touch.move(fingerId, x, y)
end

Touch.up(fingerId)
```

---
## 7. `Touch.move()`

### 1.1 接口说明

`Touch.move(fingerId, x, y, [pressure], [twist], [mask])` 用于 **将指定手指 ID 立即移动到目标坐标**。该操作为瞬时移动，不带平滑插值。

---

### 1.2 参数说明

| 参数位置 | 类型    | 是否必选 | 中文说明                     | 示例 |
|----------|---------|----------|------------------------------|------|
| 第 1 个  | integer | 是       | 手指 ID（必须非 0）          | `1` |
| 第 2 个  | number  | 是       | 目标坐标 x                   | `350` |
| 第 3 个  | number  | 是       | 目标坐标 y                   | `650` |
| 第 4 个  | number  | 否       | 压力值 0~10000               | `5000` |
| 第 5 个  | number  | 否       | 扭转角 0~100                 | `10` |
| 第 6 个  | integer | 否       | 覆盖标志位                   | `0` |

---

### 1.3 返回值说明

该接口 **无返回值**。

---

### 1.4 Lua 调用示例

```lua
-- down/move/up 成组示例：五指“梅花桩”同时按下并轻微移动
local sw, sh = Device.size()
local cx = sw * 0.5
local cy = sh * 0.5
local d  = math.min(sw, sh) * 0.18

local points = {
    {cx, cy},                 -- 中心
    {cx - d, cy - d},         -- 左上
    {cx + d, cy - d},         -- 右上
    {cx - d, cy + d},         -- 左下
    {cx + d, cy + d}          -- 右下
}

-- 按下
for i = 1, 5 do
    Touch.down(i, points[i][1], points[i][2])
end

-- 同步微移
for i = 1, 5 do
    Touch.move(i, points[i][1] + 10, points[i][2] + 10)
end

-- 抬起
for i = 1, 5 do
    Touch.up(i)
end
```

---
## 8. `Touch.up()`

### 1.1 接口说明

`Touch.up(fingerId, [x], [y], [mask])` 用于 **立即抬起指定 ID 的手指并释放资源**。若未提供坐标，则使用该手指最后记录的位置。

---

### 1.2 参数说明

| 参数位置 | 类型    | 是否必选 | 中文说明                       | 示例 |
|----------|---------|----------|--------------------------------|------|
| 第 1 个  | integer | 是       | 手指 ID                         | `1` |
| 第 2 个  | number  | 否       | 抬起坐标 x                      | `360` |
| 第 3 个  | number  | 否       | 抬起坐标 y                      | `660` |
| 第 4 个  | integer | 否       | 覆盖标志位                      | `0` |

---

### 1.3 返回值说明

该接口 **无返回值**。

---

### 1.4 Lua 调用示例

```lua
-- down/move/up 成组示例：画一个矩形
local sw, sh = Device.size()
local left   = sw * 0.2
local right  = sw * 0.8
local top    = sh * 0.3
local bottom = sh * 0.7

local fingerId = 1

Touch.down(fingerId, left, top)
Touch.move(fingerId, right, top)
Touch.move(fingerId, right, bottom)
Touch.move(fingerId, left, bottom)
Touch.move(fingerId, left, top)
Touch.up(fingerId)
```

---
## 9. `Touch.swipe()`

### 1.1 接口说明

`Touch.swipe(x1, y1, x2, y2, duration)` 用于 **从起点沿直线匀速滑动到终点**。该操作为同步阻塞，直到划动完成才继续执行下一行脚本。

---

### 1.2 参数说明

| 参数位置 | 类型   | 是否必选 | 中文说明                 | 示例 |
|----------|--------|----------|--------------------------|------|
| 第 1 个  | number | 是       | 起点坐标 x1              | `100` |
| 第 2 个  | number | 是       | 起点坐标 y1              | `300` |
| 第 3 个  | number | 是       | 终点坐标 x2              | `100` |
| 第 4 个  | number | 是       | 终点坐标 y2              | `900` |
| 第 5 个  | number | 是       | 划动持续时间（秒）       | `0.3` |

---

### 1.3 返回值说明

该接口 **无返回值**。

---

### 1.4 Lua 调用示例

```lua
local sw = Device.width()
local sh = Device.height()

-- 左滑（从右向左）
Touch.swipe(sw * 0.8, sh * 0.5, sw * 0.2, sh * 0.5, 0.3)
```

```lua
local sw, sh = Device.size()

-- 右滑（从左向右）
Touch.swipe(sw * 0.2, sh * 0.5, sw * 0.8, sh * 0.5, 0.3)
```

```lua
local sw = Device.width()
local sh = Device.height()

-- 上滑（从下向上）
Touch.swipe(sw * 0.5, sh * 0.8, sw * 0.5, sh * 0.2, 0.3)
```

```lua
local sw, sh = Device.size()

-- 下滑（从上向下）
Touch.swipe(sw * 0.5, sh * 0.2, sw * 0.5, sh * 0.8, 0.3)
```

---
## 10. `Touch.swipeCurve()`

### 1.1 接口说明

`Touch.swipeCurve(x1, y1, x2, y2, duration)` 用于 **从起点沿平滑曲线滑动到终点**，带有自然加减速效果。该操作为同步阻塞。

---

### 1.2 参数说明

| 参数位置 | 类型   | 是否必选 | 中文说明                 | 示例 |
|----------|--------|----------|--------------------------|------|
| 第 1 个  | number | 是       | 起点坐标 x1              | `120` |
| 第 2 个  | number | 是       | 起点坐标 y1              | `320` |
| 第 3 个  | number | 是       | 终点坐标 x2              | `260` |
| 第 4 个  | number | 是       | 终点坐标 y2              | `860` |
| 第 5 个  | number | 是       | 划动持续时间（秒）       | `0.4` |

---

### 1.3 返回值说明

该接口 **无返回值**。

---

### 1.4 Lua 调用示例

```lua
local sw = Device.width()
local sh = Device.height()

-- 曲线左滑
Touch.swipeCurve(sw * 0.8, sh * 0.5, sw * 0.2, sh * 0.5, 0.4)
```

```lua
local sw, sh = Device.size()

-- 曲线上滑
Touch.swipeCurve(sw * 0.5, sh * 0.8, sw * 0.5, sh * 0.2, 0.4)
```

---

## 11. `Touch.shouldShowTouches()`

### 1.1 接口说明

`Touch.shouldShowTouches(enable)` 用于 **配置模拟点击的可视化反馈开关**。开启后在系统顶层渲染实时触摸指示器，便于调试与坐标校验；关闭后立即隐藏并清理所有指示器,这个最好用于调试阶段.

---

### 1.2 参数说明

| 参数位置 | 类型    | 是否必选 | 中文说明                         | 示例 |
|----------|---------|----------|----------------------------------|------|
| 第 1 个  | boolean | 是       | 是否启用触摸指示器渲染           | `true` |

---

### 1.3 返回值说明

该接口 **无返回值**。

---

### 1.4 Lua 调用示例

```lua
-- 开启触控可视化
Touch.shouldShowTouches(true)
```

```lua
-- 关闭触控可视化
Touch.shouldShowTouches(false)
```

---