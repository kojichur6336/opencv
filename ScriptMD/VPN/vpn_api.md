# VPN 功能接口文档

---

## 1. `VPN.list()`

### 1.1 返回值说明

`VPN.list()` 用于获取当前设备中已配置的 VPN 列表。

#### 返回结构

| 字段名 | 类型   | 中文说明                     | 示例 |
|------|--------|----------------------------|------|
| code | int    | 状态码：`0` 成功，非 `0` 失败 | 0    |
| msg  | string | 状态描述信息                 | 成功 |
| data | table  | VPN 数据集合                 | 见下 |

#### `data` 字段说明

- `data` 为 **Lua table**
- `key`：VPN 的 `identifier`
- `value`：VPN 详细信息
- 遍历方式：`pairs(res.data)`

##### VPN 信息字段

| 字段名                  | 类型    | 中文说明                         | 示例           |
|-----------------------|--------|----------------------------------|----------------|
| name                  | string | VPN 名称（用户自定义）            | MyVPN   |
| identifier            | string | VPN 唯一 ID（UUID）               | 42BF9B7C-1EF5  |
| applicationName       | string | 应用名称（系统 VPN 配置页显示）   | VPNApp   |
| applicationIdentifier | string | 应用包名（唯一标识 App）          | com.example.vpn |

---

### 1.2 Lua 调用示例

```lua
local res = VPN.list()

if res then
    Log.print('------------------------------------')
    Log.print('状态码: ' .. tostring(res.code))
    Log.print('提示消息: ' .. tostring(res.msg))

    if res.code == 0 then
        local total = 0
        for id, vpnInfo in pairs(res.data) do
            total = total + 1
            Log.print(string.format(
                '[索引: %s] 唯一标识: %s, 名称: %s, 应用名: %s, 应用包名: %s',
                tostring(id),
                tostring(vpnInfo.identifier),
                tostring(vpnInfo.name),
                tostring(vpnInfo.applicationName),
                tostring(vpnInfo.applicationIdentifier)
            ))
        end
        Log.print('获取成功，总数: ' .. total)
    else
        Log.print('操作失败: ' .. tostring(res.msg))
    end

    Log.print('------------------------------------')
else
    Log.print('错误: 未能获取到 res 对象')
end
```

---

## 2. `VPN.add(VPNConfig)`

### 2.1  参数说明 接受一个包含 VPN 配置项的 table，以下是该 table 的结构：

| 字段名              | 类型    | 必选 | 中文说明                                                  | 示例 |
|-------------------|--------|------|---------------------------------------------------------|------|
| dispName           | string | 是   | VPN 名称                                                 | ExampleVPN |
| VPNType            | int    | 是   | VPN 类型：`0=L2TP`、`1=PPTP`、`2=IPSec`、`4=IKEv2`         | 0 |
| server             | string | 是   | VPN 服务器地址                                           | vpn.example.com |
| authorization      | string | 是   | VPN 账号                                                 | user01 |
| password           | string | 是   | VPN 密码                                                 | password01 |
| VPNLocalIdentifier | string | 否   | 本地身份标识                                             | localID |
| VPNRemotedentifier | string | 否   | 服务器身份标识（IKEv2 必填）                              | remoteID |
| authType           | int    | 否   | 用户认证方式：`0=无`、`1=用户名`                          | 0 |
| eapType            | string | 否   | EAP 认证方式                                             | EAP-TTLS |
| securID            | string | 否   | RSA SecurID 动态令牌                                     | token |
| secret             | string | 否   | 共享密钥                                                 | secretKey |
| encrypLevel        | int    | 否   | 加密强度等级                                             | 1 |
| VPNGrade           | int    | 否   | VPN 质量 / 信任等级                                      | 0 |
| VPNSendAllTraffic  | int    | 否   | 是否强制所有流量走 VPN：`1=是`，`0=否`                     | 1 |

---

### 2.2 返回值说明

| 字段名 | 类型   | 中文说明                      | 示例 |
|------|--------|-----------------------------|------|
| code | int    | 状态码：`0` 成功，非 `0` 失败 | 0 |
| msg  | string | 执行结果描述                 | 成功 |

---

### 2.4 Lua 调用示例

```lua
local vpnInfo = {
    dispName = 'ExampleVPN',
    VPNType = 0,
    server = 'vpn.example.com',
    authorization = 'user01',
    password = 'password01',
    VPNLocalIdentifier = '',
    VPNRemotedentifier = '',
    secret = 'secretKey',
    encrypLevel = 1,
    VPNGrade = 0,
    VPNSendAllTraffic = 1
}

local res = VPN.add(vpnInfo)
if res then
    Log.print('------------------------------------')
    Log.print('状态码: ' .. tostring(res.code))

    if res.code == 0 then
        Log.print('添加 VPN 成功')
    else
        Log.print('添加 VPN 失败: ' .. tostring(res.msg))
    end

    Log.print('------------------------------------')
else
    Log.print('错误: VPN.add 未返回结果')
end
```

---

## 3. `VPN.remove(identifier)`

### 3.1 功能说明

`VPN.remove(identifier)` 用于删除指定 VPN 配置。

- `identifier`：要删除的 VPN 的唯一 ID（UUID）
- 可以传入 VPN 名称来删除对应的 VPN（如果名称唯一）
- 如果传入 `'*'`，则删除所有 VPN 配置
- 返回值为一个包含状态码和提示信息的 table

### 3.2 参数说明

| 参数名      | 类型   | 是否必选 | 中文说明                     | 示例                   |
|------------|--------|---------|----------------------------|----------------------|
| identifier | string | 是      | 要删除的 VPN 的 UUID，VPN 名称，或者传 `'*'` 删除所有 VPN | 42BF9B7C-1EF5 / VPN名称 / '*'  |

### 3.3 返回值说明

| 字段名 | 类型   | 中文说明                      | 示例 |
|------|--------|-----------------------------|------|
| code | int    | 状态码：`0` 成功，非 `0` 失败 | 0    |
| msg  | string | 执行结果描述                 | 成功 |
| data | table  | 固定为空字符串 `""`         | ""  |

---

### 3.4 Lua 调用示例

```lua
-- 删除单个 VPN
local identifier = 'ExampleVPN-UUID'  -- 替换为实际 VPN 的 identifier 或者 名称
local res = VPN.remove(identifier)

if res then
    Log.print('------------------------------------')
    Log.print('状态码: ' .. tostring(res.code))

    if res.code == 0 then
        Log.print('删除成功')
    else
        Log.print('删除失败: ' .. tostring(res.msg))
    end

    Log.print('------------------------------------')
else
    Log.print('错误: 未能获取到 res 对象')
end

-- 删除所有 VPN
local resAll = VPN.remove('*')
if resAll then
    Log.print('------------------------------------')
    Log.print('状态码: ' .. tostring(resAll.code))

    if resAll.code == 0 then
        Log.print('已删除所有 VPN')
    else
        Log.print('删除失败: ' .. tostring(resAll.msg))
    end

    Log.print('------------------------------------')
else
    Log.print('错误: 未能获取到 res 对象')
end
```


---

## 4. `VPN.use(identifier)`

### 4.1 功能说明

`VPN.use(identifier)` 用于选择并启用指定的 VPN 配置。

- `identifier`：要启用的 VPN 的唯一 ID（UUID）或 VPN 名称
- 返回值为一个包含状态码和提示信息的 table

### 4.2 参数说明

| 参数名      | 类型   | 是否必选 | 中文说明                         | 示例                   |
|------------|--------|---------|--------------------------------|----------------------|
| identifier | string | 是      | 要启用的 VPN 的 UUID 或名称       | 42BF9B7C-1EF5 / VPN名称  |

### 4.3 返回值说明

| 字段名 | 类型   | 中文说明                      | 示例 |
|------|--------|-----------------------------|------|
| code | int    | 状态码：`0` 成功，非 `0` 失败 | 0    |
| msg  | string | 执行结果描述                 | 成功 |

---

### 4.4 Lua 调用示例

```lua
local identifier = 'ExampleVPN-UUID'  -- 或 VPN 名称
local res = VPN.use(identifier)

if res then
    Log.print('------------------------------------')
    Log.print('状态码: ' .. tostring(res.code))

    if res.code == 0 then
        Log.print('选择成功')
    else
        Log.print('选择失败: ' .. tostring(res.msg))
    end

    Log.print('------------------------------------')
else
    Log.print('错误: 未能获取到 res 对象')
end
```

---

## 5. `VPN.status()`

### 5.1 功能说明

`VPN.status()` 用于获取当前设备 VPN 的连接状态。

- 返回当前 VPN 是否处于启用状态
- 常用于脚本逻辑判断或状态检测

### 5.2 参数说明

无参数

### 5.3 返回值说明

| 类型 | 中文说明           | 示例 |
|------|------------------|------|
| bool | VPN 是否已开启     | true |

- `true`：VPN 已开启  
- `false`：VPN 未开启  

---

### 5.4 Lua 调用示例

```lua
local enabled = VPN.status()

if enabled then
    Log.print('VPN 当前状态：已开启')
else
    Log.print('VPN 当前状态：未开启')
end
```


---

## 6. `VPN.switch(enable)`

### 6.1 功能说明

`VPN.switch(enable)` 用于控制当前设备 VPN 的开启或关闭状态。

- 通过传入布尔值控制 VPN 开关
- 仅执行开关操作，不返回执行结果
- 常用于脚本中主动切换 VPN 状态

### 6.2 参数说明

| 参数名 | 类型 | 是否必选 | 中文说明       | 示例 |
|------|------|---------|--------------|------|
| enable | bool | 是 | 是否开启 VPN | true |

- `true`：开启 VPN  
- `false`：关闭 VPN  

### 6.3 返回值说明

无返回值

---

### 6.4 Lua 调用示例

```lua
-- 开启 VPN
VPN.switch(true)
Log.print('VPN 已开启')

-- 关闭 VPN
VPN.switch(false)
Log.print('VPN 已关闭')
```