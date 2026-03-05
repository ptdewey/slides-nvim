vim.api.nvim_create_user_command(
    "SlidesStart",
    function() require("slides").start() end,
    {}
)

vim.api.nvim_create_user_command(
    "SlidesStop",
    function() require("slides").stop() end,
    {}
)
