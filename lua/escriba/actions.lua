local M = {}

-- Load some needed functions
local is_inside_paragraph = require"escriba.is_inside".is_inside_paragraph

---Find the line where the current paragraph starts
---@param lnum number #Current line to be used as reference
M.find_paragraph_start = function(lnum)
    if not is_inside_paragraph(lnum) then return -1 end
    for _, line in ipairs(vim.fn.reverse(vim.fn.range(1, lnum - 1))) do
        local is_first = (line == 1)
        if not is_inside_paragraph(line) or is_first then
            return line + 1
        end
    end
end

---Find the line where the current paragraph terminates
---@param lnum number #Current line to be used as reference
M.find_paragraph_end = function(lnum)
    if not is_inside_paragraph(lnum) then return -1 end
    for _, line in ipairs(vim.fn.range(lnum + 1, vim.fn.line('$'))) do
        local is_last = (line == vim.fn.line('$'))
        if not is_inside_paragraph(line) or is_last then
            return line + (is_last and 0 or -1)
        end
    end
    return lnum
end

---Find the lines defining the current paragraph. Useful to select paragraphs
M.get_paragraph_limits = function(lnum)
    return {M.find_paragraph_start(lnum), M.find_paragraph_end(lnum)}
end

---Find the line where the next paragraph starts
---@param lnum number #Current line to be used as reference
M.get_next_paragraph = function(lnum)
    local start_line = lnum
    if is_inside_paragraph(lnum) then
        local paragraph_end = M.find_paragraph_end(lnum)
        if paragraph_end + 1 < vim.fn.line('$') then
            start_line = paragraph_end + 1
        end
    end

    for _, line in ipairs(vim.fn.range(start_line, vim.fn.line('$'))) do
        if is_inside_paragraph(line) then return line end
    end
    return lnum
end

return M
