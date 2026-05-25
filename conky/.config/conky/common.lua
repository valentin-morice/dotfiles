-- Shared conky.config values. Each section conf merges these with its own
-- section-specific overrides (gap_y, conky.text, minimum_height).
common = {
    alignment = 'top_left',
    background = false,
    border_width = 0,
    cpu_avg_samples = 2,
    default_color = 'ffffff',
    color1 = '5294e2',
    color2 = 'e0a552',
    color3 = '888888',
    color4 = 'ff5555',
    double_buffer = true,
    draw_borders = false,
    draw_graph_borders = false,
    draw_outline = false,
    draw_shades = false,
    font = 'JetBrainsMono Nerd Font:size=10',
    gap_x = 32,
    minimum_width = 268,
    no_buffers = true,
    lua_load = os.getenv("HOME") .. "/.config/conky/common.lua",
    lua_draw_hook_post = 'draw_borders',
    own_window = true,
    own_window_type = 'override',
    own_window_transparent = false,
    own_window_argb_visual = true,
    own_window_argb_value = 255,
    own_window_colour = '0d0d0d',
    own_window_class = 'Conky',
    border_inner_margin = 14,
    border_outer_margin = 0,
    top_name_width = 14,
    update_interval = 2.0,
    use_xft = true,
    extra_newline = false,
    out_to_console = false,
    out_to_stderr = false,
}

function merge(overrides)
    local out = {}
    for k, v in pairs(common) do out[k] = v end
    for k, v in pairs(overrides) do out[k] = v end
    return out
end

-- Declarative layout. Edit this table to add, remove, or reorder widgets;
-- gap_x / gap_y are computed from it via position() — never hand-tuned.
-- Heights are measured pixel-heights of each widget (header + rows + borders).
layout = {
    edge_top   = 34,
    widget_gap = 13,
    columns = {
        { gap_x = 32,
            { name = 'mail',  height = 100 },
            { name = 'disk',  height = 100 },
            { name = 'cpu',   height = 179 },
            { name = 'mem',   height = 182 },
            { name = 'power', height = 170 },
        },
    },
}

-- position(name) -> gap_x, gap_y
-- Resolves a widget's screen position from the layout table above.
function position(name)
    for _, col in ipairs(layout.columns) do
        local y = layout.edge_top
        for _, w in ipairs(col) do
            if w.name == name then
                return col.gap_x, y
            end
            y = y + w.height + layout.widget_gap
        end
    end
    error("conky layout: unknown widget '" .. name .. "'")
end

package.cpath = '/usr/lib/conky/lib?.so;' .. package.cpath
require 'cairo'
require 'cairo_xlib'

-- Draws a light-gray section border around the conky window, and
-- optionally an inner sub-section box (used for cpu/mem process lists).
-- Args (passed via lua_draw_hook_post string): inner_y, inner_h.
-- Without args, only the outer section border is drawn.
function conky_draw_borders(inner_y_str, inner_h_str)
    if conky_window == nil then return end

    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable,
                                         conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    cairo_set_source_rgba(cr, 0x44/255, 0x44/255, 0x44/255, 1)

    cairo_set_line_width(cr, 2)
    cairo_rectangle(cr, 1, 1, conky_window.width - 2, conky_window.height - 2)
    cairo_stroke(cr)

    local inner_y = tonumber(inner_y_str)
    local inner_h = tonumber(inner_h_str)
    if inner_y and inner_h then
        cairo_set_line_width(cr, 1)
        local x = 14
        local w = conky_window.width - 28
        cairo_rectangle(cr, x + 0.5, inner_y + 0.5, w - 1, inner_h - 1)
        cairo_stroke(cr)
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
