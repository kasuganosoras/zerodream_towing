-- Register Events
RegisterNetEvent("zerodream_towing:SetTowVehicle")
RegisterNetEvent("zerodream_towing:FreeTowing")
RegisterNetEvent("zerodream_towing:CreateRope")
RegisterNetEvent("zerodream_towing:RemoveRope")
RegisterNetEvent("zerodream_towing:LoadRopes")

-- Event handles
AddEventHandler("zerodream_towing:SetTowVehicle", function(vehicle) SetTowVehicle(vehicle) end)
AddEventHandler("zerodream_towing:FreeTowing", function() FreeTowing() end)
AddEventHandler("zerodream_towing:CreateRope", function(netId1, netId2) CreateRopeEvent(netId1, netId2) end)
AddEventHandler("zerodream_towing:RemoveRope", function(netId1, netId2) RemoveRopeEvent(netId1, netId2) end)
AddEventHandler("zerodream_towing:LoadRopes", function(ropeList) LoadRopesEvent(ropeList) end)

-- Variables
_g = {
    isTowing   = false,
    length     = 0,
    ropeHandle = {},
}

-- Commands
RegisterCommand("tow", function(source, args, rawCommand)
    local vehicle = GetClosestVehicle(GetEntityCoords(PlayerPedId()), 10.0, 0, 127)
    if DoesEntityExist(vehicle) then
        SetTowVehicle(vehicle)
    end
end, false)

-- Functions
function SetTowVehicle(vehicle)
    -- 检测是否已经在牵引中
    if not _g.isTowing and not _g.secondEntity then
        local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
        -- 检查是否设置了牵引车
        if not _g.firstEntity then
            if IsVehicleCanTowing(vehicle) then
                _g.firstEntity = NetworkGetNetworkIdFromEntity(vehicle)
                SendNotification('default', string.format(Config.texts.towCarDone, vehicleName))
            else
                SendNotification('error', Config.texts.notAllowed)
            end
        elseif not _g.secondEntity then
            if IsVehicleCanBeTowing(vehicle) and vehicle ~= NetworkGetEntityFromNetworkId(_g.firstEntity) then
                local distance = #(GetEntityCoords(vehicle) - GetEntityCoords(NetworkGetEntityFromNetworkId(_g.firstEntity)))
                if distance < 20.0 then
                    local pos1   = GetWorldPositionOfEntityBone(NetworkGetEntityFromNetworkId(_g.firstEntity), bone1)
                    local pos2   = GetWorldPositionOfEntityBone(vehicle, bone2) - Config.towingOffset
                    _g.secondEntity = NetworkGetNetworkIdFromEntity(vehicle)
                    _g.isTowing     = true
                    _g.length       = #(pos1 - pos2)
                    SendNotification('default', string.format(Config.texts.towingDone, vehicleName))
                    -- 开始牵引
                    TriggerServerEvent("zerodream_towing:CreateRope", _g.firstEntity, _g.secondEntity)
                else
                    SendNotification('error', Config.texts.tooFarAway)
                end
            else
                SendNotification('error', Config.texts.notAllowed)
            end
        end
    else
        SendNotification('default', Config.texts.towRemoved)
        TriggerServerEvent("zerodream_towing:RemoveRope", _g.firstEntity, _g.secondEntity)
        _g.isTowing     = false
        _g.firstEntity  = nil
        _g.secondEntity = nil
    end
end

function FreeTowing()
    if _g.isTowing then
        TriggerServerEvent("zerodream_towing:RemoveRope", _g.firstEntity, _g.secondEntity)
        _g.isTowing     = false
        _g.firstEntity  = nil
        _g.secondEntity = nil
    end
end

function FindRopeByNetworkId(netId1, netId2)
    for id, rope in pairs(_g.ropeHandle) do
        if rope.netId1 == netId1 and rope.netId2 == netId2 then
            return rope
        end
    end
    return nil
end

function AttachRope(rope, entity1, entity2)
    local bone1  = GetEntityBoneIndexByName(entity1, Config.towCarBone)
    local bone2  = GetEntityBoneIndexByName(entity2, Config.towBone)
    local pos1   = GetWorldPositionOfEntityBone(entity1, bone1)
    local pos2   = GetWorldPositionOfEntityBone(entity2, bone2) - Config.towingOffset
    local length = #(pos1 - pos2)
    AttachEntitiesToRope(rope, entity1, entity2, pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z, length, false, false, nil, nil)
    StopRopeUnwindingFront(rope)
    StartRopeWinding(rope)
    RopeForceLength(rope, length)
end

function CreateRope(pos)
    RopeLoadTextures()
    local rope = AddRope(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, Config.maxRopeLength, 1, Config.maxRopeLength, 0.25, 0.0, false, true, false, 5.0, false, 0)
    table.insert(_g.ropeHandle, {
        id = rope,
        index = #_g.ropeHandle + 1,
    })
    return #_g.ropeHandle
end

function RemoveRope(id)
    if DoesRopeExist(id) then
        StopRopeUnwindingFront(id)
        StopRopeWinding(id)
        RopeConvertToSimple(id)
    end
end

function IsVehicleCanTowing(vehicle)
    if not Config.allowNpcCar then
        if not DoesEntityExist(vehicle) or not NetworkGetEntityIsNetworked(vehicle) or not IsEntityAMissionEntity(vehicle) then
            return false
        end
    end
    return GetEntityBoneIndexByName(vehicle, Config.towCarBone) ~= -1
end

function IsVehicleCanBeTowing(vehicle)
    if not Config.allowNpcCar then
        if not DoesEntityExist(vehicle) or not NetworkGetEntityIsNetworked(vehicle) or not IsEntityAMissionEntity(vehicle) then
            return false
        end
    end
    return GetEntityBoneIndexByName(vehicle, Config.towBone) ~= -1
end

function GetDesiredLength(entity1, entity2)
    local bone1  = GetEntityBoneIndexByName(entity1, Config.towCarBone)
    local bone2  = GetEntityBoneIndexByName(entity2, Config.towBone)
    local pos1   = GetWorldPositionOfEntityBone(entity1, bone1)
    local pos2   = GetWorldPositionOfEntityBone(entity2, bone2)
    local length = #(pos1 - pos2)
    return math.min(GetRopeLength(rope), length)
end

function CreateRopeEvent(netId1, netId2)
    if NetworkDoesNetworkIdExist(netId1) and NetworkDoesNetworkIdExist(netId2) then
        local entity1 = NetworkGetEntityFromNetworkId(netId1)
        local entity2 = NetworkGetEntityFromNetworkId(netId2)
        if IsVehicleCanTowing(entity1) and IsVehicleCanBeTowing(entity2) then
            local ropeIndex  = CreateRope(GetEntityCoords(entity1))
            local ropeHandle = _g.ropeHandle[ropeIndex].id
            _g.ropeHandle[ropeIndex].netId1 = netId1
            _g.ropeHandle[ropeIndex].netId2 = netId2
            AttachRope(ropeHandle, entity1, entity2)
        end
    end
end

function RemoveRopeEvent(netId1, netId2)
    local rope    = FindRopeByNetworkId(netId1, netId2)
    local entity1 = NetworkGetEntityFromNetworkId(netId1)
    local entity2 = NetworkGetEntityFromNetworkId(netId2)
    if rope then
        RemoveRope(rope.id)
        DetachRopeFromEntity(rope.id, entity1)
        DetachRopeFromEntity(rope.id, entity2)
        DeleteRope(rope.id)
        table.remove(_g.ropeHandle, rope.index)
        if _g.firstEntity == netId1 and _g.secondEntity == netId2 then
            _g.firstEntity  = nil
            _g.secondEntity = nil
            _g.isTowing     = false
        end
    end
end

function LoadRopesEvent(ropeList)
    for k, v in pairs(ropeList) do
        if not FindRopeByNetworkId(v.netId1, v.netId2) then
            TriggerEvent("zerodream_towing:CreateRope", v.netId1, v.netId2)
        end
    end
end

function Draw2DText(x, y, size, text)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(size, size)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

function SendNotification(theme, message)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(true, false)
end

function DisplayHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, 0, 1, -1)
end

-- Main Thread
Citizen.CreateThread(function()
    -- Wait for game finish loading
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(0)
    end
    -- Wait for 5s
    Citizen.Wait(5000)
    -- Load all created ropes
    TriggerServerEvent('zerodream_towing:LoadRopes')
    -- Main thread loop
    while true do
        -- Check if is towing
        if _g.isTowing then
            -- Get entities and rope
            local firstEntity  = NetworkGetEntityFromNetworkId(_g.firstEntity)
            local secondEntity = NetworkGetEntityFromNetworkId(_g.secondEntity)
            local rope         = FindRopeByNetworkId(_g.firstEntity, _g.secondEntity)
            local distance     = #(GetEntityCoords(firstEntity) - GetEntityCoords(secondEntity))
            -- Check if entities exists and not too far
            if not DoesEntityExist(firstEntity) or not DoesEntityExist(secondEntity) or distance > Config.maxRopeLength * 2 then
                if rope then
                    _g.isTowing = false
                    SendNotification("error", Config.texts.ropeBroken)
                    TriggerServerEvent('zerodream_towing:RemoveRope', _g.firstEntity, _g.secondEntity)
                end
            -- Check if car too fast
            elseif GetEntitySpeed(firstEntity) > Config.brokenSpeed then
                if rope then
                    _g.isTowing = false
                    SendNotification("error", Config.texts.carTooFast)
                    TriggerServerEvent('zerodream_towing:RemoveRope', _g.firstEntity, _g.secondEntity)
                end
            else
                -- Check rope length
                if _g.length > Config.maxRopeLength then
                    _g.length = Config.maxRopeLength
                end
                SetVehicleHandbrake(secondEntity, false)
            end
            -- Reduce rope length
            if IsControlPressed(0, Config.reduceLength) then
                _g.length = _g.length - Config.lengthTick
                if _g.length < Config.minRopeLength then
                    _g.length = Config.minRopeLength
                end
                if rope then
                    StopRopeWinding(rope.id)
                    StartRopeUnwindingFront(rope.id)
                    RopeForceLength(rope.id, _g.length)
                end
            elseif IsControlJustReleased(0, Config.reduceLength) then
                if rope then
                    StopRopeUnwindingFront(rope.id)
                    StopRopeWinding(rope.id)
                    RopeConvertToSimple(rope.id)
                end
            -- Increase rope length
            elseif IsControlPressed(0, Config.addLength) then
                _g.length = _g.length + Config.lengthTick
                if _g.length > Config.maxRopeLength then
                    _g.length = Config.maxRopeLength
                end
                if rope then
                    StopRopeUnwindingFront(rope.id)
                    StartRopeWinding(rope.id)
                    RopeForceLength(rope.id, _g.length)
                end
            elseif IsControlJustReleased(0, Config.addLength) then
                if rope then
                    StopRopeUnwindingFront(rope.id)
                    StopRopeWinding(rope.id)
                    RopeConvertToSimple(rope.id)
                end
            -- All keys released
            else
                if rope then
                    StopRopeUnwindingFront(rope.id)
                    StartRopeWinding(rope.id)
                    RopeConvertToSimple(rope.id)
                end
            end
            -- Towing status
            if Config.displayStatus and IsMinimapRendering() then
                local vehicleName1 = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(firstEntity)))
                local vehicleName2 = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(secondEntity)))
                Draw2DText(0.20, 0.90, 0.3, string.format(Config.texts.towCarName, vehicleName1))
                Draw2DText(0.20, 0.92, 0.3, string.format(Config.texts.towingName, vehicleName2))
                Draw2DText(0.20, 0.94, 0.3, string.format(Config.texts.ropeLength, _g.length))
            end
        end
        if _g.firstEntity and not _g.secondEntity then
            DisplayHelpText(Config.texts.helpNotice)
            if IsControlJustPressed(0, 194) then
                _g.firstEntity = nil
            end
        end
        if Config.debug then
            Draw2DText(0.5, 0.15, 0.4, "isTowing: " .. (_g.isTowing and "true" or "false"))
            Draw2DText(0.5, 0.20, 0.4, "Length: " .. _g.length)
        end
        Wait(0)
    end
end)
