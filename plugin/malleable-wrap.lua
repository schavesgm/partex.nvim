if 1 ~= vim.fn.has("nvim-0.7.0") then
    vim.api.nvim_err_writeln "escriba.nvim requires at least nvim-0.7.0."
    return
end

-- If the plugin is loaded, then ignore this call
if vim.g.loaded_escriba == 1 then
    return
end
vim.g.loaded_escriba = 1
