# ZeroDream Towing
Vehicle towing system for FiveM

![Screenshots](https://i.imgur.com/tStbDzL.png)

## Features
- Towing cars
- Network synchronized ropes
- Controllable rope length
- No framework require

## Installation
1. Clone or download this repo
2. Copy the `zerodream_towing` folder to your server resources folder
3. Add `start zerodream_towing` to your server.cfg
4. Restart the server

## API
**SetTowVehicle:** Use this function to set the towing car, you have to call it two times to set the first and second vehicle.
```lua
local vehicleA = GetVehiclePedIsIn(GetPlayerPed(-1), false)
local vehicleB = GetVehiclePedIsIn(GetPlayerPed(2), false)
exports["zerodream_towing"]:SetTowVehicle(vehicleA)
exports["zerodream_towing"]:SetTowVehicle(vehicleB)
```
**FreeTowing:** This function will detach the cars immediately.
```lua
if IsControlJustPressed(0, 51) then
  exports["zerodream_towing"]:FreeTowing()
end
```

## Credit
PocceMod: https://github.com/razzie/PocceMod

## License
zerodream_towing - Vehicle towing script for FiveM

Copyright (C) 2022 Akkariin

This program Is free software: you can redistribute it And/Or modify it under the terms Of the GNU General Public License As published by the Free Software Foundation, either version 3 Of the License, Or (at your option) any later version.

This program Is distributed In the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty Of MERCHANTABILITY Or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License For more details.

You should have received a copy Of the GNU General Public License along with this program. If Not, see http://www.gnu.org/licenses/.
