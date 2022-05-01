

------------------------- replace Logi  -------------------------
if_but3 = false
if_but4 = false

but3Dragged = false
but4Dragged = false
but4Scrolled = false

-- otherMouseDragged 包含 otherMouseUp 和 otherMouseDown
-- 所以要在 butDownCallback, butUpCallback 里加 return true 去阻断 button 3 4 本身的事件
-- 而且并不需要在 otherMouseDragged 里阻断，那样写没有用
-- 下面这种写法阻断了所有 Button 3 4 的 Down 事件
butDownCallback = hs.eventtap.new({hs.eventtap.event.types.otherMouseDown}, function(e)
    local button = e:getProperty(hs.eventtap.event.properties['mouseEventButtonNumber'])
    if button == 3 then
        if_but3 = true
        return true
    end
    if button == 4 then
        if_but4 = true
        return true
    end
end)

butDownCallback:start() -- 一定要记得 start 这个 hs.eventtap.new

-- 可以分应用给键分配动作
-- 在 up 那一刻触发，所以记录的位置是 up 那一刻的位置
-- 为不同应用分配 button 动作 https://tom-henderson.github.io/2018/12/14/hammerspoon.html
butUpCallback = hs.eventtap.new({hs.eventtap.event.types.otherMouseUp}, function(e)
    local button = e:getProperty(hs.eventtap.event.properties['mouseEventButtonNumber'])

    if (button == 3) then
        if_but3 = false
        if but3Dragged then
            -- hs.alert("无动作")
        elseif not but3Dragged then
            hs.application.launchOrFocus("Mission Control.app")
        end
        but3Dragged = false
        return true  --还是要屏蔽掉按键本身，也就需要保留if_but3来判断按键是否按下
    end

    if (button == 4) then
        if_but4 = false
        if but4Dragged then
            -- hs.alert("无动作")
        elseif but4Scrolled then
            -- hs.alert("无动作")
        elseif not but4Dragged then
            doKeyStroke({ "alt", "ctrl" }, "return")
        end
        but4Dragged = false
        but4Scrolled = false
        return true 
    end
    
end)

butUpCallback:start()


------------------------- Button 3 4  -------------------------
-- 如果不在这里中断 butUpCallback，在每次抬起按键时(包括otherMouseDragged)
-- 都会触发一次 butUpCallback
local function but_context(function_do)
    mainDraggedCallback:stop()

    function_do()
    
    -- hs.timer.usleep(100000) --不再需要了
    mainDraggedCallback:start()
end


local but3up = function() 
    doKeyStroke({ "alt" }, "Q") 
    print('发送 3 up') 
end

local but3down = function() 
    hs.application.launchOrFocus("Launchpad.app") 
    print('发送 3 down') 
end

local but3left = function() 
    doKeyStroke({ "cmd" }, "tab") 
    doKeyStroke({ }, "return") 
    print('发送 3 left') 
end

local but3right = function() 
    doKeyStroke({ "cmd" }, "`") 
    print('发送 3 right') 
end

local but4up = function() 
    doKeyStroke({ "alt" }, "S") 
    print('发送 4 up') 
end

local but4down = function() 
    doKeyStroke({ "alt" }, "D") 
    print('发送 4 down') 
end

local but4left = function() 
    doKeyStroke({ "ctrl", "alt" }, ",") 
    print('发送 4 left') 
end

local but4right = function() 
    doKeyStroke({ "ctrl", "alt" }, "/") 
    print('发送 4 right') 
end




-- 可以同时存在两个针对右键的回调函数
-- 需要在此函数中屏蔽 button 3 4
mainDraggedCallback = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDragged }, function(e)
    -- local a = hs.eventtap.checkMouseButtons()
    
    if but3Dragged == true or but4Dragged == true then return end --未抬起按键时不会二次触发动作
    local dx = e:getProperty(hs.eventtap.event.properties['mouseEventDeltaX'])
    local dy = e:getProperty(hs.eventtap.event.properties['mouseEventDeltaY'])
    
    if math.abs(dy) > 12 or math.abs(dx) > 12 then
        if but4Scrolled then return end --防止滚动中移动鼠标触发动作
        
        local xdirec = (math.abs(dx) > math.abs(dy))
        local butterNum = e:getProperty(hs.eventtap.event.properties['mouseEventButtonNumber'])

        if butterNum == 3 then
            but3Dragged = true
            if xdirec then
                if dx < 0 then
                    but_context(but3left)
                end
                if dx > 0 then
                    but_context(but3right)
                end
            elseif not xdirec then
                if dy < 0 then
                    but_context(but3up)
                end
                if dy > 0 then
                    but_context(but3down)
                end
            end
            
        end

        if butterNum == 4 then
            but4Dragged = true
            if xdirec then
                if dx < 0 then
                    but_context(but4left)
                end
                if dx > 0 then
                    but_context(but4right)
                end
            elseif not xdirec then
                if dy < 0 then
                    but_context(but4up)
                end
                if dy > 0 then
                    but_context(but4down)
                end
            end
            
        end

    end


end)

mainDraggedCallback:start()


--------------------------------------------------
-- scrollWheel
--------------------------------------------------


-- 使用 applescript 切换桌面
-- https://stackoverflow.com/questions/46818712/using-hammerspoon-and-the-spaces-module-to-move-window-to-new-space
local function moveWindowOneSpace(direction)
    local keyCode = direction == "left" and 123 or 124
    return hs.osascript.applescript([[
        tell application "System Events" 
            keystroke (key code ]] .. keyCode .. [[ using control down)
        end tell
    ]])
end

scrollmultX = 12
scrollmultY = -20

scrollWheelCallback = hs.eventtap.new({hs.eventtap.event.types.scrollWheel}, function(e)

    local isContinuous = e:getProperty(hs.eventtap.event.properties.scrollWheelEventIsContinuous)
    -- 要考虑到触摸板同样是左右滚动
    if isContinuous == 0 then
        
        local scroll_d1 = e:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis1)
        if scroll_d1 ~= 0 then
            -- local a = hs.eventtap.checkMouseButtons()
            -- print(a[1],a[2],a[3],a[4],a[5])
            if if_but4 then --如果按住了 but4 就横向滑动
                but4Scrolled = true
                e:setType(hs.eventtap.event.types.nullEvent)  --null纵向滚动事件
                local scroll = hs.eventtap.event.newScrollEvent({scroll_d1 * scrollmultX, 0},{},'pixel')
                return false, {scroll} --发布横向滚动事件
            -- elseif not if_but4 then --如果没按住 but4 就反向纵向滑动
            --     local scroll = hs.eventtap.event.newScrollEvent({0, scroll_d1 * scrollmultY},{},'pixel')
            --     return false, {scroll}
            end
        end

        local scroll_d2 = e:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis2)
        if scroll_d2 ~= 0 then
            if if_but4 then
                but4Scrolled = true
                if scroll_d2 > 0 then
                    hs.eventtap.keyStroke({ }, "end")
                    return true
                elseif scroll_d2 < 0 then
                    hs.eventtap.keyStroke({ }, "home")
                    return true
                end
            elseif if_but3 then
                -- hs.alert('333')
            else
                if scroll_d2 > 0 then
                    moveWindowOneSpace("right")
                    return true
                elseif scroll_d2 < 0 then
                    moveWindowOneSpace("left")
                    return true
                end
            end
        end

    end

end)

scrollWheelCallback:start()
