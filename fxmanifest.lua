fx_version 'cerulean'
game 'gta5'

description 'Project Sentinel - Admin System with Report System and Discord Integration'
author 'Lucentix'
version '1.0.0'

ui_page 'web/build/index.html'

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

files {
    'web/build/index.html',
    'web/build/**/*'
}

dependencies {
    'oxmysql',  -- For database operations
}