-- obfuscate_offsets.lua
-- Module to obfuscate and protect memory offsets in Lua

local obfuscate_offsets = {}

-- Dynamic key generation for obfuscation
local function generate_key()
    local key = {}
    for i = 1, 16 do
        key[i] = math.random(0, 255)
    end
    return key
end

local key = generate_key()

-- XOR encode/decode function
local function xor_crypt(data, key)
    local result = {}
    for i = 1, #data do
        local key_byte = key[((i - 1) % #key) + 1]
        result[i] = string.char(bit32.bxor(data:byte(i), key_byte))
    end
    return table.concat(result)
end

-- Store obfuscated offsets internally
local obfuscated_offsets = {}

-- Register an offset (as string, e.g. "0x134D3C"), obfuscate and store it
function obfuscate_offsets.register_offset(name, offset_str)
    -- Obfuscate offset string
    local obf = xor_crypt(offset_str, key)
    obfuscated_offsets[name] = obf
end

-- Retrieve and decode an offset by name
function obfuscate_offsets.get_offset(name)
    local obf = obfuscated_offsets[name]
    if not obf then
        error("Offset not found: " .. tostring(name))
    end
    local decoded = xor_crypt(obf, key)
    return decoded
end

-- Anti-hook detection: simple self-checking function
local function self_check()
    -- Check if this function's bytecode has been tampered with
    local info = debug.getinfo(self_check)
    if not info or not info.func then
        return false
    end
    local dumped = string.dump(info.func)
    -- Simple heuristic: check length of dumped function
    if #dumped < 20 then
        return false
    end
    return true
end

-- Punishment function: terminate script or cause error
local function punish()
    error("Hooking or tampering detected! Execution terminated.")
end

-- Periodic check for hooking/tampering
local function anti_hook_check()
    if not self_check() then
        punish()
    end
end

-- Public function to call periodically or before offset usage
function obfuscate_offsets.check_protection()
    anti_hook_check()
end

-- Function to rotate key at runtime (re-obfuscate all offsets)
function obfuscate_offsets.rotate_key()
    local new_key = generate_key()
    local new_obfuscated = {}
    for name, obf in pairs(obfuscated_offsets) do
        local decoded = xor_crypt(obf, key)
        new_obfuscated[name] = xor_crypt(decoded, new_key)
    end
    key = new_key
    obfuscated_offsets = new_obfuscated
end

-- Randomized transformation example (simple)
local function random_transform(offset_str)
    -- Reverse string and append random char
    local reversed = offset_str:reverse()
    local rand_char = string.char(math.random(65, 90))
    return reversed .. rand_char
end

-- Example wrapper to register offset with random transform
function obfuscate_offsets.register_offset_advanced(name, offset_str)
    local transformed = random_transform(offset_str)
    local obf = xor_crypt(transformed, key)
    obfuscated_offsets[name] = obf
end

-- Example wrapper to get offset with reverse transform
function obfuscate_offsets.get_offset_advanced(name)
    local obf = obfuscated_offsets[name]
    if not obf then
        error("Offset not found: " .. tostring(name))
    end
    local decoded = xor_crypt(obf, key)
    -- Remove last char and reverse back
    local trimmed = decoded:sub(1, -2)
    local original = trimmed:reverse()
    return original
end

return obfuscate_offsets
