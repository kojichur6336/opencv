--====================================
-- 🚀 Touch 模块单元测试（可视化 / 居中 / 慢速安全版）
--====================================

--------------------------------------------------
-- 工具函数
--------------------------------------------------
local function logDone(name)
    Log.print(string.format("✅ 完成: %-20s @ %s", name, os.date("%H:%M:%S")))
end

local function wait(sec, reason)
    Log.print(string.format("⏳ 等待 %d 秒 (%s)", sec, reason or ""))
    Time.sleep(sec)
end

--------------------------------------------------
-- 基础信息
--------------------------------------------------
local sw = Device.width()
local sh = Device.height()
local cx = sw * 0.5
local cy = sh * 0.5

Log.print(string.format("📱 分辨率: %.0f x %.0f", sw, sh))
Log.print(string.format("🎯 屏幕中心: %.1f , %.1f", cx, cy))

--------------------------------------------------
-- 开启触摸可视化
--------------------------------------------------
Log.print("🎯 启用触摸可视化 (Touch.shouldShowTouches = true)")
Touch.shouldShowTouches(true)
wait(1, "观察触摸指示器开启状态")

Log.print("========== 🚀 Touch 单元测试开始 ==========")

--------------------------------------------------
-- 1️⃣ Tap / DoubleTap / LongPress
--------------------------------------------------
Log.print("▶️ 测试 1: Tap / DoubleTap / LongPress")

local y1 = sh * 0.2

Touch.tap(cx - sw * 0.15, y1)
logDone("Touch.tap")
wait(3, "观察 Tap")

Touch.doubleTap(cx, y1)
logDone("Touch.doubleTap")
wait(3, "观察 DoubleTap")

Touch.longPress(cx + sw * 0.15, y1, 1200)
logDone("Touch.longPress")
wait(3, "观察 LongPress")

--------------------------------------------------
-- 2️⃣ Swipe / SwipeCurve
--------------------------------------------------
Log.print("▶️ 测试 2: Swipe / SwipeCurve")

local y2 = sh * 0.35

Touch.swipe(sw * 0.2, y2, sw * 0.8, y2, 0.5)
logDone("Touch.swipe")
wait(3, "观察 Swipe")

Touch.swipeCurve(sw * 0.8, y2 + 60, sw * 0.2, y2 + 60, 0.6)
logDone("Touch.swipeCurve")
wait(3, "观察 SwipeCurve")

--------------------------------------------------
-- 3️⃣ Zoom / Pinch（居中）
--------------------------------------------------
Log.print("▶️ 测试 3: Zoom / Pinch（居中）")

local zw = sw * 0.25
local zh = sh * 0.15

Touch.zoom(cx - zw, cy - zh, zw * 2, zh * 2, 2.0, 0, 0.6)
logDone("Touch.zoom")
wait(3, "观察 Zoom")

Touch.pinch(cx - zw * 1.5, cy - zh * 1.2, zw * 3, zh * 2.4, 0.5, 0, 0.6)
logDone("Touch.pinch")
wait(3, "观察 Pinch")

--------------------------------------------------
-- 4️⃣ 五指梅花桩（居中）
--------------------------------------------------
Log.print("▶️ 测试 4: 五指梅花桩")

local r = math.min(sw, sh) * 0.18
local pts = {
    {cx, cy},
    {cx, cy - r},
    {cx, cy + r},
    {cx - r, cy},
    {cx + r, cy},
}

for i = 1, 5 do
    Touch.down(i, pts[i][1], pts[i][2])
end
wait(3, "观察五指按下")

for i = 1, 5 do
    Touch.move(i, pts[i][1] + 40, pts[i][2] + 40)
end
wait(3, "观察五指同步移动")

for i = 1, 5 do
    Touch.up(i)
end
logDone("五指梅花桩")
wait(3, "观察五指同步移动")


--------------------------------------------------
-- 5️⃣ 单指画矩形
--------------------------------------------------
Log.print("▶️ 测试 5: 单指矩形")

local baseY = cy - sh * 0.08   -- ⬅️ 上移到屏幕中心区域
local size  = sw * 0.18
local steps = 12
local delay = 0.05

local left   = cx - size
local right  = cx + size
local top    = baseY
local bottom = baseY + size

-- 1️⃣ 按下
Touch.down(1, left, top)
wait(3, "矩形起点按下（中心区域）")

-- 2️⃣ 上边
for i = 1, steps do
    local x = left + (right - left) * (i / steps)
    Touch.move(1, x, top)
    Time.sleep(delay)
end
wait(3, "上边完成")

-- 3️⃣ 右边
for i = 1, steps do
    local y = top + (bottom - top) * (i / steps)
    Touch.move(1, right, y)
    Time.sleep(delay)
end
wait(3, "右边完成")

-- 4️⃣ 下边
for i = 1, steps do
    local x = right - (right - left) * (i / steps)
    Touch.move(1, x, bottom)
    Time.sleep(delay)
end
wait(3, "下边完成")

-- 5️⃣ 左边
for i = 1, steps do
    local y = bottom - (bottom - top) * (i / steps)
    Touch.move(1, left, y)
    Time.sleep(delay)
end
wait(3, "左边完成")

-- 6️⃣ 抬起
Touch.up(1)
wait(3, "矩形完成抬起")
logDone("单指矩形")


--------------------------------------------------
-- 6️⃣ 单指螺旋
--------------------------------------------------
Log.print("▶️ 测试 6: 单指螺旋")

local sx, sy = cx - sw * 0.2, sh * 0.78
Touch.down(1, sx, sy)

for i = 1, 50 do
    local radius = i * sw * 0.003
    local angle = i * 0.5
    Touch.move(1,
        sx + radius * math.cos(angle),
        sy + radius * math.sin(angle)
    )
    Time.sleep(0.02)
end

Touch.up(1)
logDone("单指螺旋")
wait(3, "观察螺旋")

--------------------------------------------------
-- 关闭触摸可视化
--------------------------------------------------
Log.print("🧹 关闭触摸可视化 (Touch.shouldShowTouches = false)")
Touch.shouldShowTouches(false)
wait(1, "清理触控指示器")

Log.print("========== 🏁 Touch 单元测试结束 ==========")
