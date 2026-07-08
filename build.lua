--[[
    Infinite Yield Mobile Reborn
    Build Script
    This file serves as the entry point for the application.
    In development, it's a modular structure.
    For production/executor use, the src/ folder can be zipped and required as a whole.
]]

-- Return the main init module
return require(script.Parent.init)