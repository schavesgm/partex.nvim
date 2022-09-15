-- Regex employed to match lines
local keywords = 'section\\|subsection\\|subsubsection\\|chapter\\|documentclass'
local regex_emptyline = vim.regex("\\(^$\\)\\|\\(^\\s\\+$\\)")
local regex_keywdline = vim.regex(".*\\\\\\(" .. keywords .. "\\|begin\\).*")

-- Needed functions to be used in the analysis
local is_inside_matches       = require"escriba.treesitter".is_inside_matches

---Check if a line is treated as special: contains special keywords or is empty
---@param lnum number #Line number to be checked: vim-like indexing (1, $)
---@return boolean
local function is_special_line(lnum)
    local bufnr = vim.api.nvim_get_current_buf()
    local is_empty = (regex_emptyline:match_line(bufnr, lnum - 1) ~= nil)
    local is_keywr = (regex_keywdline:match_line(bufnr, lnum - 1) ~= nil)
    return (is_empty or is_keywr)
end


---Check if a given line is inside a LaTeX paragraph in the current syntax tree
---@param lnum number #Line number of be checked: vim-like indexing (1, $)
---@param bounds table #Table containing all required bounds
local function is_inside_paragraph(lnum, bounds)
    if not is_inside_matches(lnum, bounds.text_bounds) then
        return false
    end

    local not_special_line = not is_special_line(lnum)
    local not_inside_genv  = not is_inside_matches(lnum, bounds.genv_bounds)
    local not_inside_menv  = not is_inside_matches(lnum, bounds.menv_bounds)
    local not_inside_senv  = not is_inside_matches(lnum, bounds.senv_bounds)

    if (not_special_line and not_inside_genv and not_inside_menv and not_inside_senv) then
        local has_cmd = is_inside_matches(lnum, bounds.gcmd_bounds)
        if not has_cmd then
            return true
        else
            local is_inside_tgen = is_inside_matches(lnum, bounds.tgen_bounds)
            local is_inside_inlm = is_inside_matches(lnum, bounds.inlm_bounds)
            if not (is_inside_tgen and is_inside_inlm) then
                return true
            end
        end
    end
    return false
end

return {
    is_inside_paragraph = is_inside_paragraph
}
