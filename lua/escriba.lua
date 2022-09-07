local actions = require"escriba.actions"
local utils   = require"escriba.utils"

---Select inside the current paragraph
local function select_inside_paragraph()
    local lnum = vim.fn.line('.')
    local lims = actions.get_paragraph_limits(lnum)
    if (lims[1] == (-1)) or (lims[2] == (-1)) then return end
    vim.cmd('execute "normal ' .. lims[1] .. 'GV' .. lims[2] .. 'G"')
end

---Move to the next paragraph from the current line
local function move_to_next_paragraph()
    local lnum = vim.fn.line('.')
    local next_paragraph = actions.get_next_paragraph(lnum)
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
    -- Save the current keymaps to replace them in the future
    local nkeymap = utils.get_keymap('n', 'vip')
    local okeymap = utils.get_keymap('o', 'ip')

    -- Get some needed variables
    local cursor, col, prev_par = vim.fn.line('.'), vim.fn.col('.'), vim.fn.line('.')

    -- Set some needed keybinding for this function
    vim.keymap.set("o", "ip",  select_inside_paragraph, {silent=true, buffer=true})
    vim.keymap.set("n", "vip", select_inside_paragraph, {silent=true, buffer=true})

    vim.fn.cursor(1, 1)
    while true do
        prev_par = vim.fn.line('.')
        local next_paragraph = actions.get_next_paragraph(vim.fn.line('.'))
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
    select_inside_paragraph = select_inside_paragraph,
    move_to_next_paragraph  = move_to_next_paragraph,
    act_over_each_paragraph = act_over_each_paragraph,
}
