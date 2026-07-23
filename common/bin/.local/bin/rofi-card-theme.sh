#!/usr/bin/env bash
# Shared rofi card-grid theme, sourced by rofi-power and rofi-profile (which had
# ~28 identical lines of -theme-str each). Emits the theme body; the per-card
# styling is identical across menus — only the window width and grid shape (rows
# x columns) differ, so those are arguments.
#
#   rofi_card_theme <width> <columns> <lines>
#
# The card colours (@bg/@bg-alt/@bg-sel/@accent/@border-*) resolve from the base
# config.rasi's * block. See rofi-power for the notes on why the state-qualified
# selectors and enlarged element-text font are required.
rofi_card_theme() {
    local width="$1" columns="$2" lines="$3"
    cat <<EOF
window    { width: ${width}; border: 2px; border-color: @border-c; background-color: @bg; }
mainbox   { children: [ listview ]; padding: 22px; background-color: transparent; border: 0; }
inputbar  { enabled: false; }
listview  { columns: ${columns}; lines: ${lines}; spacing: 14px; fixed-height: true; fixed-columns: true;
            border: 0; background-color: transparent; scrollbar: false; }
element {
    padding:          22px 10px;
    border:           1px;
    border-radius:    12px;
    background-color: @bg-alt;
    border-color:     @border-med;
    text-color:       @fg;
}
element normal.normal,
element alternate.normal {
    background-color: @bg-alt;
    border-color:     @border-med;
    text-color:       @fg;
}
element selected.normal {
    background-color: @bg-sel;
    border-color:     @accent;
    text-color:       @accent;
}
element-text {
    font:             "JetBrainsMono Nerd Font 21";
    horizontal-align: 0.5;
    vertical-align:   0.5;
    background-color: transparent;
    text-color:       inherit;
}
EOF
}
