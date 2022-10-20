-- Load some needed functions
local utils               = require"partex.utils"
local is_inside_paragraph = require"partex.is_inside".is_inside_paragraph
local get_all_bounds      = require"partex.treesitter".get_all_bounds_required

---Find the line where the current paragraph starts
---@param lnum number #Current line to be used as reference
---@param bounds table #Table containing all the required bounds in the current syntax tree
---@return number #Line number where the current paragraph starts or -1 if not inside paragraph
local function get_paragraph_start(lnum, bounds)
    if not is_inside_paragraph(lnum, bounds) then return -1 end
    for _, line in ipairs(vim.fn.reverse(vim.fn.range(1, lnum - 1))) do
        if not is_inside_paragraph(line, bounds) then
            return line + 1
        end
        if line == 1 then
            return line
        end
    end
    return lnum
end

---Find the line where the current paragraph terminates
---@param lnum number #Current line to be used as reference
---@param bounds table #Table containing all the required bounds in the current syntax tree
---@return number #Line number where the current paragraph starts or -1 if not inside paragraph
local function get_paragraph_end(lnum, bounds)
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
    return {get_paragraph_start(lnum, bounds), get_paragraph_end(lnum, bounds)}
end

---Find the line where the next paragraph starts from the current line
---@param lnum number #Current line to be used as reference
---@param bounds table #Table containing the required bounds for the current buffer
local function get_next_paragraph(lnum, bounds)
    local start_line = lnum
    if is_inside_paragraph(lnum, bounds) then
        local paragraph_end = get_paragraph_end(lnum, bounds)
        if paragraph_end + 1 < vim.fn.line('$') then
            start_line = paragraph_end + 1
        end
    end
    for _, line in ipairs(vim.fn.range(start_line, vim.fn.line('$'))) do
        if is_inside_paragraph(line, bounds) then return line end
    end
    return lnum
end

---Find the line where the previous paragraph starts from the current line
---@param lnum number #Current line to be used as reference
---@param bounds table #Table containing the required bounds for the current buffer
local function get_previous_paragraph(lnum, bounds)
    local start_line = lnum
    if start_line == 1 then return lnum end
    if is_inside_paragraph(lnum, bounds) then
        start_line = get_paragraph_start(lnum, bounds) - 1
    end
    for _, line in ipairs(vim.fn.reverse(vim.fn.range(1, start_line))) do
        local current_is_par  = is_inside_paragraph(line, bounds)
        local previous_is_par = is_inside_paragraph(line - 1, bounds)
        local condition = current_is_par and not previous_is_par
        if condition then return line end
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

---Move to the previous paragraph from the current line
---@param bounds? table #Table containing the bounds of the current buffer
local function move_to_previous_paragraph(bounds)
    local lnum  = vim.fn.line('.')
    if (bounds == nil) then
        local bufnr  = vim.api.nvim_get_current_buf()
        local tree   = vim.treesitter.get_parser(bufnr, 'latex')
        bounds = get_all_bounds(tree:parse()[1]:root(), bufnr)
    end
    local previous_paragraph = get_previous_paragraph(lnum, bounds)
    vim.fn.cursor(previous_paragraph, 1)
end

---Move to the begining of the current paragraph
---@param bounds? table #Table containing the bounds of the current buffer
local function move_to_paragraph_start(bounds)
    local lnum  = vim.fn.line('.')
    if (bounds == nil) then
        local bufnr  = vim.api.nvim_get_current_buf()
        local tree   = vim.treesitter.get_parser(bufnr, 'latex')
        bounds = get_all_bounds(tree:parse()[1]:root(), bufnr)
    end
    local paragraph_start = get_paragraph_start(lnum, bounds)
    if (paragraph_start ~= -1) then
        vim.fn.cursor(paragraph_start, 1)
    end
end

---Move to the end of the current paragraph
---@param bounds? table #Table containing the bounds of the current buffer
local function move_to_paragraph_end(bounds)
    local lnum  = vim.fn.line('.')
    if (bounds == nil) then
        local bufnr  = vim.api.nvim_get_current_buf()
        local tree   = vim.treesitter.get_parser(bufnr, 'latex')
        bounds = get_all_bounds(tree:parse()[1]:root(), bufnr)
    end
    local paragraph_end = get_paragraph_end(lnum, bounds)
    if (paragraph_end ~= -1) then
        vim.fn.cursor(paragraph_end, 1)
    end
end

---Act with a command over each paragraph in the document. The command must use
---"ip" as the object of the action; "ip" stands for "inside paragraph". The
---actions are performed in reverse order to minimise the number of treesitter
---calls.
---Examples:
---       vipgq  -- Select the paragraph and then apply gq
---       cipHey -- Change each paragraph to "Hey"
---       dip    -- Delete all paragraphs
---@param command string #String defining the command to use at each paragraph.
local function act_over_each_paragraph(command)
    local bufnr = vim.api.nvim_get_current_buf()
    local tree  = vim.treesitter.get_parser(bufnr, 'latex')
    local bounds = get_all_bounds(tree:parse()[1]:root(), bufnr)

    -- Save the current keymaps to replace them in the future
    local nkeymap = utils.get_keymap('n', 'vip')
    local okeymap = utils.get_keymap('o', 'ip')

    -- Save the current column to go back at the end
    local col = vim.fn.col('.')

    -- Wrapper around select_inside_paragraph with desired bounds
    local function wrapper_sip()
        select_inside_paragraph(bounds)
    end

    -- Set some needed keybinding for this function
    vim.keymap.set("o", "ip",  wrapper_sip, {silent=true, buffer=true})
    vim.keymap.set("n", "vip", wrapper_sip, {silent=true, buffer=true})

    local cursor = vim.fn.line('$')
    vim.fn.cursor(cursor, 1)
    while true do
        cursor = vim.fn.line('.')
        local prev_par = get_previous_paragraph(vim.fn.line('.'), bounds)
        vim.fn.cursor(prev_par, 1)
        vim.cmd(string.format('execute "normal %s"', command))
        if prev_par == cursor then
            break
        end
    end

    -- Get back to the initial status
    utils.set_keymap(nkeymap)
    utils.set_keymap(okeymap)
    vim.fn.cursor(cursor, col)
end

return {
    get_paragraph_start        = get_paragraph_start,
    get_paragraph_end          = get_paragraph_end,
    get_paragraph_limits       = get_paragraph_limits,
    get_next_paragraph         = get_next_paragraph,
    get_previous_paragraph     = get_previous_paragraph,
    select_inside_paragraph    = select_inside_paragraph,
    move_to_next_paragraph     = move_to_next_paragraph,
    move_to_previous_paragraph = move_to_previous_paragraph,
    move_to_paragraph_start    = move_to_paragraph_start,
    move_to_paragraph_end      = move_to_paragraph_end,
    act_over_each_paragraph    = act_over_each_paragraph,
}
