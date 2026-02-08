# System 功能接口文档

---
## 1. `System.osVersion()`

### 1.1 接口说明

`System.osVersion()` 用于 **获取当前设备的 iOS 系统版本号**，返回如 `"15.0"` 或 `"16.1.2"` 的版本字符串。  
该版本号可用于系统兼容性判断。

---

### 1.2 参数说明

无需参数

---

### 1.3 返回值说明

| 返回值 | 类型   | 中文说明            | 示例     |
|--------|--------|---------------------|----------|
| 版本号 | string | 当前 iOS 版本字符串 | `"16.1.2"` |

---

### 1.4 Lua 调用示例

```lua
-- 例子1：输出系统版本
local version = System.osVersion()
Log.print('当前系统版本: ' .. tostring(version))

-- 例子2：根据版本做判断
if version and version:sub(1, 2) == "12" then
    Log.print('系统版本较旧，可能不支持部分功能')
else
    Log.print('系统版本正常')
end
```

---
## 2. `System.freeDiskSpace(path)`

### 2.1 接口说明

`System.freeDiskSpace(path)` 用于 **获取指定挂载路径的剩余可用空间**（单位：MB）。  
未传 `path` 时默认查询根分区 `/`。

---

### 2.2 参数说明

| 参数位置 | 类型   | 是否必选 | 中文说明             | 示例     |
|----------|--------|----------|----------------------|----------|
| 第 1 个  | string | 否       | 挂载路径，默认 `/`   | `"/var"` |

---

### 2.3 返回值说明

| 返回值 | 类型        | 中文说明                         | 示例    |
|--------|-------------|----------------------------------|---------|
| 空间值 | number / nil | 成功返回剩余空间（MB），失败为 nil | `10240` |

---

### 2.4 Lua 调用示例

```lua
-- 例子1：查询根分区剩余空间
local free = System.freeDiskSpace()
Log.print('根分区剩余(MB): ' .. tostring(free))

-- 例子2：空间不足提示
if free and free < 1024 then
    Log.print('剩余空间不足 1GB，请清理存储')
end
```

---
## 3. `System.totalDiskSpace(path)`

### 3.1 接口说明

`System.totalDiskSpace(path)` 用于 **获取指定挂载路径的总存储容量**（单位：MB）。  
未传 `path` 时默认查询根分区 `/`。  
在越狱环境下，查询 `/var` 可获取设备真实物理存储总量。

---

### 3.2 参数说明

| 参数位置 | 类型   | 是否必选 | 中文说明             | 示例     |
|----------|--------|----------|----------------------|----------|
| 第 1 个  | string | 否       | 挂载路径，默认 `/`   | `"/var"` |

---

### 3.3 返回值说明

| 返回值 | 类型   | 中文说明           | 示例     |
|--------|--------|--------------------|----------|
| 容量值 | number | 总存储容量（MB）   | `131072` |

---

### 3.4 Lua 调用示例

```lua
-- 例子1：查询总容量
local total = System.totalDiskSpace()
Log.print('总容量(MB): ' .. tostring(total))

-- 例子2：换算成 GB
if total then
    local gb = math.floor(total / 1024)
    Log.print('约 ' .. tostring(gb) .. ' GB')
end
```

---
## 4. `System.lockScreen()`

### 4.1 接口说明

`System.lockScreen()` 用于 **立即关闭屏幕并进入锁定状态**。  
该操作执行成功后不返回值。

---

### 4.2 参数说明

无需参数

---

### 4.3 返回值说明

该接口 **无返回值**。

---

### 4.4 Lua 调用示例

```lua
-- 例子1：延迟锁屏
Log.print('5 秒后锁屏...')
Time.sleep(5)
System.lockScreen()

-- 例子2：立即锁屏
System.lockScreen()
```

---
## 5. `System.unlockScreen(passcode)`

### 5.1 接口说明

`System.unlockScreen(passcode)` 用于 **唤醒屏幕并尝试解锁**。  
- 传入密码时，使用密码尝试解锁  
- 不传参数时，仅执行唤醒（或尝试无密码解锁）  
该操作执行成功后不返回值。

---

### 5.2 参数说明

| 参数位置 | 类型   | 是否必选 | 中文说明   | 示例        |
|----------|--------|----------|------------|-------------|
| 第 1 个  | string | 否       | 解锁密码   | `"123456"`  |

---

### 5.3 返回值说明

该接口 **无返回值**。

---

### 5.4 Lua 调用示例

```lua
-- 例子1：仅唤醒
System.unlockScreen()

-- 例子2：使用密码解锁
System.unlockScreen('123456')
```

---
## 6. `System.isScreenLocked()`

### 6.1 接口说明

`System.isScreenLocked()` 用于 **获取当前屏幕锁定状态**。

---

### 6.2 参数说明

无需参数

---

### 6.3 返回值说明

| 返回值 | 类型    | 中文说明         | 示例  |
|--------|---------|------------------|-------|
| 状态值 | boolean | 是否处于锁定状态 | `true` |

---

### 6.4 Lua 调用示例

```lua
-- 例子1：输出锁定状态
local locked = System.isScreenLocked()
Log.print('屏幕是否锁定: ' .. tostring(locked))

-- 例子2：锁定则解锁
if System.isScreenLocked() then
    System.unlockScreen()
end
```

---
## 7. `System.brightness(value)`

### 7.1 接口说明

`System.brightness(value)` 用于 **获取或设置屏幕亮度**（范围 0.0~1.0）。  
该接口采用 **getter / setter 合并设计**：  
- **不传参数**：获取当前亮度  
- **传入亮度值**：设置亮度，不返回值  

---

### 7.2 参数说明

| 参数位置 | 类型   | 是否必选 | 中文说明           | 示例 |
|----------|--------|----------|--------------------|------|
| 第 1 个  | number | 否       | 亮度值（0.0~1.0）  | `0.5` |

---

### 7.3 返回值说明

| 调用形式                   | 返回值个数 | 返回类型 | 中文说明     |
|----------------------------|------------|----------|--------------|
| `System.brightness()`      | 1          | number   | 当前亮度值   |
| `System.brightness(value)` | 0          | 无       | 无返回值     |

---

### 7.4 Lua 调用示例

```lua
-- 例子1：读取当前亮度
local b = System.brightness()
Log.print('当前亮度: ' .. tostring(b))

-- 例子2：设置亮度
System.brightness(0.6)
```

---
## 8. `System.orientationLocked(value)`

### 8.1 接口说明

`System.orientationLocked(value)` 用于 **获取或设置屏幕旋转锁定状态**。  
该接口采用 **getter / setter 合并设计**：  
- **不传参数**：获取当前锁定状态  
- **传入布尔值**：设置锁定状态，不返回值  

---

### 8.2 参数说明

| 参数位置 | 类型    | 是否必选 | 中文说明   | 示例   |
|----------|---------|----------|------------|--------|
| 第 1 个  | boolean | 否       | 是否锁定   | `true` |

---

### 8.3 返回值说明

| 调用形式                         | 返回值个数 | 返回类型 | 中文说明     |
|----------------------------------|------------|----------|--------------|
| `System.orientationLocked()`     | 1          | boolean  | 当前锁定状态 |
| `System.orientationLocked(value)`| 0          | 无       | 无返回值     |

---

### 8.4 Lua 调用示例

```lua
-- 例子1：查询锁定状态
local locked = System.orientationLocked()
Log.print('旋转锁定: ' .. tostring(locked))

-- 例子2：开启锁定
System.orientationLocked(true)
```

---
## 9. `System.autoLockTime(seconds)`

### 9.1 接口说明

`System.autoLockTime(seconds)` 用于 **获取或设置自动锁定时间**（单位：秒）。  
该接口采用 **getter / setter 合并设计**：  
- **不传参数**：获取当前自动锁定时间  
- **传入秒数**：设置自动锁定时间  

逻辑约束：  
1. 若设置值 < 30 秒（且不为 -1），将自动修正为 30 秒  
2. 若设置值 > 4294967295，将自动修正为 -1（永久不锁定）

---

### 9.2 参数说明

| 参数位置 | 类型   | 是否必选 | 中文说明                     | 示例 |
|----------|--------|----------|------------------------------|------|
| 第 1 个  | number | 否       | 锁定时间（秒），-1 表示永久不锁定 | `120` |

---

### 9.3 返回值说明

| 调用形式                        | 返回值个数 | 返回类型 | 中文说明           |
|---------------------------------|------------|----------|--------------------|
| `System.autoLockTime()`         | 1          | number   | 当前锁定时间（秒） |
| `System.autoLockTime(seconds)`  | 0          | 无       | 无返回值           |

---

### 9.4 Lua 调用示例

```lua
-- 例子1：读取当前时间
local t = System.autoLockTime()
Log.print('当前自动锁定时间: ' .. tostring(t))

-- 例子2：设置为 120 秒
System.autoLockTime(120)
```

---
## 10. `System.takeScreenshot()`

### 10.1 接口说明

`System.takeScreenshot()` 用于 **捕获当前屏幕截图并保存到相册**。

---

### 10.2 参数说明

无需参数

---

### 10.3 返回值说明

该接口 **无返回值**。

---

### 10.4 Lua 调用示例

```lua
-- 例子1：直接截图
System.takeScreenshot()

-- 例子2：延迟 1 秒截图
Time.sleep(1)
System.takeScreenshot()
```

---
## 11. `System.wifi(value)`

### 11.1 接口说明

`System.wifi(value)` 用于 **获取或设置 Wi‑Fi 开关状态**。  
该接口采用 **getter / setter 合并设计**：  
- **不传参数**：获取当前状态  
- **传入布尔值**：设置状态，不返回值  

---

### 11.2 参数说明

| 参数位置 | 类型    | 是否必选 | 中文说明       | 示例   |
|----------|---------|----------|----------------|--------|
| 第 1 个  | boolean | 否       | Wi‑Fi 开关状态 | `true` |

---

### 11.3 返回值说明

| 调用形式             | 返回值个数 | 返回类型 | 中文说明   |
|----------------------|------------|----------|------------|
| `System.wifi()`      | 1          | boolean  | 当前状态   |
| `System.wifi(value)` | 0          | 无       | 无返回值   |

---

### 11.4 Lua 调用示例

```lua
-- 例子1：读取当前状态
local on = System.wifi()
Log.print('Wi‑Fi 状态: ' .. tostring(on))

-- 例子2：设置为打开
System.wifi(true)
```

---
## 12. `System.cellularData(value)`

### 12.1 接口说明

`System.cellularData(value)` 用于 **获取或设置蜂窝数据开关状态**。  
该接口采用 **getter / setter 合并设计**：  
- **不传参数**：获取当前状态  
- **传入布尔值**：设置状态，不返回值  

---

### 12.2 参数说明

| 参数位置 | 类型    | 是否必选 | 中文说明         | 示例   |
|----------|---------|----------|------------------|--------|
| 第 1 个  | boolean | 否       | 蜂窝数据开关状态 | `true` |

---

### 12.3 返回值说明

| 调用形式                   | 返回值个数 | 返回类型 | 中文说明   |
|----------------------------|------------|----------|------------|
| `System.cellularData()`    | 1          | boolean  | 当前状态   |
| `System.cellularData(value)` | 0        | 无       | 无返回值   |

---

### 12.4 Lua 调用示例

```lua
-- 例子1：读取蜂窝数据状态
local on = System.cellularData()
Log.print('蜂窝数据: ' .. tostring(on))

-- 例子2：关闭蜂窝数据
System.cellularData(false)
```

---
## 13. `System.bluetooth(value)`

### 13.1 接口说明

`System.bluetooth(value)` 用于 **获取或设置蓝牙开关状态**。  
该接口采用 **getter / setter 合并设计**：  
- **不传参数**：获取当前状态  
- **传入布尔值**：设置状态，不返回值  

---

### 13.2 参数说明

| 参数位置 | 类型    | 是否必选 | 中文说明       | 示例   |
|----------|---------|----------|----------------|--------|
| 第 1 个  | boolean | 否       | 蓝牙开关状态   | `true` |

---

### 13.3 返回值说明

| 调用形式               | 返回值个数 | 返回类型 | 中文说明   |
|------------------------|------------|----------|------------|
| `System.bluetooth()`   | 1          | boolean  | 当前状态   |
| `System.bluetooth(value)` | 0      | 无       | 无返回值   |

---

### 13.4 Lua 调用示例

```lua
-- 例子1：读取蓝牙状态
local on = System.bluetooth()
Log.print('蓝牙状态: ' .. tostring(on))

-- 例子2：开启蓝牙
System.bluetooth(true)
```

---
## 14. `System.airplane(value)`

### 14.1 接口说明

`System.airplane(value)` 用于 **获取或设置飞行模式状态**。  
该接口采用 **getter / setter 合并设计**：  
- **不传参数**：获取当前状态  
- **传入布尔值**：设置状态，不返回值  

---

### 14.2 参数说明

| 参数位置 | 类型    | 是否必选 | 中文说明     | 示例   |
|----------|---------|----------|--------------|--------|
| 第 1 个  | boolean | 否       | 飞行模式状态 | `true` |

---

### 14.3 返回值说明

| 调用形式             | 返回值个数 | 返回类型 | 中文说明 |
|----------------------|------------|----------|----------|
| `System.airplane()`  | 1          | boolean  | 当前状态 |
| `System.airplane(value)` | 0      | 无       | 无返回值 |

---

### 14.4 Lua 调用示例

```lua
-- 例子1：读取飞行模式
local on = System.airplane()
Log.print('飞行模式: ' .. tostring(on))

-- 例子2：开启飞行模式
System.airplane(true)
```

---
## 15. `System.airDrop(mode)`

### 15.1 接口说明

`System.airDrop(mode)` 用于 **获取或设置 AirDrop 发现模式**。  
该接口采用 **getter / setter 合并设计**：  
- **不传参数**：获取当前模式  
- **传入模式值**：设置模式并返回当前模式  

模式定义：  
- `0`：接收关闭  
- `1`：仅限联系人  
- `2`：所有人  

---

### 15.2 参数说明

| 参数位置 | 类型   | 是否必选 | 中文说明       | 示例 |
|----------|--------|----------|----------------|------|
| 第 1 个  | number | 否       | 发现模式（0/1/2） | `2` |

---

### 15.3 返回值说明

| 调用形式           | 返回值个数 | 返回类型 | 中文说明       |
|--------------------|------------|----------|----------------|
| `System.airDrop()` | 1          | number   | 当前发现模式   |
| `System.airDrop(mode)` | 1      | number   | 设置后的模式   |

---

### 15.4 Lua 调用示例

```lua
-- 例子1：读取当前模式
local mode = System.airDrop()
Log.print('AirDrop 模式: ' .. tostring(mode))

-- 例子2：设置为所有人
local newMode = System.airDrop(2)
Log.print('设置后模式: ' .. tostring(newMode))
```

---
## 16. `System.respring()`

### 16.1 接口说明

`System.respring()` 用于 **重启 SpringBoard（软重启）**，不会导致越狱失效。

---

### 16.2 参数说明

无需参数

---

### 16.3 返回值说明

该接口 **无返回值**。

---

### 16.4 Lua 调用示例

```lua
-- 例子1：直接重启
System.respring()

-- 例子2：延迟重启
Time.sleep(2)
System.respring()
```

---
## 17. `System.assistiveTouch(value)`

### 17.1 接口说明

`System.assistiveTouch(value)` 用于 **获取或设置辅助触控（AssistiveTouch）状态**。  
该接口采用 **getter / setter 合并设计**：  
- **不传参数**：获取当前状态  
- **传入布尔值**：设置状态，不返回值  

---

### 17.2 参数说明

| 参数位置 | 类型    | 是否必选 | 中文说明           | 示例   |
|----------|---------|----------|--------------------|--------|
| 第 1 个  | boolean | 否       | AssistiveTouch 状态 | `true` |

---

### 17.3 返回值说明

| 调用形式                   | 返回值个数 | 返回类型 | 中文说明 |
|----------------------------|------------|----------|----------|
| `System.assistiveTouch()`  | 1          | boolean  | 当前状态 |
| `System.assistiveTouch(value)` | 0      | 无       | 无返回值 |

---

### 17.4 Lua 调用示例

```lua
-- 例子1：读取当前状态
local on = System.assistiveTouch()
Log.print('AssistiveTouch: ' .. tostring(on))

-- 例子2：开启
System.assistiveTouch(true)
```

---
## 18. `System.reduceMotion(value)`

### 18.1 接口说明

`System.reduceMotion(value)` 用于 **获取或设置减弱动态效果状态**。  
该接口采用 **getter / setter 合并设计**：  
- **不传参数**：获取当前状态  
- **传入布尔值**：设置状态，不返回值  

---

### 18.2 参数说明

| 参数位置 | 类型    | 是否必选 | 中文说明       | 示例   |
|----------|---------|----------|----------------|--------|
| 第 1 个  | boolean | 否       | 减弱动态效果状态 | `true` |

---

### 18.3 返回值说明

| 调用形式                 | 返回值个数 | 返回类型 | 中文说明 |
|--------------------------|------------|----------|----------|
| `System.reduceMotion()`  | 1          | boolean  | 当前状态 |
| `System.reduceMotion(value)` | 0      | 无       | 无返回值 |

---

### 18.4 Lua 调用示例

```lua
-- 例子1：读取当前状态
local on = System.reduceMotion()
Log.print('减弱动态效果: ' .. tostring(on))

-- 例子2：开启
System.reduceMotion(true)
```

---
## 19. `System.safariRemoteInspector(value)`

### 19.1 接口说明

`System.safariRemoteInspector(value)` 用于 **获取或设置 Safari 远程调试状态**。  
该接口采用 **getter / setter 合并设计**：  
- **不传参数**：获取当前状态  
- **传入布尔值**：设置状态并返回新状态  

---

### 19.2 参数说明

| 参数位置 | 类型    | 是否必选 | 中文说明             | 示例   |
|----------|---------|----------|----------------------|--------|
| 第 1 个  | boolean | 否       | 远程调试开关状态     | `true` |

---

### 19.3 返回值说明

| 调用形式                         | 返回值个数 | 返回类型 | 中文说明     |
|----------------------------------|------------|----------|--------------|
| `System.safariRemoteInspector()` | 1          | boolean  | 当前状态     |
| `System.safariRemoteInspector(value)` | 1      | boolean  | 设置后的状态 |

---

### 19.4 Lua 调用示例

```lua
-- 例子1：读取状态
local on = System.safariRemoteInspector()
Log.print('远程调试: ' .. tostring(on))

-- 例子2：开启并读取返回值
local newState = System.safariRemoteInspector(true)
Log.print('设置后状态: ' .. tostring(newState))
```

---
## 20. `System.shell(command, shouldWait)`

### 20.1 接口说明

`System.shell(command, shouldWait)` 用于 **执行 Shell 命令**。  
可选择是否等待命令执行完成。

---

### 20.2 参数说明

| 参数位置 | 类型    | 是否必选 | 中文说明                         | 示例                       |
|----------|---------|----------|----------------------------------|----------------------------|
| 第 1 个  | string  | 是       | 要执行的 Shell 命令              | `"ls /var/mobile"`         |
| 第 2 个  | boolean | 否       | 是否等待命令完成，默认 `false`   | `true`                     |

---

### 20.3 返回值说明

该接口 **无返回值**。

---

### 20.4 Lua 调用示例

```lua
-- 例子1：异步执行
System.shell("ls /var/mobile")

-- 例子2：等待执行完成
System.shell("ls /var/mobile", true)
```

---