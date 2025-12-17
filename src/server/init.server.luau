-- init.server.luau
-- Main entry point for The Ember Games server
-- This file bootstraps all server services

print("The Ember Games server initializing...")

-- Wait a moment for services to be ready
task.wait(1)

-- Require and run ServerMain which initializes all services
local ServerMain = require(script.Parent.ServerMain)

print("The Ember Games server started successfully!")