classdef bdSpaceTime < handle
    %bdSpaceTime Brain Dynamics GUI panel for space-time plots.
    %   This class implements space-time plots for the graphical user interface
    %   of the Brain Dynamics Toolbox (bdGUI). Users never call this class
    %   directly. They instead instruct the bdGUI application to load the
    %   panel by specifying any (or all) of the following options in their
    %   model's system definition. 
    %   
    %SYS OPTIONS
    %   sys.panels.bdSpaceTime.title = 'Space-Time'
    %
    %AUTHORS
    %  Stewart Heitmann (2016a,2017a)

    % Copyright (C) 2016,2017 QIMR Berghofer Medical Research Institute
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
        Y           % matrix of Y values versus time (n x t)
        t           % vector of time points (1 x t)
    end
    
    properties (Access=private) 
        tab         % handle to uitab object
        ax          % handle to plot axes
        img         % handle to axes image
        popup       % handle to variable selector
        varindx     % lookup table for indexes of the ODE variables
        listener    % handle to listener
    end
    
    methods
        function this = bdSpaceTime(tabgroup,control)
            % Construct a new tab panel in the parent tabgroup.
            % Usage:
            %    bdSpaceTime(tabgroup,control)
            % where 
            %    tabgroup is a handle to the parent uitabgroup object.
            %    control is a handle to the GUI control panel.

            % apply default settings to sys.panels.bdSpaceTime
            control.sys.panels.bdSpaceTime = bdSpaceTime.syscheck(control.sys);

            % build a lookup table describing the data indexes pertinent
            % to each ODE variable defined in sys.vardef{name,value}
            this.varindx = this.enumerate(control.sys.vardef);
            
            % construct the uitab
            this.tab = uitab(tabgroup, ...
                'title',control.sys.panels.bdSpaceTime.title, ...
                'Tag','bdSpaceTimeTab', ...
                'Units','pixels', ...
                'TooltipString','Right click for menu');
            
            % get tab geometry
            parentw = this.tab.Position(3);
            parenth = this.tab.Position(4);

            % plot axes
            posx = 50;
            posy = 80;
            posw = parentw-120;
            posh = parenth-90;
            this.ax = axes('Parent',this.tab, 'Units','pixels', 'Position',[posx posy posw posh]);           
            
            % plot image (empty)
            this.img = imagesc([],'Parent',this.ax);
            xlabel('time', 'FontSize',16);
            ylabel('node', 'FontSize',16);

            % Add a colorbar
            colorbar('peer',this.ax);

            % var selector
            posx = 10;
            posy = 10;
            posw = 100;
            posh = 20;
            
            this.popup = uicontrol('Style','popup', ...
                'String', {control.sys.vardef.name}, ...
                'Value', 1, ...
                'Callback', @(~,~) this.selectorCallback(control), ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', this.tab, ...
                'Position',[posx posy posw posh]);

            % construct the tab context menu
            this.tab.UIContextMenu = uicontextmenu;
            uimenu(this.tab.UIContextMenu,'Label','Close', 'Callback',@(~,~) this.delete());

            % register a callback for resizing the panel
            set(this.tab,'SizeChangedFcn', @(~,~) SizeChanged(this,this.tab));

            % listen to the control panel for redraw events
            this.listener = addlistener(control,'redraw',@(~,~) this.render(control));    
        end
        
        % Destructor
        function delete(this)
            delete(this.listener);
            delete(this.tab);          
        end
               
        function render(this,control)
            %disp('bdSpaceTime.render()')
            varnum = this.popup.Value;
            %varstr = this.popup.String{varnum};
            yindx = this.varindx{varnum};
            t0 = max(control.sol.x(1), 0); 
            t1  = control.sol.x(end);
            this.t = linspace(t0,t1,1001);
            this.Y = bdEval(control.sol,this.t,yindx);
            this.img.CData = this.Y;
            this.img.XData = this.t;
            this.img.YData = yindx - yindx(1) + 1;
            xlim(this.ax,[t0 t1]);
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
            this.ax.Position = [50, 80, parentw-120, parenth-90];
        end
 
        
        % Callback ffor the plot variable selectors
        function selectorCallback(this,control)
            this.render(control);
        end

        function indices = enumerate(this,xxxdef)
            indices = {};
            nr = numel(xxxdef);
            n = 0;
            % for each entry in xxxdef
            for r=1:nr
                nc = numel(xxxdef(r).value); 
                indices{r} = [1:nc]+n;
                n = n + nc;
            end
            
        end
        
    end
    
    methods (Static)
        
        % Check the sys.panels struct
        function syspanel = syscheck(sys)
            % Default panel settings
            syspanel.title = 'Space-Time';
            
            % Nothing more to do if sys.panels.bdSpaceTime is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdSpaceTime')
                return;
            end
            
            % sys.panels.bdSpaceTime.title
            if isfield(sys.panels.bdSpaceTime,'title')
                syspanel.title = sys.panels.bdSpaceTime.title;
            end
        end
        
    end
    
end

