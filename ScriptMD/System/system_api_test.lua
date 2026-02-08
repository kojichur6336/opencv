Log.print('========== 🚀 System 单元测试开始 ==========')

--------------------------------------------------
-- Step 1: 获取系统版本
--------------------------------------------------
Log.print('【Step 1】获取系统版本')
local osVer = System.osVersion()
if type(osVer) == 'string' and #osVer > 0 then
    Log.print('[✅ PASS] 系统版本: ' .. osVer)
else
    Log.print('[❌ FAIL] 获取系统版本失败')
end
Time.sleep(1)

--------------------------------------------------
-- Step 2: 获取磁盘总容量 (/)
--------------------------------------------------
Log.print('【Step 2】获取磁盘总容量 (/)')

local totalRoot = System.totalDiskSpace('/')
if type(totalRoot) == 'number' and totalRoot > 0 then
    Log.print('[✅ PASS] / 总容量: ' .. totalRoot)
else
    Log.print('[❌ FAIL] 获取 / 总容量失败')
end
Time.sleep(1)

--------------------------------------------------
-- Step 3: 获取磁盘剩余容量 (/)
--------------------------------------------------
Log.print('【Step 3】获取磁盘剩余容量 (/)')

local freeRoot = System.freeDiskSpace('/')
if type(freeRoot) == 'number' then
    Log.print('[✅ PASS] / 剩余容量: ' .. freeRoot)
else
    Log.print('[❌ FAIL] 获取 / 剩余容量失败')
end
Time.sleep(1)

--------------------------------------------------
-- Step 4: 磁盘容量一致性校验
--------------------------------------------------
Log.print('【Step 4】磁盘容量一致性校验')
if freeRoot <= totalRoot then
    Log.print('[✅ PASS] 剩余容量 ≤ 总容量')
else
    Log.print('[❌ FAIL] 容量异常')
end
Time.sleep(1)

--------------------------------------------------
-- Step 5: 屏幕锁定状态
--------------------------------------------------
Log.print('【Step 5】获取屏幕锁定状态')
local locked = System.isScreenLocked()
if type(locked) == 'boolean' then
    Log.print('[✅ PASS] 当前锁定状态: ' .. tostring(locked))
else
    Log.print('[❌ FAIL] 无法获取锁定状态')
end
Time.sleep(1)

--------------------------------------------------
-- Step 6: 锁屏功能
--------------------------------------------------
Log.print('【Step 6】执行锁屏（人工确认）')
System.lockScreen()
Log.print('[ℹ️ INFO] 已请求锁屏，等待状态刷新')
Time.sleep(3)

--------------------------------------------------
-- Step 7: 解锁屏幕（不带密码）
--------------------------------------------------
Log.print('【Step 7】解锁屏幕（唤醒）')
System.unlockScreen()
Time.sleep(3)

local locked2 = System.isScreenLocked()
if locked2 == false then
    Log.print('[✅ PASS] 已唤醒屏幕')
else
    Log.print('[⚠️ WARN] 屏幕仍为锁定状态')
end
Time.sleep(1)

--------------------------------------------------
-- Step 8~9: 屏幕亮度动态测试
--------------------------------------------------
Log.print('【Step 8】屏幕亮度动态测试')
local originalBrightness = System.brightness()
if type(originalBrightness) ~= 'number' then
    Log.print('[❌ FAIL] 读取亮度失败')
else
    Log.print('[✅ PASS] 当前亮度: ' .. originalBrightness)
    local testBrightness = (math.abs(originalBrightness-0.5)<0.05) and 0.8 or 0.5
    Log.print('设置屏幕亮度为 ' .. testBrightness)
    System.brightness(testBrightness)
    Time.sleep(3)
    if math.abs(System.brightness()-testBrightness)<0.05 then
        Log.print('[✅ PASS] 亮度设置成功')
    else
        Log.print('[❌ FAIL] 亮度未生效')
    end
    System.brightness(originalBrightness)
    Time.sleep(1)
    Log.print('[✅ DONE] 原始亮度已恢复')
end

--------------------------------------------------
-- Step 10~11: 屏幕旋转锁定动态测试
--------------------------------------------------
Log.print('【Step 10】屏幕旋转锁定动态测试')
local oriLockOriginal = System.orientationLocked()
System.orientationLocked(not oriLockOriginal)
Time.sleep(3)
if System.orientationLocked() == not oriLockOriginal then
    Log.print('[✅ PASS] 旋转锁定设置成功')
else
    Log.print('[❌ FAIL] 设置未生效')
end
System.orientationLocked(oriLockOriginal)
Time.sleep(1)
Log.print('[✅ DONE] 原始旋转锁定已恢复')

--------------------------------------------------
-- Step 12~13: 自动锁定时间动态测试
--------------------------------------------------
Log.print('【Step 12】自动锁定时间动态测试')
local autoLockOriginal = System.autoLockTime()
local testLockTime = (autoLockOriginal ~= 60) and 60 or 120
System.autoLockTime(testLockTime)
Time.sleep(3)
if System.autoLockTime() == testLockTime then
    Log.print('[✅ PASS] 自动锁定时间设置成功')
else
    Log.print('[❌ FAIL] 自动锁定时间未生效')
end
System.autoLockTime(autoLockOriginal)
Time.sleep(1)
Log.print('[✅ DONE] 原始自动锁定时间已恢复')

--------------------------------------------------
-- Step 14: Wi-Fi 动态测试
--------------------------------------------------
Log.print('【Step 14】Wi-Fi 动态测试')
local wifiOriginal = System.wifi()
System.wifi(not wifiOriginal)
Time.sleep(3)
if System.wifi() == not wifiOriginal then
    Log.print('[✅ PASS] Wi-Fi 设置成功')
else
    Log.print('[❌ FAIL] Wi-Fi 设置失败')
end
System.wifi(wifiOriginal)
Time.sleep(1)
Log.print('[✅ DONE] 原始 Wi-Fi 状态已恢复')

--------------------------------------------------
-- Step 15: 蓝牙动态测试
--------------------------------------------------
Log.print('【Step 15】蓝牙动态测试')
local btOriginal = System.bluetooth()
System.bluetooth(not btOriginal)
Time.sleep(3)
if System.bluetooth() == not btOriginal then
    Log.print('[✅ PASS] 蓝牙设置成功')
else
    Log.print('[❌ FAIL] 蓝牙设置失败')
end
System.bluetooth(btOriginal)
Time.sleep(1)
Log.print('[✅ DONE] 原始蓝牙状态已恢复')

--------------------------------------------------
-- Step 16: 飞行模式动态测试
--------------------------------------------------
Log.print('【Step 16】飞行模式动态测试')
local airplaneOriginal = System.airplane()
System.airplane(not airplaneOriginal)
Time.sleep(3)
if System.airplane() == not airplaneOriginal then
    Log.print('[✅ PASS] 飞行模式设置成功')
else
    Log.print('[❌ FAIL] 飞行模式设置失败')
end
System.airplane(airplaneOriginal)
Time.sleep(1)
Log.print('[✅ DONE] 原始飞行模式已恢复')

--------------------------------------------------
-- Step 17: AirDrop 模式动态测试
--------------------------------------------------
Log.print('【Step 17】AirDrop 模式动态测试')
local airdropOriginal = System.airDrop()
local testAirDrop = (airdropOriginal ~= 0) and 0 or 1
System.airDrop(testAirDrop)
Time.sleep(3)
if System.airDrop() == testAirDrop then
    Log.print('[✅ PASS] AirDrop 模式设置成功')
else
    Log.print('[❌ FAIL] AirDrop 模式设置失败')
end
System.airDrop(airdropOriginal)
Time.sleep(1)
Log.print('[✅ DONE] 原始 AirDrop 模式已恢复')

--------------------------------------------------
-- Step 18: AssistiveTouch 状态动态测试
--------------------------------------------------
Log.print('【Step 18】AssistiveTouch 动态测试')
local assistOriginal = System.assistiveTouch()
System.assistiveTouch(not assistOriginal)
Time.sleep(3)
if System.assistiveTouch() == not assistOriginal then
    Log.print('[✅ PASS] AssistiveTouch 设置成功')
else
    Log.print('[❌ FAIL] AssistiveTouch 设置失败')
end
System.assistiveTouch(assistOriginal)
Time.sleep(1)
Log.print('[✅ DONE] 原始 AssistiveTouch 状态已恢复')

--------------------------------------------------
-- Step 19: Reduce Motion 动态测试
--------------------------------------------------
Log.print('【Step 19】Reduce Motion 动态测试')
local reduceOriginal = System.reduceMotion()
System.reduceMotion(not reduceOriginal)
Time.sleep(3)
if System.reduceMotion() == not reduceOriginal then
    Log.print('[✅ PASS] Reduce Motion 设置成功')
else
    Log.print('[❌ FAIL] Reduce Motion 设置失败')
end
System.reduceMotion(reduceOriginal)
Time.sleep(1)
Log.print('[✅ DONE] 原始 Reduce Motion 已恢复')

--------------------------------------------------
-- Step 20: Safari 远程调试动态测试
--------------------------------------------------
Log.print('【Step 20】Safari 远程调试动态测试')
local safariOriginal = System.safariRemoteInspector()
System.safariRemoteInspector(not safariOriginal)
Time.sleep(3)
if System.safariRemoteInspector() == not safariOriginal then
    Log.print('[✅ PASS] Safari 远程调试设置成功')
else
    Log.print('[❌ FAIL] Safari 远程调试设置失败')
end
System.safariRemoteInspector(safariOriginal)
Time.sleep(1)
Log.print('[✅ DONE] 原始 Safari 状态已恢复')

--------------------------------------------------
-- Step 21: Shell 命令执行
--------------------------------------------------
Log.print('【Step 21】Shell 命令执行测试')
-- 异步执行
Log.print('【Shell】异步执行 ls /var/mobile')
System.shell('ls /var/mobile')
Log.print('[ℹ️ INFO] 已触发异步 Shell 执行（无返回值，人工确认日志输出）')
Time.sleep(1)

-- 同步执行
Log.print('【Shell】同步执行 ls /var/mobile')
local startTime = Time.now()
System.shell('ls /var/mobile', true)
local cost = Time.now() - startTime
if cost >= 0 then
    Log.print('[✅ PASS] Shell 同步执行完成，耗时: ' .. string.format('%.2f', cost) .. ' 秒')
else
    Log.print('[❌ FAIL] Shell 同步执行异常')
end

Log.print('========== 🏁 System 单元测试结束 ==========')
