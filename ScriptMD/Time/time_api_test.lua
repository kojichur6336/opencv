--====================================
-- 🚀 Time 模块单元测试脚本（安全版）
-- 测试 sleep / msleep / delay / systemTimeSeconds / networkTime
--====================================

-- 日志工具
local function logResult(name, success, value)
    local status = success and "✅ PASS" or "❌ FAIL"
    Log.print(string.format("[%s] %s -> %s", status, name, tostring(value)))
end

Log.print("========== Time 模块单元测试 ==========")

-- 1️⃣ 秒级休眠
Log.print("测试 Time.sleep(1)")
local t0 = os.time()
Time.sleep(1)
local t1 = os.time()
logResult("Time.sleep(1) duration", (t1 - t0) == 1, t1 - t0)

-- 2️⃣ 毫秒级休眠
Log.print("测试 Time.msleep(500)")
local ok = pcall(Time.msleep, 500)
logResult("Time.msleep(500) executed", ok, "")

-- 3️⃣ 延时
Log.print("测试 Time.delay(200)")
local ok2 = pcall(Time.delay, 200)
logResult("Time.delay(200) executed", ok2, "")

-- 4️⃣ 系统时间
local sysTime = Time.systemTimeSeconds()
logResult("Time.systemTimeSeconds()", sysTime ~= nil, os.date('%Y-%m-%d %H:%M:%S', sysTime))

-- 5️⃣ 网络时间测试（示例 60 秒）
local duration = 60
Log.print('====================================')
Log.print('🚀 网络时间对齐测试 (60 秒演示)')
Log.print('💡 提示：请在脚本运行期间手动修改系统时间进行测试')
Log.print('====================================')

for i = duration, 1, -1 do
    local sTime = Time.systemTimeSeconds()
    local nTime, synced = Time.networkTime()
    local offset = nTime - sTime
    local statusIcon = synced and '✅ [已同步]' or '⏳ [同步中]'

    Log.print(string.format('倒计时: %02d 秒 %s', i, statusIcon))
    Log.print(string.format('  系统时间: %s (%d)', os.date('%Y-%m-%d %H:%M:%S', sTime), sTime))
    Log.print(string.format('  网络时间: %s (%d)', os.date('%Y-%m-%d %H:%M:%S', nTime), nTime))
    Log.print(string.format('  当前偏差: %d 秒', offset))
    Log.print('------------------------------------')

    Time.sleep(1)
end

Log.print("========== Time 单元测试结束 ==========")
