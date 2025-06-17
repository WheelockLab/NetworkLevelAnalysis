function moveFigToParentUILocation(fig_h, parent_h)

    %Intended to fix issue in Windows where plots generated from NLA_GUI
    %and NLA_Result get drawn way off top of screen.
    %Inputs are: 
    %    fig_h - figure handle
    %    parent_h - UIFigure handle to move to (matlab.ui.Figure)
            
    figPos = get(fig_h, 'Position');
    
    currWidth = figPos(3);
    currHeight = figPos(4);
    
    parentPos = parent_h.Position;
    
    %Position sets bottom left of figure, but we want to match the
    %top left (to ensure that top of new figure is on screen()
    vertOffset = currHeight - parentPos(4);
    
    additionalOffset = [10, -10];
    
    moveFigTo_x = parentPos(1) + additionalOffset(1);
    moveFigTo_y = parentPos(2) + additionalOffset(2) - vertOffset;
    
                
    set(fig_h, 'Position', [moveFigTo_x moveFigTo_y currWidth currHeight]);

end