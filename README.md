# kame.vim

Vim filetype detection, syntax highlighting, formatting, and parse diagnostics
for the Kame build system.

## Installation

### Vim package (no plugin manager)

Clone the repository into Vim's package directory:

```sh
git clone https://github.com/sebastien/kame.vim.git \
  ~/.vim/pack/plugins/start/kame.vim
```

Vim will load the plugin automatically on startup. For Neovim, use its site
directory instead:

```sh
git clone https://github.com/sebastien/kame.vim.git \
  ~/.local/share/nvim/site/pack/plugins/start/kame.vim
```

### vim-plug

Add this to your vim-plug configuration, then run `:PlugInstall`:

```vim
Plug 'sebastien/kame.vim'
```

Files ending in `.km` (the default) and `.kmk` are detected as Kame.

## Usage

Commands:

- `:KameFormat` saves the current file and formats it in place with
  `kame do fmt -i`.
- `:KameLint` saves the current file and parses it with
  `kame do parse --lang script`. Parse errors are listed in the quickfix window.

Set `g:kame_command` to the executable path if Kame is not on `PATH`:

```vim
let g:kame_command = '/path/to/kame'
```

Linting currently checks Kame script syntax; it does not perform build-graph,
recipe, or style analysis.
