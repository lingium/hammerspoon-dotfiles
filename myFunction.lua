
------------------------- Functions  -------------------------
-- faster KeyStroke than hs.eventtap.keyStroke()
-- https://github.com/Hammerspoon/hammerspoon/issues/1011#issuecomment-261114434
doKeyStroke = function(modifiers, character)
    local event = require("hs.eventtap").event
    event.newKeyEvent(modifiers, string.lower(character), true):post()
    event.newKeyEvent(modifiers, string.lower(character), false):post()
end

doSingleKeyStroke = function(keyCode)
    local event = require("hs.eventtap").event
    event.newKeyEvent(keyCode, true):post()
    event.newKeyEvent(keyCode, false):post()
end

doClickAndRestore = function(mousePos, delay)
    local delay = delay == nil and 200000 or delay
    local oldmousePos = hs.mouse.absolutePosition()
    hs.eventtap.leftClick(mousePos, delay) --默认有延迟 Defaults to 200000 (i.e. 200ms)
    hs.mouse.absolutePosition(oldmousePos)
end

printTable = function(a)
    for k, v in pairs(a) do
        print(tostring(k), v)
    end
end

-- https://blog.csdn.net/qq_15437667/article/details/81537387
lenTable = function(a)
    return (a and #a) or 0
end

function openFolder(path)
    local numWinBefore = lenTable(hs.application.get("com.apple.finder"):allWindows())
    hs.osascript.applescript( 'tell application "Finder" to open (' .. path .. ' as POSIX file)' )
    local numWinAfter = lenTable(hs.application.get("com.apple.finder"):allWindows())
    if numWinAfter > numWinBefore then --要打开的窗口已经在本桌面新打开
        hs.application.launchOrFocus('Finder')
    elseif numWinAfter == numWinBefore then --要打开的窗口位于别的桌面，要切过去，或早就在本桌面打开
        hs.application.launchOrFocus('Finder')
        hs.osascript.applescript( 'tell application "Finder" to open (' .. path .. ' as POSIX file)' )
    end
end

--检查app是否有符合title的窗口，有hs.application:findWindow(titlePattern) 

-------------------------  Global  -------------------------
-- hammerspoon有bug，{ 'fn' }, "f13"只会管"f13",flags不会管，也就是说无法区分按不按flags
-- 应用切换
hs.hotkey.bind({  }, "f1", function ()
    hs.application.launchOrFocus('Finder') --如果当前桌面上有Finder窗口就会弹出该窗口
    hs.timer.usleep(10000) -- 0.01s
    local b = hs.application.frontmostApplication()
    local numWindows = lenTable(b:allWindows())
    --桌面是一个没有名字的Finder窗口，所以至少有一个
    if numWindows == 1 then 
        -- doKeyStroke({ "alt", "cmd" }, "L")
        doKeyStroke({ "cmd" }, "N") --如果没有，就会打开download窗口
    else
        -- hs.alert.show(numWindows)
    end
end)

hs.hotkey.bind({  }, "f2", function ()
    hs.application.launchOrFocus('PDF Expert')
end)

hs.hotkey.bind({  }, "f3", function ()
    hs.application.launchOrFocus('Google Chrome')
end)

hs.hotkey.bind({  }, "f4", function ()
    hs.application.launchOrFocus('Microsoft OneNote')
end)

hs.hotkey.bind({  }, "f5", function ()
    hs.application.launchOrFocus('Visual Studio Code')
end)

hs.hotkey.bind({  }, "f6", function ()
    hs.spaces.toggleAppExpose() --app Exposé
end)

hs.hotkey.bind({  }, "f7", function ()
    hs.osascript.applescript([[
        tell application "System Events"
            tell process "控制中心"
                click menu bar item 6 of menu bar 1
                if exists of UI element "暂停" of window 1 then
                    click button "暂停" of window 1
                else if exists of UI element "播放" of window 1 then
                    click button "播放" of window 1
                end if
                click menu bar item 6 of menu bar 1
            end tell
        end tell
    ]])
end)


hyperModFn = hs.hotkey.modal.new({}, "kana")
hyperKeyFnCallback = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(e)
    local t_flags = e:getFlags()
    local n_keycode = e:getKeyCode()
    local s_keycode = hs.keycodes.map[e:getKeyCode()] --'fn'
    if s_keycode == 'fn' and ( t_flags.fn) then   
        hyperModFn:enter()
    end
    if s_keycode == 'fn' and (t_flags.fn == nil) then   
        hyperModFn:exit()
    end
end)
hyperKeyFnCallback:start()

--强制在当前桌面打开并聚焦一个Downloads窗口
hyperModFn:bind({ "fn" }, "f1", function()
    local path = '"/Users/lingzhi/Downloads"'
    --如果不这样的话，一旦其他桌面有Downloads窗口，本桌面又聚焦在访达app，就会切到其他窗口并多打开一个Downloads
    if hs.application.frontmostApplication():bundleID() == 'com.apple.finder' then --如果聚焦在访达app
        local win = hs.application.get("com.apple.finder"):findWindow('Downloads') --检查当前桌面访达窗口是否有Downloads
        if win then 
            win:focus()
        elseif win == nil then 
            doKeyStroke({ "cmd" }, "N") --如果没有就打开Downloads
        end
    else
        local numWinBefore = lenTable(hs.application.get("com.apple.finder"):allWindows())
        hs.osascript.applescript( 'tell application "Finder" to open (' .. path .. ' as POSIX file)' )
        local numWinAfter = lenTable(hs.application.get("com.apple.finder"):allWindows())
        if numWinAfter > numWinBefore then --要打开的窗口已经在本桌面新打开
            hs.application.launchOrFocus('Finder')
        elseif numWinAfter == numWinBefore then --要打开的窗口位于别的桌面，或者之前就已经在本桌面打开
            local win = hs.application.get("com.apple.finder"):findWindow('Downloads')
            if win then
                win:focus()
            else
                hs.application.launchOrFocus('Finder')
                doKeyStroke({ "cmd" }, "N")
            end
        end
    end

end)

hyperModFn:bind({ "fn" }, "f3", function ()
    local chrome = hs.application.get('Google Chrome')
    if #chrome:allWindows() == 0 then 
        hs.application.launchOrFocus('Google Chrome') --避免打开两个新标签页
    else
        hs.application.launchOrFocus('Google Chrome')
        hs.eventtap.keyStroke({ "cmd" }, "t", 0, chrome)
    end
end)

-------------------------  OneNote  -------------------------
-- 切换笔记本
nb1pos = {x = 88, y = 228}
nb2pos = {x = 92, y = 263}

local switch_nb1 = hs.hotkey.new(hyperKey1, "[", function()
    -- doKeyStroke({ "alt", "ctrl" }, "return") --先强制全屏
    hs.eventtap.keyStroke({ "ctrl" }, "G", 200000, hs.application.get('Microsoft OneNote')) --要发送到特定应用，不然会重新引起hyper键的回调
    doClickAndRestore(nb1pos, 0)
end)

local switch_nb2 = hs.hotkey.new(hyperKey1, "]", function()
    -- doKeyStroke({ "alt", "ctrl" }, "return")
    hs.eventtap.keyStroke({ "ctrl" }, "G", 200000, hs.application.get('Microsoft OneNote'))
    doClickAndRestore(nb2pos, 0)
end)

-- ⌘⇧K 复制粘贴连接
-- 发送同一个键需要加 nil https://groups.google.com/g/hammerspoon/c/yp4AvJr5v7Q/m/74F-rsPZAgAJ
local pasteLink = hs.hotkey.new({"cmd", "shift"}, "K", nil, function()
    hs.eventtap.keyStroke({ "cmd" }, "K", 50000, hs.application.get('Microsoft OneNote')) --最快了
    hs.eventtap.keyStroke({ "cmd" }, "V", 50000, hs.application.get('Microsoft OneNote'))
    hs.eventtap.keyStroke({}, "return", 50000, hs.application.get('Microsoft OneNote'))
end)

-- hs.hotkey.bind 会使快捷键被全局覆盖，以后其他应用无法检测到该快捷键，这种写法就不会
function appWatcherFun_onenote(appName, eventType, appObject)
    if (appName == "Microsoft OneNote") then
        if (eventType == hs.application.watcher.activated) then
            -- hs.alert.show("已聚焦到 Microsoft OneNote")
            switch_nb1:enable()
            switch_nb2:enable()
            pasteLink:enable()
        end
        if (eventType == hs.application.watcher.deactivated) then
            -- hs.alert.show("已失焦")
            switch_nb1:disable()
            switch_nb2:disable()
            pasteLink:disable()
        end
    end
end

appWatcher_onenote = hs.application.watcher.new(appWatcherFun_onenote)
appWatcher_onenote:start()

-------------------------  访达  -------------------------
-- 复制文件全名

local copyFullname = hs.hotkey.new({"alt"}, "C", function()
    local a = hs.application.get('访达')
    hs.eventtap.keyStroke({}, "return", 50000, a) --50000是最快的，再快不行了
    hs.eventtap.keyStroke({ "cmd" }, "A", 50000, a)
    hs.eventtap.keyStroke({ "cmd" }, "C", 50000, a)
    hs.eventtap.keyStroke({}, "return", 50000, a)
end)

function appWatcherFun_finder(appName, eventType, appObject)
    if (appName == "访达") then
        if (eventType == hs.application.watcher.activated) then
            -- hs.alert.show("已聚焦到 访达")
            copyFullname:enable()
        end
        if (eventType == hs.application.watcher.deactivated) then
            -- hs.alert.show("已失焦")
            copyFullname:disable()
        end
    end
end

appWatcher_finder = hs.application.watcher.new(appWatcherFun_finder)
appWatcher_finder:start()




-------------------------  Chrome  -------------------------
--在chrome中转译hyperkey

hyper_chrome = hs.hotkey.modal.new({}, "f19")
-- function hyper_chrome:entered() hs.alert'Entered mode' end
-- function hyper_chrome:exited()  hs.alert'Exited mode'  end
-- hyper_chrome:bind('', 'escape', function() hyper_chrome:exit() end)
hyper_chrome:bind(hyperKey1, 'tab', function() 
    hs.eventtap.keyStroke({ "ctrl" }, "tab", 0, hs.application.get('Google Chrome'))
end)
hyper_chrome:bind(hyperKey3, 'tab', function() 
    hs.eventtap.keyStroke({ "ctrl", "shift" }, "tab", 0, hs.application.get('Google Chrome'))
end)

function appWatcherFun_chrome(appName, eventType, appObject)
    if (appName == "Google Chrome") then
        if (eventType == hs.application.watcher.activated) then
            hyper_chrome:enter()
        end
        if (eventType == hs.application.watcher.deactivated) then
            hyper_chrome:exit()
        end
    end
end

appWatcher_chrome = hs.application.watcher.new(appWatcherFun_chrome)
appWatcher_chrome:start()


-------------------------  微信 自动登录 hs.application.watcher 实现 -------------------------

function appWatcherFun_weixin(appName, eventType, appObject)
    -- 如果没有在此之前指定应用名称则对所有app都适用
    if (appName == "微信") then
        if eventType == hs.application.watcher.launched then
            wx = hs.application.get('微信')
            dl = wx:findWindow('登录')
            if dl == nil then 
            else
                hs.eventtap.keyStroke({}, "return", 200000, wx)
            end
        end
    end
end

appWatcher_weixin = hs.application.watcher.new(appWatcherFun_weixin)
appWatcher_weixin:start()


-------------------------  PDF Expert  -------------------------


local open_outline = hs.hotkey.new(hyperKey1, "]", function()
    hs.eventtap.keyStroke({ "cmd", "alt" }, "2", 0, hs.application.get('PDF Expert')) --要发送到特定应用，不然会重新引起hyper键的回调
    hs.eventtap.keyStroke({ "cmd" }, "9", 0, hs.application.get('PDF Expert'))
end)

local close_outline = hs.hotkey.new(hyperKey1, "[", function()
    hs.eventtap.keyStroke({ "cmd", "alt" }, "5", 0, hs.application.get('PDF Expert'))
    hs.eventtap.keyStroke({ "cmd" }, "9", 0, hs.application.get('PDF Expert'))
end)

local function pdfQuickAddText(obsObj,axUiObj,typeStr,table)
    local role = axUiObj:attributeValue("AXRole")
    if role == 'AXMenu' then --当右键菜单打开时执行
        local callback = function(msg, results, count)
            local but = results[1]
            but:performAction("AXPress")
            UIWatcher_pdfexpert:callback(nil) --不再对右键菜单自动点击按钮
            hs.application.launchOrFocus('PDF Expert') --通过url scheme唤醒会把焦点切走，用快捷键触发则无需此行
        end
        local criteria = function(axui) --该函数接受一个uielement，如果符合返回true否则返回false
            return axui:matchesCriteria({attribute ='AXTitle', value='文本'})
        end
        local results = axUiObj:elementSearch(callback, criteria)
    end
end


function appWatcherFun_pdfexpert(appName, eventType, appObject)
    if (appName == "PDF Expert") then
        if (eventType == hs.application.watcher.activated) then
            -- hs.alert.show("已聚焦到 PDF Expert")
            open_outline:enable()
            close_outline:enable()
            if UIWatcher_pdfexpert==nil then UIWatcher_pdfexpert = appImeHint(appName) end
        end
        if (eventType == hs.application.watcher.deactivated) then
            -- hs.alert.show("已失焦")
            open_outline:disable()
            close_outline:disable()
        end
        if (eventType == hs.application.watcher.launched) then 
            UIWatcher_pdfexpert = appImeHint(appName)
            UIWatcher_pdfexpert:callback(nil)
        end
        if (eventType == hs.application.watcher.terminated) then 
            UIWatcher_pdfexpert = nil
        end
    end
end

appWatcher_pdfexpert = hs.application.watcher.new(appWatcherFun_pdfexpert)
appWatcher_pdfexpert:start()

-- hs.hotkey.bind(hyperKey1, 'c', function()
--     UIWatcher_pdfexpert:callback(pdfQuickAddText)
--     hs.eventtap.rightClick(hs.mouse.absolutePosition(), 0)
-- end)

--Bind to 'hammerspoon://pdfexpert_add_text':
hs.urlevent.bind("pdfexpert_add_text", function(eventName, params, senderPID)
    UIWatcher_pdfexpert:callback(pdfQuickAddText)
    hs.eventtap.rightClick(hs.mouse.absolutePosition(), 0)
end)


-------------------------  URL Scheme: Clash 更新config并添加自定义命令  -------------------------

--Bind to 'hammerspoon://clash_update_config':
hs.urlevent.bind("clash_update_config", function(eventName, params, senderPID)

local _,success= hs.execute("curl 'https://sub.fastyunhub.top/link/vHRKVDgresgd9Ff2?mu=22&is_ss=2&type=0' -o /Users/lingzhi/.config/clash/merge.yaml")

if success then 
    hs.execute([[
sed -i '' '/rules:/a\
 - DOMAIN-KEYWORD,deepl, 🚀 节点选择\
 - DOMAIN-SUFFIX,onedrive.live.com, 🚀 节点选择\
 - DOMAIN-SUFFIX,pushbullet.com, 🚀 节点选择\
 - DOMAIN-SUFFIX,notion.so, 🚀 节点选择\
 - DOMAIN-SUFFIX,lookup-api.apple.com, 🚀 节点选择\
 - DOMAIN-KEYWORD,microsoftstream, 🚀 节点选择\
\
\
' '/Users/lingzhi/.config/clash/merge.yaml'
]])
else hs.alert('下载config失败')
end

end)






