function settings_struct = getDefaultPlotSettings()

    settings_struct = struct();
    settings_struct.color_map = parula(1000);
    settings_struct.p_value_plot_max = 0.0500;
    settings_struct.name_label = 'plot title';        
    settings_struct.callback = @() [];
    settings_struct.significance_type =  nla.gfx.SigType.DECREASING;
    settings_struct.plot_scale = nla.gfx.ProbPlotMethod.DEFAULT;
    settings_struct.plot_max = 0.0500;

end