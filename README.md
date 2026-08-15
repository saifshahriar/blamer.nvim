# blamer.nvim

A git blame plugin for Neovim inspired by VS Code's GitLens plugin.

![blamer gif](https://res.cloudinary.com/djg49e1u9/image/upload/c_crop,h_336/v1579092411/blamer_mkv07c.gif)

## Installation

#### lazy.nvim

```lua
{
  'APZelos/blamer.nvim',
  config = function()
    require('blamer').setup()
  end,
}
```

#### vim-plug

```vim
call plug#begin('~/.local/share/nvim/plugged')
...
Plug 'APZelos/blamer.nvim'
...
call plug#end()
```

The plugin works out of the box with default settings even without calling `setup()`.

## Configuration

All options can be passed to `require('blamer').setup({ ... })`.

#### Enabled

Enables blamer on Neovim startup.

You can toggle blamer on/off with the `:BlamerToggle` command.

If the current directory is not a git repository the blamer will be automatically disabled.

Default: `false`

```lua
require('blamer').setup({
  enabled = true,
})
```

#### Delay

The delay in milliseconds for the blame message to show. Setting this too low may cause performance issues.

Default: `1000`

```lua
require('blamer').setup({
  delay = 500,
})
```

#### Show in visual modes

Enables / disables blamer in visual modes.

Default: `true`

```lua
require('blamer').setup({
  show_in_visual_modes = false,
})
```

#### Show in insert modes

Enables / disables blamer in insert modes.

Default: `true`

```lua
require('blamer').setup({
  show_in_insert_modes = false,
})
```

#### Prefix

The prefix that will be added to the template.

Default: `'   '`

```lua
require('blamer').setup({
  prefix = ' > ',
})
```

#### Template

The template for the blame message that will be shown.

Default: `'<author>, <author-time> • <summary>'`

Available options: `<author>`, `<author-mail>`, `<author-time>`, `<committer>`, `<committer-mail>`, `<committer-time>`, `<summary>`, `<commit-short>`, `<commit-long>`.

```lua
require('blamer').setup({
  template = '<committer> <summary>',
})
```

### Date format

The [format](https://devhints.io/datetime#strftime-format) of the date fields. (`<author-time>`, `<committer-time>`)

Default: `'%d/%m/%y %H:%M'`

```lua
require('blamer').setup({
  date_format = '%d/%m/%y',
})
```

### Relative time

Shows commit date in relative format

Default: `false`

```lua
require('blamer').setup({
  relative_time = true,
})
```

#### Highlight

The color of the blame message.

Default: `link Blamer Comment`

```vim
highlight Blamer guifg=lightgrey
```

## Commands

- `:BlamerShow` - enable blamer and show the blame message
- `:BlamerHide` - hide the blame message and disable blamer
- `:BlamerToggle` - toggle blamer on/off

## Author

[APZelos](https://github.com/APZelos)

## License

This software is released under the MIT License.