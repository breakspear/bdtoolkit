% Test function for bdStaticPanel
function [bdsolverpanel, bdcontrol] = bdSolverPanelTest(sys)
    % ensure bdControl is in the path
    if ~exist('bdControl.m','file')
        addpath ..
    end

    % construct figure
    fig = figure('Units','pixels','Position',[randi(100,1,1),randi(100,1,1),800,600]);

    % construct the LHS panel
    panel1 = uipanel(fig,'Units','pixels','Position',[5 5 600 600]);
    tabgroup1 = uitabgroup(panel1);
            
    % construct the RHS panel
    panel2 = uipanel(fig,'Units','pixels','Position',[5 5 100 600],'BorderType','none');

    % resize the panels (putting them in their exact position)
    SizeChanged(fig,panel1,panel2);

    % register a callback for resizing the figure
    set(fig,'SizeChangedFcn', @(~,~) SizeChanged(fig,panel1,panel2));
    
    % construct the control panel
    bdcontrol = bdControl(panel2,sys);
    
    bdsolverpanel = bdSolverPanel(tabgroup1,'Solver Panel',sys,bdcontrol);
    
    % force a recompute
    notify(bdcontrol,'recompute');
end

function SizeChanged(fig,panel1,panel2)
    % get the new figure size
    figw = fig.Position(3);
    figh = fig.Position(4);

    % dont allow small figures to cramp our panels
    figw = max(figw,300);
    figh = max(figh,300);

    % width of the RHS panel
    panel2w = 110;

    % resize the LHS panel
    w1 = figw - panel2w - 10;
    h1 = figh - 10;
    panel1.Position = [5 5 w1 h1];

    % resize the RHS panel
    w2 = panel2w;
    h2 = figh - 10;
    panel2.Position = [8+w1 5 w2 h2];            
end

