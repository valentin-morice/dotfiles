#!/usr/bin/env bash
# Shared rofi card-grid theme, sourced by rofi-power, rofi-profile and
# rofi-confirm (which had ~28 identical lines of -theme-str each). Emits the
# theme body; the per-card styling is identical across menus — only the card
# width and grid shape (rows x columns) differ, so those are arguments.
#
#   rofi_card_theme <width> <columns> <lines>
#   card_glyph <glyph>
#
# card_glyph wraps a card's icon in Material Symbols Outlined at weight 500 —
# the same family, style and weight as the waybar icons, so the menus and the
# bar share one icon set. The span is load-bearing, not cosmetic: the glyphs are
# Private Use Area codepoints the Nerd Font ALSO fills, so without the explicit
# font_family the card's JetBrainsMono Nerd Font would draw an unrelated glyph.
# The label is not wrapped, so it stays in the card font.
#
# size/rise are measured, not eyeballed, against the Font Awesome glyphs these
# replaced: Material pads its 24dp grid more, so 110% brings the ink back to the
# old size (lock 27px vs 26, reboot 23 vs 22), and the bigger glyph pushes the
# label below centre — rise -6000 on the glyph puts the two centres back within
# half a pixel. Each menu's label then sits at rise 3000 (was 4000), a deliberate
# ~1px drop below exact centre, which read better by eye. Change one, re-measure
# both.
#
# The card colours (@bg/@bg-alt/@bg-sel/@accent/@border-*) resolve from the base
# config.rasi's * block. See rofi-power for the notes on why the state-qualified
# selectors and enlarged element-text font are required.
card_glyph() {
    printf "<span font_family='Material Symbols Outlined' weight='500' size='110%%' rise='-6000'>%s</span>" "$1"
}

rofi_card_theme() {
    local width="$1" columns="$2" lines="$3"
    cat <<EOF
mainbox   { children: [ listview ]; width: ${width}; padding: 22px; border: 2px; border-color: @border-c; background-color: @bg; }
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
