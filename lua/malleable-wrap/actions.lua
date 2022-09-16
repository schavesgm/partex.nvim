-- Load some needed functions
local utils               = require"malleable-wrap.utils"
local is_inside_paragraph = require"malleable-wrap.is_inside".is_inside_paragraph
local get_all_bounds      = require"malleable-wrap.treesitter".get_all_bounds_required

---Find the line where the current paragraph starts
---@param lnum number #Current line to be used as reference
---@param bounds table #Table containing all the required bounds in the current syntax tree
local function find_paragraph_start(lnum, bounds)
    if not is_inside_paragraph(lnum, bounds) then return -1 end
    for _, line in ipairs(vim.fn.reverse(vim.fn.range(1, lnum - 1))) do
        if not is_inside_paragraph(line, bounds) then
            return line + 1
        end
        if line == 1 then
            return line
        end
    end
end

---Find the line where the current paragraph terminates
---@param lnum number #Current line to be used as reference
---@param bounds table #Table containing all the required bounds in the current syntax tree
local function find_paragraph_end(lnum, bounds)
    if not is_inside_paragraph(lnum, bounds) then return -1 end
    local last_line = vim.fn.line('$')
    for _, line in ipairs(vim.fn.range(lnum + 1, vim.fn.line('$'))) do
        if not is_inside_paragraph(line, bounds) then
            return line - 1
        end
        if (line == last_line) then
            return line
        end
    end
    return lnum
end

---Find the lines defining the current paragraph. Useful to select paragraphs
---@param lnum number #Current line to be used as reference
---@param bounds table #Table containing the required bounds for the current buffer
local function get_paragraph_limits(lnum, bounds)
    return {find_paragraph_start(lnum, bounds), find_paragraph_end(lnum, bounds)}
end

---Find the line where the next paragraph starts from the current line
---@param lnum number #Current line to be used as reference
---@param bounds table #Table containing the required bounds for the current buffer
local function get_next_paragraph(lnum, bounds)
    local start_line = lnum
    if is_inside_paragraph(lnum, bounds) then
        local paragraph_end = find_paragraph_end(lnum, bounds)
        if paragraph_end + 1 < vim.fn.line('$') then
            start_line = paragraph_end + 1
        end
    end
    for _, line in ipairs(vim.fn.range(start_line, vim.fn.line('$'))) do
        if is_inside_paragraph(line, bounds) then return line end
    end
    return lnum
end

---Select inside the current paragraph
---@param bounds? table #Table containing the bounds of the current buffer
local function select_inside_paragraph(bounds)
    local lnum  = vim.fn.line('.')
    if (bounds == nil) then
        local bufnr  = vim.api.nvim_get_current_buf()
        local tree   = vim.treesitter.get_parser(bufnr, 'latex')
        bounds = get_all_bounds(tree:parse()[1]:root(), bufnr)
    end

    local plims = get_paragraph_limits(lnum, bounds)
    if (plims == nil) then return end
    if (plims[1] == (-1)) or (plims[2] == (-1)) then return end
    vim.cmd('execute "normal ' .. plims[1] .. 'GV' .. plims[2] .. 'G"')
end

---Move to the next paragraph from the current line
---@param bounds? table #Table containing the bounds of the current buffer
local function move_to_next_paragraph(bounds)
    local lnum  = vim.fn.line('.')
    if (bounds == nil) then
        local bufnr  = vim.api.nvim_get_current_buf()
        local tree   = vim.treesitter.get_parser(bufnr, 'latex')
        bounds = get_all_bounds(tree:parse()[1]:root(), bufnr)
    end
    local next_paragraph = get_next_paragraph(lnum, bounds)
    vim.fn.cursor(next_paragraph, 1)
end

---Act with a command over each paragraph in the document. The command must use
---"ip" as the object of the action; "ip" stands for "inside paragraph"
---Examples:
---       vipgq  -- Select the paragraph and then apply gq
---       cipHey -- Change each paragraph to "Hey"
---       dip    -- Delete all paragraphs
---@param command string #String defining the command to use at each paragraph.
local function act_over_each_paragraph(command)

    -- TODO: Here there is a factor of two in get_all_bounds that needs to be removed
    local bufnr = vim.api.nvim_get_current_buf()
    local tree  = vim.treesitter.get_parser(bufnr, 'latex')

    -- Save the current keymaps to replace them in the future
    local nkeymap = utils.get_keymap('n', 'vip')
    local okeymap = utils.get_keymap('o', 'ip')

    -- Get some needed variables
    local cursor, col, prev_par = vim.fn.line('.'), vim.fn.col('.'), vim.fn.line('.')

    -- Table containing the bounds
    local bounds = {}

    -- Wrapper around select_inside_paragraph with desired bounds
    local function wrapper_sip()
        select_inside_paragraph(bounds)
    end

    -- Set some needed keybinding for this function
    vim.keymap.set("o", "ip",  wrapper_sip, {silent=true, buffer=true})
    vim.keymap.set("n", "vip", wrapper_sip, {silent=true, buffer=true})

    vim.fn.cursor(1, 1)
    while true do
        -- Update the bounds and the previous paragraph on the current buffer
        bounds = get_all_bounds(tree:parse()[1]:root(), bufnr)
        prev_par = vim.fn.line('.')
        local next_paragraph = get_next_paragraph(vim.fn.line('.'), bounds)
        vim.fn.cursor(next_paragraph, 1)
        vim.cmd(string.format('execute "normal %s"', command))
        if prev_par == next_paragraph then
            break
        end
    end

    -- Get back to the initial status
    utils.set_keymap(nkeymap)
    utils.set_keymap(okeymap)
    vim.fn.cursor(cursor, col)
end

return {
    find_paragraph_start    = find_paragraph_start,
    find_paragraph_end      = find_paragraph_end,
    get_paragraph_limits    = get_paragraph_limits,
    get_next_paragraph      = get_next_paragraph,
    select_inside_paragraph = select_inside_paragraph,
    move_to_next_paragraph  = move_to_next_paragraph,
    act_over_each_paragraph = act_over_each_paragraph,
}
