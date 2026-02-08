Log.print('========== 🚀 VPN 单元测试开始 ==========')

--------------------------------------------------
-- 工具函数：等待 VPN 状态收敛
--------------------------------------------------
local function waitVPNStatus(expected, timeout)
    local interval = 0.5
    local elapsed = 0

    while elapsed < timeout do
        local status = VPN.status()
        if status == expected then
            return true
        end
        Time.sleep(interval)
        elapsed = elapsed + interval
    end

    return false
end

--------------------------------------------------
-- Step 1: 获取初始 VPN 列表
--------------------------------------------------
Log.print('[Step 1] 📋 获取初始 VPN 列表')

local listRes = VPN.list()
if not listRes or listRes.code ~= 0 then
    Log.print('[❌ FAIL] 获取 VPN 列表失败')
    return
end

Log.print('当前 VPN 数量: ' .. tostring(#listRes.data))
Time.sleep(1)

--------------------------------------------------
-- Step 2: 新增 VPN
--------------------------------------------------
Log.print('[Step 2] ➕ 新增 VPN 配置')

local vpnInfo = {
    dispName = 'UnitTestVPN',
    VPNType = 0,
    server = 'hh1.jhip.net',
    authorization = 'lqq0001',
    password = '1988712',
    VPNLocalIdentifier = '',
    VPNRemotedentifier = '',
    secret = '8899',
    encrypLevel = 1,
    VPNGrade = 0,
    VPNSendAllTraffic = 1
}

local addRes = VPN.add(vpnInfo)
if not addRes or addRes.code ~= 0 then
    Log.print('[❌ FAIL] 新增 VPN 失败')
    return
end

Log.print('[✅ PASS] VPN 新增命令已提交')
Time.sleep(2)

--------------------------------------------------
-- Step 3: 查找新增 VPN
--------------------------------------------------
Log.print('[Step 3] 🔍 查找新增的 VPN')

local listRes2 = VPN.list()
if not listRes2 or listRes2.code ~= 0 then
    Log.print('[❌ FAIL] 再次获取 VPN 列表失败')
    return
end

local targetIdentifier = nil

for _, info in pairs(listRes2.data) do
    Log.print(string.format(
        '  - 名称: %s | identifier: %s',
        tostring(info.name),
        tostring(info.identifier)
    ))

    if info.name == 'UnitTestVPN' then
        targetIdentifier = info.identifier
        break
    end
end

if not targetIdentifier then
    Log.print('[❌ FAIL] 未找到新增的 VPN 配置')
    return
end

Log.print('[✅ PASS] 找到新增 VPN，identifier = ' .. tostring(targetIdentifier))
Time.sleep(1)

--------------------------------------------------
-- Step 4: 选择 VPN
--------------------------------------------------
Log.print('[Step 4] 🎯 选择 VPN')

local useRes = VPN.use(targetIdentifier)
if not useRes or useRes.code ~= 0 then
    Log.print('[❌ FAIL] VPN 选择失败')
    return
end

Log.print('[✅ PASS] VPN 已设为当前配置')
Time.sleep(2)

--------------------------------------------------
-- Step 5: 查询当前 VPN 状态
--------------------------------------------------
Log.print('[Step 5] 📡 查询当前 VPN 状态')

local currentStatus = VPN.status()
Log.print('当前 VPN 状态: ' .. (currentStatus and '已开启' or '未开启'))
Time.sleep(1)

--------------------------------------------------
-- Step 6: 切换 VPN 状态（带收敛验证）
--------------------------------------------------
Log.print('[Step 6] 🔁 切换 VPN 状态')

local targetStatus = not currentStatus
Log.print('目标状态: ' .. (targetStatus and '开启' or '关闭'))

VPN.switch(targetStatus)
Log.print('已发送 VPN.switch(' .. tostring(targetStatus) .. ')，等待系统生效...')

local ok = waitVPNStatus(targetStatus, 15)

if ok then
    Log.print('[✅ PASS] VPN 状态已成功切换为: ' .. (targetStatus and '已开启' or '未开启'))
else
    Log.print('[❌ FAIL] VPN 状态在超时时间内未生效')
    return
end

--------------------------------------------------
-- Step 7: 最终确认 VPN 状态
--------------------------------------------------
Log.print('[Step 7] ✅ 最终确认 VPN 状态')

local finalStatus = VPN.status()
if finalStatus == targetStatus then
    Log.print('[✅ PASS] VPN 最终状态确认一致')
else
    Log.print('[❌ FAIL] VPN 最终状态不一致')
end

Time.sleep(1)

--------------------------------------------------
-- Step 8: 删除 VPN
--------------------------------------------------
Log.print('[Step 8] 🗑 删除 VPN 配置')

local removeRes = VPN.remove(targetIdentifier)
if not removeRes or removeRes.code ~= 0 then
    Log.print('[❌ FAIL] 删除 VPN 失败')
    return
end

Log.print('[✅ PASS] VPN 删除命令已提交')
Time.sleep(2)

--------------------------------------------------
-- Step 9: 最终列表确认
--------------------------------------------------
Log.print('[Step 9] 📋 最终 VPN 列表确认')

local finalList = VPN.list()
if not finalList or finalList.code ~= 0 then
    Log.print('[❌ FAIL] 获取最终 VPN 列表失败')
    return
end

Log.print('最终 VPN 数量: ' .. tostring(#finalList.data))

Log.print('========== 🏁 VPN 单元测试结束 ==========')
