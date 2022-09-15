local M = {}

-- Wrap over the escriba actions module to expose it
M.actions = require"escriba.actions"

---Format the document to a given length
---@param opts table #Argument to be passed from command
local function format_document(opts)
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
    local config = {
        create_excmd = true,
        keymaps = {
            set = true,
            operator = {
                select_inside_lhs = 'ip',
            },
            normal = {
                select_inside_lhs = 'ip',
                move_to_next_paragraph = 'np',
            }
        }
    }
    config = (settings) and vim.tbl_deep_extend('force', config, settings) or config
    local augroup = vim.api.nvim_create_augroup('Escriba', {clear=false})

    -- Create the excommand if desired
    if settings.create_excmd then
        vim.api.nvim_create_autocmd('FileType', {
            pattern='tex',
            callback=function()
                local bufnr = vim.api.nvim_get_current_buf()
                vim.api.nvim_buf_create_user_command(bufnr, 'FormatTex', format_document, {bang=true, nargs='?'})
            end,
            group=augroup,
        })
    end

    -- Create the keybindings if desired
    if settings.keymaps.set then
        vim.api.nvim_create_autocmd('FileType', {
            pattern='tex',
            callback=function()
                -- Set the keymaps to select paragraphs
                vim.keymap.set("o", "ip",  M.actions.select_inside_paragraph)
                vim.keymap.set("n", "vip", M.actions.select_inside_paragraph)

                -- Set keymap to move to the following paragraph
                vim.keymap.set("n", "np", M.actions.move_to_next_paragraph)
            end,
            group=augroup,
        })
    end
end

return M
