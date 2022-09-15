local queries = require"escriba.queries"

---Get a list containing all lines matching a query. The list writes the
---bound defining each match: {1, 2} means matched from line 1 to line 2
---@param query table #Treesitter latex query to be analysed
---@param root table #Treesitter syntax tree root node
---@param bufnr number #Buffer of the file where the query is performed
---@return table #List-like table containing the lines containing matched nodes.
local function get_all_lines_matching_query(query, root, bufnr)
    local matches = query:iter_matches(root, bufnr)
    if not matches then return {} end

    local bounds = {}
    for _, _, metadata in matches do
        local lbound, _, ubound, _ = unpack(metadata.content[1])
        table.insert(bounds, {lbound, ubound})
    end
    return bounds
end

---Check if the current line number is inside any of the bounds
---@param lnum number #Line number of be analysed
---@param bounds table #List-like table containing the bounds
local function is_inside_matches(lnum, bounds)
    if (next(bounds) == nil) then return false end
    for _, region in ipairs(bounds) do
        local is_inside = (region[1] <= lnum) and (lnum <= region[2])
        if is_inside then return true end
    end
    return false
end

---Get all bounds required to check if a line is inside a paragraph. Only call this
---function if the syntax tree has been modified.
---@param root table #Treesitter syntax tree root
---@param bufnr number #Buffer of the file where the query is performed
---@return table #Table containing all required list-like bounds
local function get_all_bounds_required(root, bufnr)
    return {
        text_bounds = get_all_lines_matching_query(queries.text_query, root, bufnr),
        genv_bounds = get_all_lines_matching_query(queries.genv_query, root, bufnr),
        menv_bounds = get_all_lines_matching_query(queries.menv_query, root, bufnr),
        senv_bounds = get_all_lines_matching_query(queries.senv_query, root, bufnr),
        tgen_bounds = get_all_lines_matching_query(queries.tgen_query, root, bufnr),
        inlm_bounds = get_all_lines_matching_query(queries.inlm_query, root, bufnr),
        gcmd_bounds = get_all_lines_matching_query(queries.gcmd_query, root, bufnr),
    }
end

return {
    get_all_lines_matching_query = get_all_lines_matching_query,
    is_inside_matches            = is_inside_matches,
    get_all_bounds_required      = get_all_bounds_required,
}
