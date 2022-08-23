fx_version "cerulean"
game "gta5"

client_script 'dist/client.js'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'dist/server.js'
}

shared_scripts {
    'config.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/*.js',
}
