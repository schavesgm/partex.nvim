---Get a keymap table on a given mode, filtering by lhs keystroke
---@param mode string #Neovim mode
---@param lhs string  #Keystroke to filter
local function get_keymap(mode, lhs)
    local keymaps, found = vim.api.nvim_get_keymap(mode), nil
    for _, keymap in ipairs(keymaps) do
        if (keymap.lhs == lhs) then
            found = keymap
            break
        end
    end
    return found
end

---Set a keymap from a keymap table
---@param keymap table #Table containing the keymap definition
local function set_keymap(keymap)
    if (keymap == nil) then return end
    local rhs  = (keymap.expr == 0) and keymap.callback or keymap.expr
    local opts = {buffer=keymap.buffer, silent=keymap.silent, remap=not keymap.noremap}
    vim.keymap.set(keymap.mode, keymap.lhs, rhs, opts)
end

return {
    get_keymap     = get_keymap,
    set_keymap     = set_keymap,
}
