
--https://stackoverflow.com/questions/46750313/comparing-tables-in-lua-where-keys-are-tables
function deepCompare(t1, t2)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then
        return false
    end
    -- non-table types can be directly compared
    if ty1 ~= "table" and ty2 ~= "table" then
        return t1 == t2
    end

    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not deepCompare(v1, v2) then
            return false
        end
    end
    for k2, v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not deepCompare(v1, v2) then
            return false
        end
    end
    return true
end

-------------------------  搜狗输入法中英提示  -------------------------

-- hs.hotkey.bind(hyperKey1, 'c', function() hs.alert(hs.uielement.focusedElement():role()) end)

-- hs.hotkey.bind(hyperKey1, 'v', function() 
--     shift_twice()
-- end)

shiftDown = hs.eventtap.event.newKeyEvent(hs.keycodes.map.capslock, true)
shiftUp = hs.eventtap.event.newKeyEvent(hs.keycodes.map.capslock, false)

-- 读完hs.eventtap.keyStroke的源码看到newKeyEvent，因为keyStroke不能只发送modifier
-- 来自此处的例子 https://www.hammerspoon.org/docs/hs.eventtap.event.html#newKeyEvent
function shift_twice()
    shiftDown:post()
    shiftUp:post()
    -- shiftDown:post()
    -- shiftUp:post()
    -- hs.osascript.applescript('tell application "System Events" to key code 56')
end


lastUiParentFrame = {}
function showImeHint_chrome(obsObj,axUiObj,typeStr,table)
    local currentUiParentFrame = axUiObj:attributeValue("AXParent"):attributeValue("AXFrame")
    -- local appName = hs.application.applicationForPID(axUiObj:pid()):name()
    -- print(i(axUiObj:attributeNames()))
    -- print(i(axUiObj:allAttributeValues()))
    local role = axUiObj:attributeValue("AXRole")
    -- hs.alert(role)

    if typeStr == "AXFocusedWindowChanged" then --切换窗口重置
        local lastUiParentFrame = {}
        local a = hs.eventtap.checkMouseButtons()
        -- print(a[1],a[2],a[3],a[4],a[5])
        if a[1] == true then
            obsObj:callback(nil)
            hs.timer.doAfter(0.01, function() obsObj:callback(showImeHint_chrome) end)
        end
    elseif typeStr == "AXFocusedUIElementChanged" then
        -- hs.alert(role)
        if role == "AXTextField" or role == "AXTextArea" or role == "AXComboBox" then
            -- debugElement(axUiObj)
    
            local sameUiPosition = deepCompare(currentUiParentFrame, lastUiParentFrame)
            if not sameUiPosition then
                -- hs.alert(i(obsObj))
                print("AXTextArea")
                obsObj:callback(nil) --这样接连数次触发时，第二次往后就会错过回调函数的执行
                shift_twice()
                hs.timer.doAfter(0.01, function() obsObj:callback(showImeHint_chrome) end)
            elseif sameUiPosition then
                -- hs.alert("两个ui位置相同")
            end
        end
        lastUiParentFrame = currentUiParentFrame --update lastUiParentFrame
    
    end

end


function showImeHint(obsObj,axUiObj,typeStr,table)
    local role = axUiObj:attributeValue("AXRole")
    -- hs.alert(role)
    if role == "AXTextField" or role == "AXTextArea" or role == "AXComboBox" then
        -- hs.alert(i(obsObj))
        print("AXTextArea")
        obsObj:callback(nil) --这样接连数次触发时，第二次往后就会错过回调函数的执行
        shift_twice()
        hs.timer.doAfter(0.01, function() obsObj:callback(showImeHint) end)
    end
end


function appImeHint(appName)
    local tarApp = hs.application(appName)
    if tarApp == nil then
        return nil
    elseif appName == "Google Chrome" then --为chrome单独分配回调函数
        local axObs = ax.observer.new(tarApp:pid())
        axObs:callback(showImeHint_chrome)
        axObs:addWatcher(ax.applicationElement(hs.application(appName)), "AXFocusedUIElementChanged")
        axObs:addWatcher(ax.applicationElement(hs.application(appName)), "AXFocusedWindowChanged")
        axObs:start()
        return axObs
    else 
        local axObs = ax.observer.new(tarApp:pid())
        axObs:callback(showImeHint)
        axObs:addWatcher(ax.applicationElement(hs.application(appName)), "AXFocusedUIElementChanged")
        axObs:start()
        return axObs
    end
end


-- 用于菜单栏app
local imeHintApps = {'Bob', }
imeHintTb = {}
for i, app in ipairs(imeHintApps) do
    -- table.insert(imeHintTb, appImeHint(app))
    imeHintTb[app] = appImeHint(app)
end


-- 用于桌面app
local function rejectApp(appName)
    -- local rejectAppNames = { "Google Chrome", "Hammerspoon" }
    local rejectAppNames = { "Hammerspoon" }
    for i, win in ipairs(rejectAppNames) do
        if win == appName then
            return false
        end
    end
    return true
end

function appWatcherFun_imeHint(appName, eventType, appObject)
    --新启动app时算launched，不算activated。不用考虑菜单栏app
    if rejectApp(appName) then 
        if (eventType == hs.application.watcher.launched) then 
            imeHintTb[appName] = appImeHint(appName)
        end
        if (eventType == hs.application.watcher.terminated) then 
            imeHintTb[appName] = nil
        end
        if (eventType == hs.application.watcher.activated) then --reload时已经打开的app通过activated创建observer
            if imeHintTb[appName] ~= nil then
                -- hs.alert('有该app的observer')
            elseif imeHintTb[appName] == nil then
                imeHintTb[appName] = appImeHint(appName)
                -- hs.alert('没有该app的observer')
            end
            
        end
    end
end

appWatcher_imeHint = hs.application.watcher.new(appWatcherFun_imeHint)
appWatcher_imeHint:start()







