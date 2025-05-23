# gitlab.nvim

A Neovim plugin for interacting with GitLab using the `glab` CLI.

## Features

- Create GitLab issues
- Create branches for issues
- ... (more to come)

## Requirements

- Neovim 0.7+
- `glab` CLI installed and authenticated
- `nui.nvim`

## Installation

Using packer.nvim:

```lua
use {
  'your-username/gitlab.nvim',
  requires = {
    'MunifTanjim/nui.nvim',
    -- Potentially other dependencies like plenary.nvim if needed
  }
}
```

## Setup

```lua
require('gitlab').setup({
  -- your configuration options here
})
```

## Usage

- `:GitlabCreateIssue` - Create a new GitLab issue.