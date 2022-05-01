local events = hs.uielement.watcher
-- windowTracker.lua https://gist.github.com/cmsj/591624ef07124ad80a1c 

function GetTableLng(tbl)
    -- https://stackoverflow.com/questions/2705793/how-to-get-number-of-entries-in-a-lua-table
    local getN = 0
    for n in pairs(tbl) do 
        getN = getN + 1 
    end
    return getN
end


watchers = {}
allowAppNames = {'文本编辑', '预览', }
-- allowAppBundleID = {'com.apple.TextEdit', 'com.apple.Preview', }
--'com.apple.Preview'有别名，即使使用bundleID还是会报Some applications have alternate names 

-- 查看watch的对象 i(watchers[27649].windows[14653]:element()) 

function init()
    appsWatcher = hs.application.watcher.new(handleGlobalAppEvent)
    appsWatcher:start()

    for k, v in ipairs(allowAppNames) do
        watchApp(hs.application.get(v), true)
    end

    -- -- Watch any apps that already exist
    -- local apps = hs.application.runningApplications() --这种方式获取到的app太多了，导致reload巨慢
    -- for i = 1, #apps do
    --     if apps[i]:title() ~= "Hammerspoon" then
    --     watchApp(apps[i], true)
    --     end
    -- end
end

function tableContains(table, element)
    for _, value in pairs(table) do
        if value == element then
        return true
        end
    end
    return false
end

--有app启动就加watcher，有app关闭就清理watcher。三个参数是appName, eventType, appObject
function handleGlobalAppEvent(name, event, app)
    if not tableContains(allowAppNames, name) then return end --如果allowAppNames不包含就不处理该app
    -- if name~='文本编辑' and name~='预览' and name~='PDF Expert' then return end
    if event == hs.application.watcher.launched then
        watchApp(app)
        elseif event == hs.application.watcher.terminated then
        -- Clean up
        local appWatcher = watchers[app:pid()]
        if appWatcher then --如果里面有这个app的Watcher
            appWatcher.watcher:stop()
            for id, watcher in pairs(appWatcher.windows) do
                watcher:stop()
            end
            watchers[app:pid()] = nil
        end
    end
end

--为启动的app添加watcher。参数是appObject, initializing=nil(在watchWindow中是否显示提示)
function watchApp(app, initializing)
    if not app then return end --防止需要观察的app没打开
    if watchers[app:pid()] then return end

    local watcher = app:newWatcher(handleAppEvent, {app=app}) --object:newWatcher(...) = hs.uielement.newWatcher(object, ...)
    watchers[app:pid()] = {watcher = watcher, windows = {}}

    watcher:start({events.windowCreated, events.focusedWindowChanged})

    -- Watch any windows that already exist
    for i, window in pairs(app:allWindows()) do
        watchWindow(window, initializing)
    end
end

-- 处理app层面事件，如窗口的创建和销毁
function handleAppEvent(element, event, watcher, info)
    if event == events.windowCreated then --给后续新建窗口加watcher
        watchWindow(element)
    elseif event == events.focusedWindowChanged then
    -- Handle window change
    end
end


function watchWindow(win, initializing)
    
    if win:title()== '打开' then return end
    -- local a = hs.application.get('PDF Expert'):findWindow('新建标签') 
    -- if win:application():name() == 'PDF Expert' and win:title()~='新建标签' and a then a:close() end
    
    local appWindows = watchers[win:application():pid()].windows
    if win:isStandard() and not appWindows[win:id()] then
        local watcher = win:newWatcher(handleWindowEvent, {pid=win:pid(), id=win:id()})
        appWindows[win:id()] = watcher

        watcher:start({events.elementDestroyed, events.windowResized, events.windowMoved})

        if not initializing then --注意(not nil) = true
        -- hs.alert.show('window created: '..win:id()..' with title: '..win:title())
        end
    end
end

-- 处理window层面事件，如uielement的创建和销毁，窗口移动、改变大小等
function handleWindowEvent(win, event, watcher, info)
    if event == events.elementDestroyed then --如果窗口关闭就删掉该window的watcher
        watcher:stop()
        watchers[info.pid].windows[info.id] = nil 
        
        if GetTableLng(watchers[info.pid].windows) == 0 then hs.application.get(info.pid):kill() end
    else
        -- Handle other events...
    end
    -- hs.alert.show('window event '..event..' on '..info.id)
end

init()


