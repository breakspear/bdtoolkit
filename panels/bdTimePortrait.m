classdef bdTimePortrait < handle
    %bdTimePortrait  Brain Dynamics Toolbox panel for time plots.
    %   This class implements time plots for the graphical user interface
    %   of the Brain Dynamics Toolbox (bdGUI). Users never call this class
    %   directly. They instead instruct the bdGUI application to load the
    %   panel by specifying options in their model's sys struct. 
    %   
    %SYS OPTIONS
    %   sys.panels.bdTimePortrait.title = 'Time Portrait'
    %   sys.panels.bdTimePortrait.grid = false
    %   sys.panels.bdTimePortrait.hold = false
    %   sys.panels.bdTimePortrait.autolim = true
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
    properties (Access=private) 
        fig             % handle to parent figure
        tab             % handle to uitab object
        ax1             % handle to plot 1 axes
        ax2             % handle to plot 2 axes
        popup1          % handle to popup selector 1
        popup2          % handle to popup selector 2
        varMap          % maps entries in vardef to rows in sol.y
        auxMap          % maps entries in auxdef to rows in sal
        solMap          % maps rows in sol.y to entries in vardef
        soxMap          % maps rows in sox.y to entries in auxdef
        listener        % handle to listener
    end
    
    methods
        function this = bdTimePortrait(tabgroup,control)
            % Construct a new tab panel in the parent tabgroup.
            % Usage:
            %    bdTimePortrait(tabgroup,control)
            % where 
            %    tabgroup is a handle to the parent uitabgroup object.
            %    control is a handle to the GUI control panel.

            % apply default settings to sys.panels.bdTimePortrait
            control.sys.panels.bdTimePortrait = bdTimePortrait.syscheck(control.sys);
            
            % get handle to parent figure
            this.fig = ancestor(tabgroup,'figure');
            
            % map vardef entries to rows in sol
            this.varMap = bd.varMap(control.sys.vardef);
            this.solMap = bd.solMap(control.sys.vardef);
            if isfield(control.sys,'auxdef')
                % map auxdef entries to rows in sal
                this.auxMap = bd.varMap(control.sys.auxdef);
                this.soxMap = bd.solMap(control.sys.auxdef);
            else
                % construct empty maps
                this.auxMap = bd.varMap([]);
                this.soxMap = bd.solMap([]);
            end
            
            % number of entries in vardef
            nvardef = numel(control.sys.vardef);
                        
            % construct the uitab
            this.tab = uitab(tabgroup,'title',control.sys.panels.bdTimePortrait.title, 'Tag','bdTimePortraitTab','Units','pixels');
            
            % get tab geometry
            parentw = this.tab.Position(3);
            parenth = this.tab.Position(4);

            % plot axes 1
            posw = parentw-65;
            posh = (parenth-120)/2;
            posx = 50;
            posy = 100 + posh;
            this.ax1 = axes('Parent',this.tab, 'Units','pixels', 'Position',[posx posy posw posh]);           
            hold(this.ax1,'on');
      
            % plot axes 2
            posw = parentw-65;
            posh = (parenth-120)/2;
            posx = 50;
            posy = 80;
            this.ax2 = axes('Parent',this.tab, 'Units','pixels', 'Position',[posx posy posw posh]);           
            hold(this.ax2,'on');
            
            % plot 1 popup selector
            posx = 10;
            posy = 10;
            posw = 100;
            posh = 20;
            popupval = 1;  
            popuplist = {this.solMap.name, this.soxMap.name};
            this.popup1 = uicontrol('Style','popup', ...
                'String', popuplist, ...
                'Value', popupval, ...
                'Callback', @(~,~) this.selectorCallback(control), ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', this.tab, ...
                'Position',[posx posy posw posh]);

            % plot 2 var selector
            posx = 110;
            posy = 10;
            posw = 100;
            posh = 20;
            if nvardef>=2
                popupval = numel(control.sys.vardef(1).value) + 1;
            end            
            this.popup2 = uicontrol('Style','popup', ...
                'String', popuplist, ...
                'Value', popupval, ...
                'Callback', @(~,~) this.selectorCallback(control), ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', this.tab, ...
                'Position',[posx posy posw posh]);
            
            % construct the TimePortrait menu (if it does not already exist)
            obj = findobj(this.fig,'Tag','bdTimePortraitMenu');
            if isempty(obj)
                bdTimePortrait.constructMenu(this.fig,control);
            end
            
            % construct the tab context menu
            this.tab.UIContextMenu = uicontextmenu;
            uimenu(this.tab.UIContextMenu,'Label','Close Panel', 'Callback',@(~,~) this.delete());

            % register a callback for resizing the panel
            set(this.tab,'SizeChangedFcn', @(~,~) SizeChanged(this,this.tab));
            
            % listen to the control panel for redraw events
            this.listener = addlistener(control,'redraw',@(~,~) this.render(control));    
        end
        
        % Destructor
        function delete(this)
            delete(this.listener);
            delete(this.tab);          
            % delete the menu if no more bdTimePortrait panels exist
            obj = findobj(this.fig,'Tag','bdTimePortraitTab');
            if isempty(obj)
                obj = findobj(this.fig,'Tag','bdTimePortraitMenu');
                if ~isempty(obj)
                    delete(obj);
                end
            end
        end
        
        function render(this,control)
            %disp('bdTimePortrait.render()')

            % retrieve the menu appdata
            appdata = getappdata(this.fig,'bdTimePortrait');

            % render the upper and lower axes 
            renderax(this.ax1, this.popup1.Value);
            renderax(this.ax2, this.popup2.Value);            
            xlabel(this.ax2,'time', 'FontSize',14);

            % Yindx is the global index of the selected variable
            function renderax(ax,popindx)
                % find the non-negative time entries in sol.x
                tindx = find(control.sol.x>=0);
                t = control.sol.x(tindx);

                % number of entries in sol
                nvardef = numel(this.solMap);
                
                % if the user selected a variable from vardef then ...
                if popindx <= nvardef
                    % the popup index corresponds to the row index of sol
                    solindx = popindx; 

                    % get detail of the selected variable
                    name    = this.solMap(solindx).name;        % name string
                    varindx = this.solMap(solindx).varindx;     % index in vardef{}
                
                    % find all rows of sol.y that are related to this vardef entry
                    solrows = this.varMap(varindx).solindx;
                    
                    % extract the values for plotting
                    y = control.sol.y(solrows,tindx);

                    % index of the variable of interest
                    yrow = solindx - solrows(1) + 1;
                else
                    % the popup index refers to an entry of sox
                    solindx = popindx - nvardef;
                    
                    % get detail of the selected variable
                    name    = this.soxMap(solindx).name;        % name string
                    auxindx = this.soxMap(solindx).varindx;     % auxdef index

                    % find all rows of aux that are related to this auxdef entry
                    solrows = this.auxMap(auxindx).solindx;

                    % extract the values for plotting
                    y = control.sox.y(solrows,tindx);

                    % index of the variable of interest
                    yrow = solindx - solrows(1) + 1;
                end
                
                % if 'hold' menu is checked then ...
                if appdata.hold
                    % Change existing plots to thin lines 
                    objs = findobj(ax);
                    set(objs,'LineWidth',0.5);               
                else
                    % Clear the plot axis
                    cla(ax);
                end
                
                % plot the background traces in grey
                plot(ax, t, y', 'color',[0.75 0.75 0.75], 'HitTest','off');
                
                % (re)plot the variable of interest in black
                plot(ax, t, y(yrow,:), 'color','k', 'Linewidth',1.5);
                ylabel(ax,name, 'FontSize',16,'FontWeight','normal');

                % show gridlines (or not)
                if appdata.grid
                    grid(ax,'on');
                else
                    grid(ax,'off')
                end

                % adjust the y limits (or not)
                if appdata.autolim
                    ylim(ax,'auto')
                else
                    ylim(ax,'manual');
                end
                
                % adjust the x limits
                xlim(ax,[0 t(end)+1e-10]);      % we add a tiny amount to t(end) in case it is zero
            end
        end
        
    end
    
    
    methods (Access=private)
 
        % Callback for panel resizing. 
        function SizeChanged(this,parent)
            % get new parent geometry
            parentw = parent.Position(3);
            parenth = parent.Position(4);
            
            % new width, height of each axis
            w = parentw - 65;
            h = (parenth - 120)/2;
            
            % adjust position of ax1
            this.ax1.Position = [50, 110+h, w, h];

            % adjust position of ax2
            this.ax2.Position = [50, 80, w, h];
        end
        
        % Callback for the plot variable selectors
        function selectorCallback(this,control)
            this.render(control);
        end
        
    end
    
    
    methods (Static)
        
        % Check the sys.panels struct
        function syspanel = syscheck(sys)
            % Default panel settings
            syspanel.title = 'Time Portrait';
            syspanel.grid = false;
            syspanel.hold = false;
            syspanel.autolim = true;
            
            % Nothing more to do if sys.panels.bdTimePortrait is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdTimePortrait')
                return;
            end
            
            % sys.panels.bdTimePortrait.title
            if isfield(sys.panels.bdTimePortrait,'title')
                syspanel.title = sys.panels.bdTimePortrait.title;
            end
            
            % sys.panels.bdTimePortrait.grid
            if isfield(sys.panels.bdTimePortrait,'grid')
                syspanel.grid = sys.panels.bdTimePortrait.grid;
            end
            
            % sys.panels.bdTimePortrait.hold
            if isfield(sys.panels.bdTimePortrait,'hold')
                syspanel.hold = sys.panels.bdTimePortrait.hold;
            end
            
            % sys.panels.bdTimePortrait.autolim
            if isfield(sys.panels.bdTimePortrait,'autolim')
                syspanel.autolim = sys.panels.bdTimePortrait.autolim;
            end
        end
        
        
        % The menu is static so that one menu can serve many instances of the class
        function menuobj = constructMenu(fig,control)            
            % init the appdata for the menu     
            appdata.grid = control.sys.panels.bdTimePortrait.grid;
            appdata.hold = control.sys.panels.bdTimePortrait.hold;
            appdata.autolim = control.sys.panels.bdTimePortrait.autolim;            
            setappdata(fig,'bdTimePortrait',appdata);
            
            % grid menu check string
            if appdata.grid
                gridcheck = 'on';
            else
                gridcheck = 'off';
            end
            
            % hold menu check string
            if appdata.hold
                holdcheck = 'on';
            else
                holdcheck = 'off';
            end
            
            % autolim menu check string
            if appdata.autolim
                autolimcheck = 'on';
            else
                autolimcheck = 'off';
            end
            
            % construct menu items
            menuobj = uimenu('Parent',fig, 'Label','Time Portrait', 'Tag','bdTimePortraitMenu');
            uimenu('Parent',menuobj, ...
                   'Label','Grid', ...
                   'Checked',gridcheck, ...
                   'Callback', @(menuitem,~) bdTimePortrait.MenuCallback(fig,menuitem,control) );
            uimenu('Parent',menuobj, ...
                   'Label','Hold', ...
                   'Checked',holdcheck, ...
                   'Callback', @(menuitem,~) bdTimePortrait.MenuCallback(fig,menuitem,control) );
            uimenu('Parent',menuobj, ...
                   'Label','Auto Limits', ...
                   'Checked',autolimcheck, ...
                   'Callback', @(menuitem,~) bdTimePortrait.MenuCallback(fig,menuitem,control) );
        end        
        
        
        % Menu Item Callback
        function MenuCallback(fig,menuitem,control)
            % retrieve the appdata
            appdata = getappdata(fig,'bdTimePortrait');
            
            switch menuitem.Label
                case 'Grid'
                    switch menuitem.Checked
                        case 'on'
                            appdata.grid = false;
                            menuitem.Checked='off';
                        case 'off'
                            appdata.grid = true;
                            menuitem.Checked='on';
                    end
                case 'Hold'
                    switch menuitem.Checked
                        case 'on'
                            appdata.hold = false;
                            menuitem.Checked='off';
                        case 'off'
                            appdata.hold = true;
                            menuitem.Checked='on';
                    end
                case 'Auto Limits'
                    switch menuitem.Checked
                        case 'on'
                            appdata.autolim = false;
                            menuitem.Checked='off';
                        case 'off'
                            appdata.autolim = true;
                            menuitem.Checked='on';
                    end
            end 
            
            % save the new appdata
            setappdata(fig,'bdTimePortrait',appdata);
            
            % notify all panels to redraw
            notify(control,'redraw');
        end
        
    end
    
end
