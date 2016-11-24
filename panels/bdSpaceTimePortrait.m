classdef bdSpaceTimePortrait < handle
    %bdSpaceTimePortrait - a GUI tab panel for displaying space-time plots.
    %   Displays space-time plots in the Brain Dynamics Toolbox GUI.
    %

    % Copyright (c) 2016, Stewart Heitmann <heitmann@ego.id.au>
    % All rights reserved.
    %
    % Redistribution and use in source and binary forms, with or without
    % modification, are permitted provided that the following conditions
    % are met:
    %
    % 1. Redistributions of source code must retain the above copyright
    %    notice, this list of conditions and the following disclaimer.
    % 
    % 2. Redistributions in binary form must reproduce the above copyright
    %    notice, this list of conditions and the following disclaimer in
    %    the documentation and/or other materials provided with the
    %    distribution.
    %
    % THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    % "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    % LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    % FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    % COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    % INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    % BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    % LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    % CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    % LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    % ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    % POSSIBILITY OF SUCH DAMAGE.

    properties
        Y       % matrix of Y values versus time (n x t)
        t       % vector of time points (1 x t)
    end
    
    properties (Access=private) 
        tab     % handle to uitab object
        ax      % handle to plot axes
        img     % handle to axes image
        popup   % hanle to variable selector
        varindx % lookup table for indexes of the ODE variables
    end
    
    methods
        function this = bdSpaceTimePortrait(tabgroup,control)
            % Construct a new tab panel in the parent tabgroup.
            % Usage:
            %    bdSpaceTimePortrait(tabgroup,title,control)
            % where 
            %    tabgroup is a handle to the parent uitabgroup object.
            %    title is a string defining the name given to the new tab.
            %    control is a handle to the GUI control panel.

            if ~isfield(control.sys.gui,'bdSpaceTimePortrait')
                return      % we aren't wanted so quietly do nothing.
            end
            
            % sys.gui.bdSpaceTimePortrait.title (optional)
            if isfield(control.sys.gui.bdSpaceTimePortrait,'title')
                title = control.sys.gui.bdSpaceTimePortrait.title;
            else
                title = 'Space-Time';
            end

            % build a lookup table describing the data indexes pertinent
            % to each ODE variable defined in control.vardef{name,value}
            this.varindx = this.enumerate(control.vardef);
            
            % construct the uitab
            this.tab = uitab(tabgroup,'title',title, 'Units','pixels');
            
            % get tab geometry
            parentx = this.tab.Position(1);
            parenty = this.tab.Position(2);
            parentw = this.tab.Position(3);
            parenth = this.tab.Position(4);

            % plot axes
            posx = 50;
            posy = 80;
            posw = parentw-65;
            posh = parenth-90;
            this.ax = axes('Parent',this.tab, 'Units','pixels', 'Position',[posx posy posw posh]);           
            
            % plot image (empty)
            this.img = imagesc([],'Parent',this.ax);
            xlabel('time', 'FontSize',16);
            ylabel('node', 'FontSize',16);

            % var selector
            posx = 10;
            posy = 10;
            posw = 100;
            posh = 20;
            
            this.popup = uicontrol('Style','popup', ...
                'String', control.vardef(:,1), ...
                'Value', 1, ...
                'Callback', @(~,~) this.selectorCallback(control), ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', this.tab, ...
                'Position',[posx posy posw posh]);

            % register a callback for resizing the panel
            set(this.tab,'SizeChangedFcn', @(~,~) SizeChanged(this,this.tab));

            % listen to the control panel for redraw events
            addlistener(control,'redraw',@(~,~) this.render(control));    
        end
        
        function render(this,control)
            %disp('bdSpaceTimePortrait.render()')
            varnum = this.popup.Value;
            varstr = this.popup.String{varnum};
            yindx = this.varindx{varnum};
            tend  = control.sol.x(end);
            this.t = linspace(0,tend,1001);
            %this.Y = deval(control.sol,this.t,yindx);
            this.Y = control.deval(this.t,yindx);
            this.img.CData = this.Y;
            this.img.XData = this.t;
            this.img.YData = yindx - yindx(1) + 1;
            xlim(this.ax,[0 tend]);
            ylim(this.ax,[0.5 numel(yindx)+0.5]);
            %title(this.ax,varstr);
            n = numel(yindx);
            if n<=20
                set(this.ax,'YTick',1:n);
            end
        end
    end
    
    methods (Access=private)
        % Callback for panel resizing. 
        function SizeChanged(this,parent)
            % get new parent geometry
            parentw = parent.Position(3);
            parenth = parent.Position(4);
            
            % resize the axes
            this.ax.Position = [50, 80, parentw-65, parenth-90];
        end
 
        
        % Callback ffor the plot variable selectors
        function selectorCallback(this,control)
            this.render(control);
        end

        function indices = enumerate(this,xxxdef)
            indices = {};
            nr = size(xxxdef,1);
            n = 0;
            % for each row in xxxdef{row,ccol}
            for r=1:nr
                nc = numel(xxxdef{r,2}); 
                indices{r} = [1:nc]+n;
                n = n + nc;
            end
            
        end
        
    end
    
end

