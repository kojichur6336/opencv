--====================================
-- 🚀 Device API 单元测试脚本
--====================================

local function log(title)
    Log.print(title)
end

local function pass(name, value)
    Log.print(string.format("[✅ PASS] %s -> %s", name, tostring(value)))
end

local function fail(name, value)
    Log.print(string.format("[❌ FAIL] %s -> %s", name, tostring(value)))
end

local function assertNotNil(name, value)
    if value ~= nil then
        pass(name, value)
    else
        fail(name, "nil")
    end
end

local function assertType(name, value, t)
    if type(value) == t then
        pass(name, value)
    else
        fail(name, "type=" .. type(value))
    end
end

log("====================================")
log("🚀 Device API 单元测试开始")
log("====================================")

------------------------------------------------
-- 1️⃣ Device.name()（异步安全测试）
------------------------------------------------
local oldName = Device.name()
assertType("Device.name() getter", oldName, "string")

local testName = oldName .. "_TEST"
Device.name(testName)

local success = false
local timeout = 2.0      -- 最多等 2 秒
local interval = 0.5
local elapsed = 0

while elapsed < timeout do
    Time.sleep(interval)
    elapsed = elapsed + interval

    local current = Device.name()
    if current == testName then
        pass("Device.name() setter (delayed)", current)
        success = true
        break
    end
end

if not success then
    fail("Device.name() setter (timeout)", Device.name())
end

-- 恢复原名称（同样异步，不强制校验）
Device.name(oldName)
Time.sleep(0.5)

------------------------------------------------
-- 2️⃣ 屏幕尺寸相关
------------------------------------------------
assertType("Device.width()", Device.width(), "number")
assertType("Device.height()", Device.height(), "number")

local w, h = Device.size()
if w and h then
    pass("Device.size()", w .. "x" .. h)
else
    fail("Device.size()", "nil")
end

assertType("Device.scale()", Device.scale(), "number")
assertType("Device.dpi()", Device.dpi(), "number")

------------------------------------------------
-- 3️⃣ 方向
------------------------------------------------
local orientation = Device.frontOrientation()
if type(orientation) == "number" and orientation >= 0 and orientation <= 4 then
    pass("Device.frontOrientation()", orientation)
else
    fail("Device.frontOrientation()", orientation)
end

------------------------------------------------
-- 4️⃣ 设备标识
------------------------------------------------
assertNotNil("Device.model()", Device.model())
assertNotNil("Device.modelNumber()", Device.modelNumber())
assertNotNil("Device.uuid()", Device.uuid())
assertNotNil("Device.serialNumber()", Device.serialNumber())
assertNotNil("Device.cpuArchitecture()", Device.cpuArchitecture())

------------------------------------------------
-- 5️⃣ MAC 地址
------------------------------------------------
local wifiMac = Device.wifiAddress()
if wifiMac and wifiMac:find(":") then
    pass("Device.wifiAddress()", wifiMac)
else
    fail("Device.wifiAddress()", wifiMac)
end

local btMac = Device.bluetoothAddress()
if btMac and btMac:find(":") then
    pass("Device.bluetoothAddress()", btMac)
else
    fail("Device.bluetoothAddress()", btMac)
end

------------------------------------------------
-- 6️⃣ IP 地址
------------------------------------------------
local ip = Device.ip()
assertType("Device.ip()", ip, "string")

local allIp = Device.ip("all")
assertType("Device.ip('all')", allIp, "table")

------------------------------------------------
-- 7️⃣ Telephony
------------------------------------------------
local tele = Device.telephonyInfo()
assertType("Device.telephonyInfo()", tele, "table")

local imei = Device.telephonyInfo("IMEI")
if imei and imei ~= "N/A" then
    pass("Device.telephonyInfo('IMEI')", imei)
else
    Log.print("[⚠️ WARN] IMEI 不可用或无权限")
end

------------------------------------------------
-- 8️⃣ 音量（异步收敛测试）
------------------------------------------------
local vol = Device.volume()
assertType("Device.volume()", vol, "number")

local target = 0.3
Device.volume(target)

local success = false
local timeout = 2.0
local interval = 0.05
local elapsed = 0

while elapsed < timeout do
    Time.sleep(interval)
    elapsed = elapsed + interval

    local current = Device.volume()

    -- 系统音量有平滑 & 量化，允许更大误差
    if math.abs(current - target) <= 0.08 then
        pass("Device.volume(0.3, delayed)", current)
        success = true
        break
    end
end

if not success then
    fail("Device.volume(0.3, timeout)", Device.volume())
end

-- 恢复原音量（不强制断言）
Device.volume(vol)
Time.sleep(0.3)

------------------------------------------------
-- 9️⃣ Device.mute()（状态延迟安全测试）
------------------------------------------------
local muteBefore = Device.mute()
assertType("Device.mute()", muteBefore, "boolean")

Device.mute(not muteBefore)

local success = false
local timeout = 1.5
local interval = 0.5
local elapsed = 0

while elapsed < timeout do
    Time.sleep(interval)
    elapsed = elapsed + interval

    local current = Device.mute()
    if current ~= muteBefore then
        pass("Device.mute(toggle, delayed)", current)
        success = true
        break
    end
end

if not success then
    fail("Device.mute(toggle, timeout)", Device.mute())
end

-- 恢复原状态
Device.mute(muteBefore)
Time.sleep(0.2)

------------------------------------------------
-- 🔟 Flash（谨慎测试）
------------------------------------------------
local flashState = Device.flash()
assertType("Device.flash()", flashState, "boolean")

Device.flash(true)
Time.sleep(0.5)
Device.flash(false)
pass("Device.flash(on/off)", "executed")

------------------------------------------------
-- 1️⃣1️⃣ 振动
------------------------------------------------
local ok = pcall(Device.vibrator)
if ok then
    pass("Device.vibrator()", "executed")
else
    fail("Device.vibrator()", "error")
end

------------------------------------------------
-- 1️⃣2️⃣ Home 键（无法自动验证）
------------------------------------------------
log("[ℹ️ INFO] 即将模拟 Home 键（人工观察）")
Time.sleep(1)
Device.homePress()
Time.sleep(1)
Device.homeDoublePress()
pass("Device.homePress / homeDoublePress", "executed")

------------------------------------------------
log("====================================")
log("🏁 Device API 单元测试完成")
log("====================================")
