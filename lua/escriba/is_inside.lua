-- Regex employed to match lines
local keywords = 'section\\|subsection\\|subsubsection\\|chapter\\|documentclass'
local regex_emptyline = vim.regex("\\(^$\\)\\|\\(^\\s\\+$\\)")
local regex_keywdline = vim.regex(".*\\\\\\(" .. keywords .. "\\|begin\\).*")

---Check if a current line number is inside bounds
---@param lnum number #Line number to be checked; vim-like indexingz (1, $)
---@param bounds table #Table containing all the queried matches
local function is_inside_bounds(lnum, bounds)
    for _, limits in ipairs(bounds) do
        local is_inside = (limits[1] <= lnum - 1) and (lnum - 1 <= limits[2])
        if is_inside then return true end
    end
    return false
end

---Get all lines matching a LaTeX query
---@param query_str string #Query string to be processed
---@return table #Table containing all lines child of the queried nodes, empty table if no matches
local function get_lines_matching_query(query_str)
    local bufnr = vim.api.nvim_get_current_buf()
    local tree  = vim.treesitter.get_parser(bufnr, 'latex')
    local query = vim.treesitter.parse_query('latex', query_str)

    -- Get all the matches from the query
    local matches = query:iter_matches(tree:parse()[1]:root(), bufnr)
    if (matches == nil) then return {} end

    local bounds = {}
    for _, _, metadata in matches do
        local content = metadata.content[1]
        table.insert(bounds, {content[1], content[3]})
    end
    return bounds
end

---Check if the current line belongs to any of the matchs of a given query
---@param lnum number #Line number to be checked; vim-like indexing (1, $)
---@param query string #Query string to be processed
local function is_inside_query(lnum, query)
    local bounds = get_lines_matching_query(query)
    if next(bounds) == nil then return false end
    return is_inside_bounds(lnum, bounds)
end

---Check if the current line is inside a text node
---@param lnum number #Line number to be checked; vim-like indexing (1, $)
local function is_inside_text(lnum)
    return is_inside_query(lnum, [[((text) @lines (#offset! @lines))]])
end

---Check if a line is treated as special: contains special keywords or is empty
---@param lnum number #Line number to be checked: vim-like indexing (1, $)
---@return boolean
local function is_special_line(lnum)
    local bufnr = vim.api.nvim_get_current_buf()
    local is_empty = (regex_emptyline:match_line(bufnr, lnum - 1) ~= nil)
    local is_keywr = (regex_keywdline:match_line(bufnr, lnum - 1) ~= nil)
    return (is_empty or is_keywr)
end

---Check if the current line is inside generic_environment, "document" is ignored
---@param lnum number #Line number to be checked; vim-like indexing (1, $)
local function is_inside_generic_environment(lnum)
    return is_inside_query(lnum,
    [[
        (
            (generic_environment
                begin: (begin
                    name: (curly_group_text) @marker (#not-eq? @marker "{document}")
                )
            ) @lines (#offset! @lines)
        )
    ]])
end

---Check if the current line is inside a math_environment
---@param lnum number #Line number of be checked; vim-like indexing (1, $)
local function is_inside_math_environment(lnum)
    return is_inside_query(lnum, [[((math_environment) @lines (#offset! @lines))]])
end

---Check if the current line is inside several special environments
---@param lnum number #Line number to be checked; vim-like indexing (1, $)
local function is_inside_special_environment(lnum)
    -- Check if the current line is inside a special environment
    return is_inside_query(lnum,
    [[
        ((package_include) @lines (#offset! @lines))
        ((author_declaration) @lines (#offset! @lines))
        ((title_declaration) @lines (#offset! @lines))
    ]])
end

---Check if the current line corresponds to an isolated command environment
---@param lnum number #Line number to be checked; vim-like indexing (1, $)
local function is_isolated_command(lnum)
    return not is_inside_query(lnum,
        [[((text (generic_command) @lines (#offset! @lines)))]]
    ) and not is_inside_query(lnum,
        [[((inline_formula) @lines (#offset! @lines))]]
    )
end

---Check if the current line is inside a paragraph
---@param lnum number #Line number to be checked: vim-like indexing (1, $)
local function is_inside_paragraph(lnum)
    if not is_inside_text(lnum) then return false end
    local not_special_line = not is_special_line(lnum)
    local not_inside_genv  = not is_inside_generic_environment(lnum)
    local not_inside_menv  = not is_inside_math_environment(lnum)
    local not_inside_senv  = not is_inside_special_environment(lnum)

    if not_special_line and not_inside_genv and not_inside_menv and not_inside_senv then
        local has_cmd = is_inside_query(lnum, [[((generic_command) @lines (#offset! @lines))]])
        if not has_cmd then
            return true
        else
            if not is_isolated_command(lnum) then return true end
        end
    end
    return false
end

return {
    is_inside_generic_environment = is_inside_generic_environment,
    is_inside_math_environment    = is_inside_math_environment,
    is_inside_special_environment = is_inside_special_environment,
    is_special_line               = is_special_line,
    is_isolated_command           = is_isolated_command,
    is_inside_paragraph           = is_inside_paragraph
}
