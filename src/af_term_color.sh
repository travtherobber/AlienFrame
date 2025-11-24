#!/usr/bin/env bash
#@AF:module=term_color
af_term_color_reset()    { builtin echo -ne "\033[0m"; }
af_term_color_fg()       { builtin echo -ne "\033[38;5;${1}m"; }
af_term_color_bg()       { builtin echo -ne "\033[48;5;${1}m"; }
af_term_bold()           { builtin echo -ne "\033[1m"; }
af_term_dim()            { builtin echo -ne "\033[2m"; }
af_term_italic()         { builtin echo -ne "\033[3m"; }
af_term_underline()      { builtin echo -ne "\033[4m"; }
