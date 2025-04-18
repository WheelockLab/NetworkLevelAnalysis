function [outputArg1,outputArg2] = setTitle(ax, txt, is_subtitle)
    %SETTITLE Set the title of an axes
    %   ax: Axes to set the title on
    %   txt: Title/subtitle text
    %   is_subtitle: boolean, whether to display as a subtitle
    if ~exist('is_subtitle', 'var'), is_subtitle = false; end
    
    if is_subtitle
        subtitle(ax, txt);
    else
        title(ax, txt);
    end
    set(ax,'fontsize', 9.5)
end

