-- Regex employed to match lines
local keywords = 'section\\|subsection\\|subsubsection\\|chapter\\|documentclass'
local regex_emptyline = vim.regex("\\(^$\\)\\|\\(^\\s\\+$\\)")
local regex_keywdline = vim.regex(".*\\\\\\(" .. keywords .. "\\|begin\\).*")

-- Queries to be used in the analysis
local queries = require"escriba.queries"

---Check if a line is treated as special: contains special keywords or is empty
---@param lnum number #Line number to be checked: vim-like indexing (1, $)
---@return boolean
local function is_special_line(lnum)
    local bufnr = vim.api.nvim_get_current_buf()
    local is_empty = (regex_emptyline:match_line(bufnr, lnum - 1) ~= nil)
    local is_keywr = (regex_keywdline:match_line(bufnr, lnum - 1) ~= nil)
    return (is_empty or is_keywr)
end

---Get all lines matching a LaTeX query
---@param lnum number #Line number to be checked; vim-like indexing (1, $)
---@param root table #Root of the syntax tree to be used in the analysis
---@param query table #Query string to be processed
local function check_is_inside_query(lnum, root, query)
    local matches = query:iter_matches(root, vim.api.nvim_get_current_buf())
    if (matches == nil) then return {} end
    for _, _, metadata in matches do
        local lbound, ubound = metadata.content[1][1], metadata.content[1][3]
        local is_inside = (lbound <= lnum - 1) and (lnum - 1 <= ubound)
        if is_inside then return true end
    end
    return false
end

---Check if the current line is inside a text node
---@param lnum number #Line number to be checked; vim-like indexing (1, $)
---@param root table #Root of the syntax tree to be used in the analysis
local function is_inside_text(lnum, root)
    return check_is_inside_query(lnum, root, queries.text_query)
end

---Check if the current line is inside generic_environment, "document" is ignored
---@param lnum number #Line number to be checked; vim-like indexing (1, $)
---@param root table #Root of the syntax tree to be used in the analysis
local function is_inside_generic_environment(lnum, root)
    return check_is_inside_query(lnum, root, queries.genv_query)
end

---Check if the current line is inside a math_environment
---@param lnum number #Line number of be checked; vim-like indexing (1, $)
---@param root table #Root of the syntax tree to be used in the analysis
local function is_inside_math_environment(lnum, root)
    return check_is_inside_query(lnum, root, queries.menv_query)
end

---Check if the current line is inside several special environments
---@param lnum number #Line number to be checked; vim-like indexing (1, $)
---@param root table #Root of the syntax tree to be used in the analysis
local function is_inside_special_environment(lnum, root)
    -- Check if the current line is inside a special environment
    return check_is_inside_query(lnum, root, queries.senv_query)
end

---Check if the current line corresponds to an isolated command environment
---@param lnum number #Line number to be checked; vim-like indexing (1, $)
---@param root table #Root of the syntax tree to be used in the analysis
local function is_isolated_command(lnum, root)
    return not check_is_inside_query(lnum, root, queries.tgen_query) and
           not check_is_inside_query(lnum, root, queries.inlm_query)
end

---Check if the current line is inside a paragraph
---@param lnum number #Line number to be checked: vim-like indexing (1, $)
---@param root table #Root of the syntax tree to be used in the analysis
local function is_inside_paragraph(lnum, root)
    if not is_inside_text(lnum, root) then return false end
    local not_special_line = not is_special_line(lnum)
    local not_inside_genv  = not is_inside_generic_environment(lnum, root)
    local not_inside_menv  = not is_inside_math_environment(lnum, root)
    local not_inside_senv  = not is_inside_special_environment(lnum, root)
    local above_conditions = not_special_line and not_inside_genv and not_inside_menv and not_inside_senv

    if above_conditions then
        local has_cmd = check_is_inside_query(lnum, root, queries.gcmd_query)
        if not has_cmd then
            return true
        else
            if not is_isolated_command(lnum, root) then return true end
        end
    end
    return false
end

return {
    is_inside_paragraph = is_inside_paragraph
}
