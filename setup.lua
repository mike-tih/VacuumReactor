-- setup with "wget https://raw.githubusercontent.com/mike-tih/VacuumReactor/refs/heads/main/setup.lua && setup"

local shell = require('shell')
local args = {...}
local branch
local repo
local scripts = {
    'start.lua',
    'config.lua',
    'functions.lua',
    'setReactor.lua',
    '.shrc',
}

-- BRANCH
if #args >= 1 then
    branch = args[1]
else
    branch = 'main'
end

-- REPO
if #args >= 2 then
    repo = args[2]
else
    repo = 'https://raw.githubusercontent.com/mike-tih/VacuumReactor/'
end

-- INSTALL
for i=1, #scripts do
    shell.execute(string.format('wget -f %s%s/%s', repo, branch, scripts[i]))
end