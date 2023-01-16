# 📚 partex.nvim
![partex.nvim](./assets/video.gif)

`partex.nvim` introduces several functions to deal with `LaTeX` files paragraph formatting and
movement. The plugin is entirely written in `lua` and employs `treesitter` to perform the syntax
queries; the `LaTeX` treesitter parser is
[required](https://github.com/nvim-treesitter/nvim-treesitter).

A paragraph is defined as a block of text in a `LaTeX` file that might contain inline equations or
inline commands. For instance, the following `LaTeX` snippet contains two paragraphs:
```latex
\begin{document}
    \begin{equation}
        f(x) = \sin(A\, x + \phi)
        \label{eq:myeq1}
    \end{equation}
    % -- This is paragraph A: 
    Lorem ipsum dolor sit amet, officia excepteur ex fugiat $f(x)$ reprehenderit enim labore culpa
    sint ad nisi Lorem pariatur mollit ex esse exercitation amet, eq.~(\ref{eq:myeq1}). Nisi anim
    cupidatat excepteur officia. Reprehenderit nostrud nostrud ipsum Lorem est aliquip amet
    voluptate voluptate dolor minim nulla est proident. Nostrud officia pariatur ut officia. Sit
    irure elit esse ea nulla sunt ex occaecat reprehenderit commodo officia dolor Lorem duis laboris
    cupidatat officia voluptate. Culpa proident adipisicing id nulla nisi laboris ex in Lorem sunt
    duis officia eiusmod. Aliqua reprehenderit commodo ex non excepteur duis sunt velit enim.
    Voluptate laboris sint cupidatat ullamco ut ea consectetur et est culpa et culpa duis, $g(x)
    \simeq f(x)$
    \begin{equation}
        g(x) = \cos(B\, x)
        \label{eq:myeq2}
    \end{equation}
    % -- This is paragraph B:
    Lorem ipsum dolor sit amet, qui minim labore adipisicing minim sint cillum sint consectetur
    cupidatat~\cite{MyCiteOne, MyCiteTwo}
\end{document}
```
Commented paragraphs, isolated commands, math environments and general environments are not
paragraphs. Additionally, blank lines (`regex = ^$ \| ^\s\+$`) are not considered part of a
paragraph. Blocks of text inside `\begin{document} ... \end{document}` and `\begin{abstract} ...
\end{abstract}` are considered paragraphs to allow an easy manipulation of any `LaTeX` file.

## Disclaimer
Parsing `LaTeX` code is difficult. As a result, some special cases might not be correctly parsed.
Contributions to solve corner-cases are welcomed.

# Installation
To install the plugin, use your desired `neovim` plugin manager. For example, `packer`
```lua
use {'schavesgm/partex.nvim'}
```
The plugin requires, at least, `neovim 0.7`.

# Configuration
`partex.nvim` can be configured using
```lua
require"partex".setup()
```

The default configuration is
```lua
{
    -- Create the excommand "FormatTex" automatically
    create_excmd = true,
    keymaps = {
        -- Set the keybindings
        set = true,
        operator = {
            -- Act inside a paragraph in operator mode
            select_inside = "ip",
        },
        normal = {
            -- Visually select inside a paragraph
            select_inside = "vip",
            -- Move to the next paragraph in the file
            move_to_next  = "np",
            -- Move to the previous paragraph in the file
            move_to_prev  = "Np",
            -- Move to the end of the current paragraph
            move_to_end   = "mp",
            -- Move to the start of the current paragraph
            move_to_start = "Mp",
        }
    }
}
```
The configuration can be easily updated by passing a `lua` table to `require"partex".setup()`

The command `:FormatTex` can take an integer argument, which sets the `textwidth` of the document,
and formats the whole document to the desired length. If `textwidth` is already set, then
`:FormatTex` will try formatting the document to the current value of `textwidth`. `FormatTex` also
sets `colorcolumn=+1` to allow a quick visualisation of the maximum `textwidth` employed.

Furthermore, `partex.nvim` exposes several useful functions, which can be employed to create new
functionalities:
```lua
require"partex.actions" = {
    get_paragraph_start        = <function>,
    get_paragraph_end          = <function>,
    get_paragraph_limits       = <function>,
    get_next_paragraph         = <function>,
    get_previous_paragraph     = <function>,
    select_inside_paragraph    = <function>,
    move_to_next_paragraph     = <function>,
    move_to_previous_paragraph = <function>,
    move_to_paragraph_start    = <function>,
    move_to_paragraph_end      = <function>,
    act_over_each_paragraph    = <function>,
    get_all_bounds_required    = <function>,
    is_inside_paragraph        = <function>,
}
```
