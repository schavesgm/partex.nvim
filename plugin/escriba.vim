"" TODO: Make the iteration faster by caching the TreeSitter queries

lua << EOF
    local actions = require"escriba"

    ---Format the document to a given length
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
        actions.act_over_each_paragraph("vipgq")
    end

    ---Set the needed keybindings
    local function set_autocommand()
        -- Set the keymaps to select paragraphs
        vim.keymap.set("o", "ip",  actions.select_inside_paragraph)
        vim.keymap.set("n", "vip", actions.select_inside_paragraph)

        -- Set keymap to move to the following paragraph
        vim.keymap.set("n", "np", actions.move_to_next_paragraph)

        -- Generate a user command to format the document
        vim.api.nvim_buf_create_user_command(vim.api.nvim_get_current_buf(), 'FormatTex', format_document, {bang=true, nargs='?'})
    end

    -- Create an autogroup for a set of autocommands
    local augroup = vim.api.nvim_create_augroup('Escriba', {clear=true})

    -- Set the keymaps to select the paragraphs
    vim.api.nvim_create_autocmd('FileType', {
            pattern='tex',
            callback=set_autocommand,
            group=autogroup,
        }
    )
EOF
