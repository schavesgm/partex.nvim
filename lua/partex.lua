local M = {}

-- Expose some functions 
M.actions = vim.tbl_deep_extend("force",
    require"partex.actions",
    {
        get_all_bounds_required = require"partex.treesitter".get_all_bounds_required,
        is_inside_paragraph     = require"partex.is_inside".is_inside_paragraph,
    }
)

---Format the document to a given length
---@param opts table #Argument to be passed from command
local function format_document(opts)
    if vim.bo.filetype ~= "tex" then
        vim.notify("Filetype is not tex. Ignoring...", vim.log.levels.WARN)
        return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local args  = opts.args

    local textwidth = vim.bo.textwidth
    if args == "" then
        if (vim.bo.textwidth == 0) then
            vim.notify('textwidth is not defined. Ignoring call...', vim.log.levels.WARN)
            return
        end
    else
        textwidth = tonumber(opts.args)
    end
    vim.api.nvim_buf_set_option(bufnr, 'textwidth',  textwidth)
    vim.api.nvim_set_option_value('colorcolumn', '+1', {scope='local'})
    M.actions.act_over_each_paragraph("vipgq")
end

---Configure the plugina according to some settings
M.setup = function(settings)

    -- Default configuration of the plugin
    M.config = {
        create_excmd = true,
        keymaps = {
            set = true,
            operator = {
                select_inside = "ip",
            },
            normal = {
                select_inside = "vip",
                move_to_next  = "np",
                move_to_prev  = "Np",
                move_to_end   = "mp",
                move_to_start = "Mp",
            }
        }
    }
    if (settings ~= nil) then
        M.config = vim.tbl_deep_extend("force", M.config, settings)
    end

    -- Create the excommand if desired
    if M.config.create_excmd then
        vim.api.nvim_create_user_command('FormatTex', format_document, {bang=true, nargs='?'})
    end

    -- Create the keybindings if desired
    if M.config.keymaps.set then

        ---@param callback function: Callback function to execute after wrapping
        local filetype_wrapper = function(callback)
            if vim.bo.filetype ~= "tex" then
                vim.notify("Filetype is not tex. Ignoring...", vim.log.levels.WARN)
                return
            end
            return callback
        end

        local keymaps = M.config.keymaps
        -- Set the keymaps to select paragraphs
        vim.keymap.set("o", keymaps.operator.select_inside,  filetype_wrapper(M.actions.select_inside_paragraph))
        vim.keymap.set("n", keymaps.normal.select_inside,    filetype_wrapper(M.actions.select_inside_paragraph))

        -- Set keymap to move to the following paragraph
        vim.keymap.set("n", keymaps.normal.move_to_next,  filetype_wrapper(M.actions.move_to_next_paragraph))
        vim.keymap.set("n", keymaps.normal.move_to_prev,  filetype_wrapper(M.actions.move_to_previous_paragraph))
        vim.keymap.set("n", keymaps.normal.move_to_start, filetype_wrapper(M.actions.move_to_paragraph_start))
        vim.keymap.set("n", keymaps.normal.move_to_end,   filetype_wrapper(M.actions.move_to_paragraph_end))
    end
end

return M
