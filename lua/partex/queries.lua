local parse_query = vim.treesitter.parse_query

-- Query employed to check if a line is text or not
local text_query = parse_query('latex', [[((text) @lines (#offset! @lines))]])

-- Query employed to check if a line is inside a generic environemt, not "document"
local genv_query = parse_query('latex',
[[
    (
        (generic_environment
            begin: (begin
                name: (curly_group_text) @marker (#not-any-of? @marker "{document}" "{abstract}")
            )
        ) @lines (#offset! @lines)
    )
]])

-- Query employed to check if a line is inside a math environment
local menv_query = parse_query('latex', [[((math_environment) @lines (#offset! @lines))]])

-- Query employed to check if a line is inside a special environment
local senv_query = parse_query('latex',
[[
    ((package_include) @lines (#offset! @lines))
    ((author_declaration) @lines (#offset! @lines))
    ((title_declaration) @lines (#offset! @lines))
]])

-- Query employed to check if a line is inside a text.generic_command
local tgen_query = parse_query('latex', [[((text (generic_command) @lines (#offset! @lines)))]])

-- Query employed to check if a line contains an inline_formula
local inlm_query = parse_query('latex', [[((inline_formula) @lines (#offset! @lines))]])

-- Query employed to check if a line has a generic_command
local gcmd_query = parse_query('latex', [[((generic_command) @lines (#offset! @lines))]])

return {
    text_query = text_query,
    genv_query = genv_query,
    menv_query = menv_query,
    senv_query = senv_query,
    tgen_query = tgen_query,
    inlm_query = inlm_query,
    gcmd_query = gcmd_query
}
