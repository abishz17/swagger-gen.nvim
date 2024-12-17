# swagger-gen.nvim

A Neovim plugin to generate Swagger documentation for Go Echo handlers using Claude AI.

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "abishz17/swagger-gen.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
}
