fx_version  'cerulean'
games       {'gta5'}
author      'Akkariin'
description 'ZeroDream Vehicle Towing System'
version     '1.0.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

exports {
    'SetTowVehicle',
    'FreeTowing',
}
