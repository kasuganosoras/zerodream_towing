RegisterServerEvent('zerodream_towing:CreateRope')
RegisterServerEvent('zerodream_towing:RemoveRope')
RegisterServerEvent('zerodream_towing:LoadRopes')

_g = {
    ropeList = {},
}

function IsRopeExists(netId1, netId2)
    for _, rope in pairs(_g.ropeList) do
        if (rope.netId1 == netId1 and rope.netId2 == netId2) or (rope.netId1 == netId2 and rope.netId2 == netId1) then
            return true
        end
    end
    return false
end

AddEventHandler('zerodream_towing:CreateRope', function(netId1, netId2)
    if not IsRopeExists(netId1, netId2) then
        table.insert(_g.ropeList, {
            netId1 = netId1,
            netId2 = netId2,
        })
        TriggerClientEvent("zerodream_towing:CreateRope", -1, netId1, netId2)
    end
end)

AddEventHandler('zerodream_towing:RemoveRope', function(netId1, netId2)
    for k,v in pairs(_g.ropeList) do
        if v.netId1 == netId1 and v.netId2 == netId2 then
            table.remove(_g.ropeList, k)
            TriggerClientEvent("zerodream_towing:RemoveRope", -1, netId1, netId2)
            break
        end
    end
end)

AddEventHandler('zerodream_towing:LoadRopes', function()
    TriggerClientEvent("zerodream_towing:LoadRopes", -1, _g.ropeList)
end)
