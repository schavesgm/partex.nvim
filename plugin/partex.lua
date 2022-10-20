if 1 ~= vim.fn.has("nvim-0.8.0") then
    vim.api.nvim_err_writeln "partex.nvim requires at least nvim-0.8.0."
    return
end

-- If the plugin is loaded, then ignore this call
if vim.g.loaded_partex == 1 then
    return
end
vim.g.loaded_partex = 1
