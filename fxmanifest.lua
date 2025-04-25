fx_version 'cerulean'
game 'gta5'

description 'Project Sentinel - Admin System with Report System and Discord Integration'
author 'Lucentix'
version '1.0.0'

ui_page 'web/build/index.html'

shared_scripts {
    'shared/logger.lua'
}

client_scripts {
    'client/error_handler.lua',  -- Load error handler first
    'client/main.lua',
    'client/commands.lua',
    'client/debug_tools.lua'
}

server_scripts {
    'server/json_storage.lua',
    'server/error_handler.lua',  -- Add the server error handler
    'server/bootstrapper.lua',
    'server/main.lua',
    'server/permission_handler.lua'
}

files {
    'web/build/index.html',
    'web/build/**/*'
}

dependencies {
    'oxmysql',  -- For database operations
}