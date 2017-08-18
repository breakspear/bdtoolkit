classdef bdHilbert < handle
    %bdHilbert  Brain Dynamics Toolbox panel for the Hilbert transfrom.
    %   This class implements the Hilbert transform for the graphical user
    %   interface of the Brain Dynamics Toolbox (bdGUI). Users never call
    %   this class directly. They instead instruct the bdGUI application
    %   to load the panel by specifying options in their model's sys struct. 
    %   
    %SYS OPTIONS
    %   sys.panels.bdHilbert.title = 'Hilbert'
    %   sys.panels.bdHilbert.grid = false
    %   sys.panels.bdHilbert.hold = false
    %
    %AUTHORS
    %  Stewart Heitmann (2017b)

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
    properties (Access=public)
        t               % time scale of phase plot
        h               % hilbert transform
        p               % phase values
    end
    
    properties (Access=private) 
        fig             % handle to parent figure
        tab             % handle to uitab object
        ax1             % handle to plot 1 axes
        ax2             % handle to plot 2 axes
        popup1          % handle to popup selector 1
        popup2          % handle to popup selector 2
        checkbox        % handle to "Relative Plot" checkbox
        varMap          % maps entries in vardef to rows in sol.y
        auxMap          % maps entries in auxdef to rows in sal
        solMap          % maps rows in sol.y to entries in vardef
        soxMap          % maps rows in sox.y to entries in auxdef
        listener        % handle to listener
        gridflag        % grid menu flag
        holdflag        % hold menu flag
        autolimflag     % auto limits menu flag        
    end
    
    methods
        function this = bdHilbert(tabgroup,control)
            % Construct a new tab panel in the parent tabgroup.
            % Usage:
            %    bdHilbert(tabgroup,control)
            % where 
            %    tabgroup is a handle to the parent uitabgroup object.
            %    control is a handle to the GUI control panel.

            % apply default settings to sys.panels.bdHilbert
            control.sys.panels.bdHilbert = bdHilbert.syscheck(control.sys);
            
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
            this.tab = uitab(tabgroup, ...
                'title',control.sys.panels.bdHilbert.title, ...
                'Tag','bdHilbertTab', ...
                'Units','pixels', ...
                'TooltipString','Right click for menu');
            
            % get tab geometry
            parentw = this.tab.Position(3);
            parenth = this.tab.Position(4);

            % check that we have the signal processing toolbox (for the hilbert
            % function)
            if ~license('test','Signal_Toolbox') || ~exist('hilbert','file')
                % Signal Processing Toolbox is missing 
                uicontrol('Style','text', ...
                          'String','Requires the Matlab Signal Processing Toolbox', ...
                          'Parent', this.tab, ...
                          'HorizontalAlignment','center', ...
                          'Units','normal', ...
                          'Position',[0 0.5 1 0.1]);

                % construct the tab context menu
                this.contextMenu(control);
            else            
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
                axis(this.ax2,'off'); 

                % plot var selector 1
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

                % plot var selector 2
                posx = 110;
                posy = 10;
                posw = 100;
                posh = 20;
                popuplist = {this.solMap.name, this.soxMap.name};
                this.popup2 = uicontrol('Style','popup', ...
                    'String', popuplist, ...
                    'Value', popupval, ...
                    'Enable', 'off', ...
                    'Callback', @(~,~) this.selectorCallback(control), ...
                    'HorizontalAlignment','left', ...
                    'FontUnits','pixels', ...
                    'FontSize',12, ...
                    'Parent', this.tab, ...
                    'Position',[posx posy posw posh]);

                % Relative Phase toggle button
                posx = 210;
                posy = 10;
                posw = 200;
                posh = 20;
                this.checkbox = uicontrol('Style','checkbox', ...
                    'String', 'Phase Relative to ...', ...
                    'Value',0, ...
                    'Callback', @(~,~) this.checkboxCallback(control), ...
                    'FontUnits','pixels', ...
                    'FontSize',12, ...
                    'Parent', this.tab, ...
                    'Position',[posx posy posw posh]);
            
                % construct the tab context menu
                this.contextMenu(control);

                % register a callback for resizing the panel
                set(this.tab,'SizeChangedFcn', @(~,~) SizeChanged(this,this.tab));

                % listen to the control panel for redraw events
                this.listener = addlistener(control,'redraw',@(~,~) this.render(control));    
            end
        end
        
        % Destructor
        function delete(this)
            delete(this.listener);
            delete(this.tab);          
        end
        
        function render(this,control)
            %disp('bdHilbert.render()')
            
            % number of entries in sol
            nvardef = numel(this.solMap);
                
            % read the main popup variable selector
            popindx1 = this.popup1.Value;
            
            % if the user selected a variable from vardef then ...
            if popindx1 <= nvardef
                % the popup index corresponds to the row index of sol
                solindx = popindx1; 

                % get detail of the selected variable
                name    = this.solMap(solindx).name;        % name string
                varindx = this.solMap(solindx).varindx;     % index in vardef{}

                % find all rows of sol.y that are related to this vardef entry
                solrows = this.varMap(varindx).solindx;

                % extract the values needed for analysis
                this.t = control.sol.x;
                y = control.sol.y(solrows,:);
                
                % index of the variable of interest
                yrow = solindx - solrows(1) + 1;
            else
                % the popup index refers to an entry of sox
                solindx = popindx1 - nvardef;

                % get detail of the selected variable
                name    = this.soxMap(solindx).name;        % name string
                auxindx = this.soxMap(solindx).varindx;     % auxdef index

                % find all rows of aux that are related to this auxdef entry
                solrows = this.auxMap(auxindx).solindx;

                % extract the values needed for analysis
                this.t = control.sox.x;
                y = control.sox.y(solrows,:);

                % index of the variable of interest
                yrow = solindx - solrows(1) + 1;
            end
 
            % compute the Hilbert transfrom
            this.h = hilbert(y')';

            % compute the phase angles from the Hilbert transfrom
            this.p = angle(this.h);
                        
            % Compute the relative phase (if enabled)
            if this.checkbox.Value
               % read the second popup variable selector
                popindx2 = this.popup2.Value;
            
                % if the user selected a variable from vardef then ...
                if popindx2 <= nvardef
                    % the popup index corresponds to the row index of sol
                    y2 = control.sol.y(popindx2,:);
                else
                    % the popup index refers to an entry of sox
                    y2 = control.sox.y(popindx2-nvardef,:);
                end
            
                % compute the Hilbert transfrom
                h2 = hilbert(y2')';

                % compute the phase angles from the Hilbert transfrom
                p2 = angle(h2);
             
                % repeat the rows of p2 to match this.p
                p2 = p2(ones(1,size(this.p,1)),:);
                
                % adjust the phase angles of the first variable relative to this one
                this.p = this.p - p2;
            end
            
            % isolate the non-negative time entries
            tindx = find(this.t>=0);
            tt = this.t(tindx);
            yy = y(:,tindx);
            pp = this.p(:,tindx);
            pp = pp - mean(pp(:,1)) - pi/2;
            cosp = cos(pp);
            sinp = sin(pp);
            
            % if 'hold' menu is checked then ...
            if this.holdflag
                % Change existing plots on ax1 to thin lines 
                objs = findobj(this.ax1);
                set(objs,'LineWidth',0.5);               
                % Change existing plots on ax2 to thin lines 
                objs = findobj(this.ax2);
                set(objs,'LineWidth',0.5);               
            else
                % Clear the plot axis
                cla(this.ax1);
                cla(this.ax2);
            end
            
            % show gridlines (or not)
            if this.gridflag
                grid(this.ax1,'on');
                grid(this.ax2,'on');
            else
                grid(this.ax1,'off')
                grid(this.ax2,'off')
            end
            
            % Plot the original signal in ax1
            % ... with the background traces in grey
            plot(this.ax1, tt, yy, 'color',[0.75 0.75 0.75], 'HitTest','off');              
            % ... and variable of interest in black
            plot(this.ax1, tt, yy(yrow,:), 'color','k', 'Linewidth',1.5);
            ylabel(this.ax1,name, 'FontSize',16,'FontWeight','normal');

            [Y,Z,X] = cylinder(0.95*ones(1,31),31);
            edgecolor = 0.8*[1 1 1];
            facecolor = 1.0*[1 1 1];
            edgealpha = 0.7;
            facealpha = 0.7;

            span = tt(end)-tt(1);
            hnd = mesh(this.ax2, X.*span,Y,Z, 'EdgeColor',edgecolor,'FaceColor',facecolor, 'FaceAlpha',facealpha, 'EdgeAlpha',edgealpha);
            view(this.ax2,-5,0);
            xlim(this.ax2,[tt(1) tt(end)]);
            ylim(this.ax2, [-1 1]);
            zlim(this.ax2, [-1 1]);
            hold on;

            % Plot the phase cyliner in ax2
            plot3(this.ax2, tt, 0.975*sinp, 0.975*cosp, 'color',[0.5 0.5 0.5], 'HitTest','off');
            plot3(this.ax2, tt, sinp(yrow,:), cosp(yrow,:), 'color','k', 'Linewidth',1.5);
        end        
    end
    
    
    methods (Access=private)

        function contextMenu(this,control)            
            % init the menu flags from the sys.panels options     
            this.gridflag = control.sys.panels.bdHilbert.grid;
            this.holdflag = control.sys.panels.bdHilbert.hold;
            
            % grid menu check string
            if this.gridflag
                gridcheck = 'on';
            else
                gridcheck = 'off';
            end
            
            % hold menu check string
            if this.holdflag
                holdcheck = 'on';
            else
                holdcheck = 'off';
            end
            
            % construct the tab context menu
            this.tab.UIContextMenu = uicontextmenu;

            % construct menu items
            uimenu(this.tab.UIContextMenu, ...
                   'Label','Grid', ...
                   'Checked',gridcheck, ...
                   'Callback', @(menuitem,~) ContextCallback(menuitem) );
            uimenu(this.tab.UIContextMenu, ...
                   'Label','Hold', ...
                   'Checked',holdcheck, ...
                   'Callback', @(menuitem,~) ContextCallback(menuitem) );
            uimenu(this.tab.UIContextMenu, ...
                   'Label','Close', ...
                   'Callback',@(~,~) this.delete());
        
            % Context Menu Item Callback
            function ContextCallback(menuitem)
                switch menuitem.Label
                    case 'Grid'
                        switch menuitem.Checked
                            case 'on'
                                this.gridflag = false;
                                menuitem.Checked='off';
                            case 'off'
                                this.gridflag = true;
                                menuitem.Checked='on';
                        end
                    case 'Hold'
                        switch menuitem.Checked
                            case 'on'
                                this.holdflag = false;
                                menuitem.Checked='off';
                            case 'off'
                                this.holdflag = true;
                                menuitem.Checked='on';
                        end
                end 
                % redraw this panel
                this.render(control);
            end
        end
        
        % Callback for the "relative phase" checkbox
        function checkboxCallback(this,control)
            if this.checkbox.Value
                set(this.popup2,'Enable','on');
            else
                set(this.popup2,'Enable','off');
            end
            this.render(control);           
        end
                
        % Callback for panel resizing. 
        function SizeChanged(this,parent)
            % get new parent geometry
            parentw = parent.Position(3);
            parenth = parent.Position(4);
            
            % new width, height of each axis
            w = parentw - 65;
            h = (parenth - 110)/2;
            
            % adjust position of ax1
            this.ax1.Position = [50, 100+h, w-15, h];

            % adjust position of ax2
            this.ax2.Position = [20, 50, w+35, h];
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
            syspanel.title = 'Hilbert';
            syspanel.grid = false;
            syspanel.hold = false;
            syspanel.autolim = true;
            
            % Nothing more to do if sys.panels.bdHilbert is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdHilbert')
                return;
            end
            
            % sys.panels.bdHilbert.title
            if isfield(sys.panels.bdHilbert,'title')
                syspanel.title = sys.panels.bdHilbert.title;
            end
            
            % sys.panels.bdHilbert.grid
            if isfield(sys.panels.bdHilbert,'grid')
                syspanel.grid = sys.panels.bdHilbert.grid;
            end
            
            % sys.panels.bdHilbert.hold
            if isfield(sys.panels.bdHilbert,'hold')
                syspanel.hold = sys.panels.bdHilbert.hold;
            end
        end
        
    end
    
end
