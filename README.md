# blamer.nvim

A git blame plugin for Neovim inspired by VS Code's GitLens plugin.

![blamer gif](https://res.cloudinary.com/djg49e1u9/image/upload/c_crop,h_336/v1579092411/blamer_mkv07c.gif)

Blame information for the line under your cursor (or your visual selection) is shown as virtual text next to the line, after a short delay.

## Features

- Shows the commit that last touched the line under the cursor as virtual text
- Blames the whole visual selection in visual mode
- Customizable template with commit author, date, summary, and hash fields
- Relative or absolute time display
- Debounced updates so the plugin stays fast while you move the cursor
- Toggleable at any time with `:BlamerToggle`
- Automatically disables itself outside git repositories

## Requirements

- Neovim 0.7+ (virtual text via extmarks)
- `git` available in your `PATH`
- A git repository to blame (the plugin automatically disables itself otherwise)

## Installation

The plugin works out of the box with default settings even without calling `setup()`.

#### lazy.nvim

```lua
{
  'saifshahriar/blamer.nvim',
  lazy = false,
  config = function()
    require('blamer').setup({
      enabled = true,
    })
  end,
}
```

If you want to lazy-load it instead, trigger on the commands:

```lua
{
  'saifshahriar/blamer.nvim',
  cmd = { 'BlamerToggle', 'BlamerShow', 'BlamerHide' },
  config = function()
    require('blamer').setup({
      enabled = true,
    })
  end,
}
```

> **Note:** with lazy-loading, the commands are only available after the plugin loads. If you get `E492: Not an editor command`, the plugin has not been loaded yet — trigger it with the `cmd` list above or use `lazy = false`.

#### vim-plug

```vim
call plug#begin('~/.local/share/nvim/plugged')
...
Plug 'saifshahriar/blamer.nvim'
...
call plug#end()
```

#### Packer

```lua
require('packer').startup(function(use)
  -- other plugins ...
  use {
    'saifshahriar/blamer.nvim',
    config = function()
      require('blamer').setup({ enabled = true })
    end,
  }
  -- other ...
end)
```

## Quick Start

1. Install the plugin (see above).
2. Call `require('blamer').setup({ enabled = true })`.
3. Move your cursor around — after the delay (default `1000ms`), the last commit that touched the current line appears to the right of it.

Example minimal config:

```lua
require('blamer').setup({
  enabled = true,
})
```

Full example with all options:

```lua
require('blamer').setup({
  enabled = true,                   -- show blame on startup
  delay = 500,                      -- ms to wait before showing blame
  show_in_visual_modes = true,      -- blame visual selections
  show_in_insert_modes = true,      -- blame while in insert mode
  prefix = ' > ',                   -- text before the blame message
  template = '<author>, <author-time> • <summary>',
  date_format = '%d/%m/%y %H:%M',   -- strftime format for dates
  relative_time = false,            -- show dates as "3 minutes ago"
})
```

## Commands

| Command         | Description                                            |
| --------------- | ------------------------------------------------------ |
| `:BlamerShow`   | Enable blamer and show the blame message immediately   |
| `:BlamerHide`   | Hide the blame message and disable blamer              |
| `:BlamerToggle` | Toggle blamer on/off                                   |

## Configuration

All options are passed as a table to `require('blamer').setup({ ... })`.

### `enabled`

Enables blamer on Neovim startup.

You can toggle blamer on/off at any time with the `:BlamerToggle` command.

If the current directory is not a git repository the blamer will be automatically disabled.

- **Type:** `boolean`
- **Default:** `false`

```lua
require('blamer').setup({
  enabled = true,
})
```

### `delay`

The delay in milliseconds for the blame message to show after the cursor stops moving.

Setting this too low may cause performance issues, since the git blame command runs synchronously on every refresh.

- **Type:** `number`
- **Default:** `1000`

```lua
require('blamer').setup({
  delay = 500,
})
```

### `show_in_visual_modes`

Enables / disables blamer in visual modes. When enabled, the whole visual selection is blamed, line by line.

- **Type:** `boolean`
- **Default:** `true`

```lua
require('blamer').setup({
  show_in_visual_modes = false,
})
```

### `show_in_insert_modes`

Enables / disables blamer in insert modes.

When `false`, blame is hidden while you are typing and re-shown when you leave insert mode.

- **Type:** `boolean`
- **Default:** `true`

```lua
require('blamer').setup({
  show_in_insert_modes = false,
})
```

### `prefix`

The prefix that will be added to the template.

- **Type:** `string`
- **Default:** `'   '`

```lua
require('blamer').setup({
  prefix = ' > ',
})
```

### `template`

The template for the blame message that will be shown.

Any combination of the fields below can be used; unknown fields are left untouched.

| Field              | Description                                |
| ------------------ | ------------------------------------------ |
| `<author>`         | Commit author name                         |
| `<author-mail>`    | Commit author email                        |
| `<author-time>`    | Commit author timestamp                    |
| `<committer>`      | Commit committer name                      |
| `<committer-mail>` | Commit committer email                     |
| `<committer-time>` | Commit committer timestamp                 |
| `<summary>`        | First line of the commit message           |
| `<commit-short>`   | Short commit hash (first 8 characters)     |
| `<commit-long>`    | Full commit hash (40 characters)           |

- **Type:** `string`
- **Default:** `'<author>, <author-time> • <summary>'`

```lua
require('blamer').setup({
  template = '<committer> <summary>',
})
```

### `date_format`

The [strftime format](https://devhints.io/datetime#strftime-format) of the date fields (`<author-time>`, `<committer-time>`). Ignored when `relative_time` is enabled.

- **Type:** `string`
- **Default:** `'%d/%m/%y %H:%M'`

```lua
require('blamer').setup({
  date_format = '%d/%m/%y',
})
```

### `relative_time`

Shows commit dates in a relative format (e.g. `3 minutes ago`) instead of the absolute date.

- **Type:** `boolean`
- **Default:** `false`

```lua
require('blamer').setup({
  relative_time = true,
})
```

## Highlight

The color of the blame message is controlled by the `Blamer` highlight group.

- **Default:** `link Blamer Comment`

Override it in your colorscheme or config:

```vim
highlight Blamer guifg=lightgrey
```

```lua
vim.api.nvim_set_hl(0, 'Blamer', { fg = '#808080', italic = true })
```

## Lua API

The module exposes the same functionality as the commands:

```lua
local blamer = require('blamer')

blamer.setup(opts)         -- merge options and (re)initialize the plugin
blamer.enable()            -- enable blamer (like :BlamerShow)
blamer.disable()           -- disable blamer (like :BlamerHide)
blamer.toggle()            -- toggle blamer on/off (like :BlamerToggle)
blamer.show()              -- immediately show blame for the current line
blamer.hide()              -- immediately hide the blame message
blamer.enable_show()       -- mark blame as visible and show it
blamer.disable_show()      -- mark blame as hidden and hide it
```

Note: `setup()` is idempotent and can be called multiple times to update options.

## How it works

- On `BufEnter`, blamer checks whether the buffer belongs to a git repository and whether the file is tracked (`git ls-files --error-unmatch`).
- On `CursorMoved`, `BufEnter` and `BufWritePost`, a debounced timer (see `delay`) is restarted.
- When the timer fires, `git blame --line-porcelain -L <line>,<line>` is run for the line under the cursor (or the visual range), and the result is rendered as virtual text next to each line.
- Uncommitted lines are shown as `You` with the summary `Uncommitted changes`.
- Lines committed by the configured git `user.name` / `user.email` are shown as `You`.

## Troubleshooting

#### `E492: Not an editor command` when running `:BlamerToggle`

The plugin has not been loaded yet (most common with lazy.nvim). Add the commands to the lazy-loading trigger list, or set `lazy = false`:

```lua
{
  'saifshahriar/blamer.nvim',
  cmd = { 'BlamerToggle', 'BlamerShow', 'BlamerHide' },
}
```

#### Blame text never appears

- Make sure you called `setup({ enabled = true })` or ran `:BlamerShow`.
- Make sure the file is inside a git repository and is tracked.
- Check that `git` is in your `PATH`.
- The plugin deliberately skips special buffers (`buftype` is not empty), e.g. `:help` or plugin windows.

#### Blame text is slow to appear

That's the `delay` option (default `1000ms`). Lower it:

```lua
require('blamer').setup({ delay = 200 })
```

On very large repositories the synchronous `git blame` call can take a moment — if you notice cursor stutter, increase the delay instead.

## Authors

Original plugin: [APZelos](https://github.com/APZelos)

Lua port and current maintainer: [saifshahriar](https://github.com/saifshahriar)

## License

This software is released under the MIT License.