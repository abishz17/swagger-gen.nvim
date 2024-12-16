# swagger-gen.nvim

A Neovim plugin to generate Swagger documentation for Go Echo handlers using Claude AI.

### Requirements
```
ANTHROPIC_API_KEY environment variable set with your Claude API key
nvim-treesitter
plenary.nvim
```


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
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use {
    'abishz17/swagger-gen.nvim',
    requires = {
        'nvim-lua/plenary.nvim',
        'nvim-treesitter/nvim-treesitter',
    }
}
```
### Set your anthropic API key
```bash
export ANTHROPIC_API_KEY=your_api_key
```
## Usage

1. Place your cursor on the first line of your  handler function
2. Run the command:
```vim
:lua require('swagger-doc').generate_swagger_docs()
```

## Keybinding Example

```lua
vim.keymap.set('n', '<leader>sd', require('swagger-doc').generate_swagger_docs, { desc = 'Generate Swagger Docs' })
```
