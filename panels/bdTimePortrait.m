classdef bdTimePortrait < handle
    %bdTimePortrait - a GUI tab panel for displaying time plots.
    %   Displays time plots in the Brain Dynamics Toolbox GUI.

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
        salMap          % maps rows in sal to entries in auxdef
    end
    
    methods
        function this = bdTimePortrait(tabgroup,control)
            % Construct a new tab panel in the parent tabgroup.
            % Usage:
            %    bdTimePortrait(tabgroup,title,control)
            % where 
            %    tabgroup is a handle to the parent uitabgroup object.
            %    title is a string defining the name given to the new tab.
            %    control is a handle to the GUI control panel.

            % default sys.gui settings
            title = 'Time Portrait';

            % sys.gui.bdTimePortrait.title
            if isfield(control.sys.gui,'bdTimePortrait') && isfield(control.sys.gui.bdTimePortrait,'title')
                title = control.sys.gui.bdTimePortrait.title;
            end
            
            % get handle to parent figure
            this.fig = ancestor(tabgroup,'figure');
            
            % map vardef entries to rows in sol
            this.varMap = bdUtils.varMap(control.sys.vardef);
            this.solMap = bdUtils.solMap(control.sys.vardef);
            if isfield(control.sys,'auxdef')
                % map auxdef entries to rows in sal
                this.auxMap = bdUtils.varMap(control.sys.auxdef);
                this.salMap = bdUtils.solMap(control.sys.auxdef);
            else
                % construct empty maps
                this.auxMap = bdUtils.varMap([]);
                this.salMap = bdUtils.solMap([]);
            end
            
            % number of entries in vardef
            nvardef = size(control.sys.vardef,1);
                        
            % construct the uitab
            this.tab = uitab(tabgroup,'title',title, 'Units','pixels');
            
            % get tab geometry
            parentw = this.tab.Position(3);
            parenth = this.tab.Position(4);

            % plot axes 1
            posw = parentw-65;
            posh = (parenth-120)/2;
            posx = 50;
            posy = 100 + posh;
            this.ax1 = axes('Parent',this.tab, 'Units','pixels', 'Position',[posx posy posw posh]);           
            
            % plot axes 2
            posw = parentw-65;
            posh = (parenth-120)/2;
            posx = 50;
            posy = 80;
            this.ax2 = axes('Parent',this.tab, 'Units','pixels', 'Position',[posx posy posw posh]);           
            
            % plot 1 popup selector
            posx = 10;
            posy = 10;
            posw = 100;
            posh = 20;
            popupval = 1;  
            popuplist = {this.solMap.name, this.salMap.name};
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
                popupval = numel(control.sys.vardef{1,2}) + 1;
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

            % register a callback for resizing the panel
            set(this.tab,'SizeChangedFcn', @(~,~) SizeChanged(this,this.tab));
            
            % listen to the control panel for redraw events
            addlistener(control,'redraw',@(~,~) this.render(control));    
        end
        
        function render(this,control)
            %disp('bdTimePortrait.render()')

            % retrieve the menu appdata
            appdata = getappdata(this.fig,'bdTimePortrait');

            % render the upper and lower axes 
            renderax(this.ax1, this.popup1.Value);
            renderax(this.ax2, this.popup2.Value);            
            xlabel(this.ax2,'time', 'FontSize',14);

            % show gridlines (or not)
            if appdata.gridflag
                grid(this.ax1,'on');
                grid(this.ax2,'on');
            else
                grid(this.ax1,'off')
                grid(this.ax2,'off')
            end

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
                    % the popup index refers to an entry of sal
                    salindx = popindx - nvardef;
                    
                    % get detail of the selected variable
                    name    = this.salMap(salindx).name;        % name string
                    auxindx = this.salMap(salindx).varindx;     % auxdef index

                    % find all rows of aux that are related to this auxdef entry
                    salrows = this.auxMap(auxindx).solindx;

                    % extract the values for plotting
                    y = control.sal(salrows,tindx);

                    % index of the variable of interest
                    yrow = salindx - salrows(1) + 1;
                end

                % plot the background traces in grey
                plot(ax, t, y', 'color',[0.75 0.75 0.75]);
                hold(ax,'on');
                
                % (re)plot the variable of interest in black
                plot(ax, t, y(yrow,:), 'color','k', 'Linewidth',1.5);
                ylabel(ax,name, 'FontSize',16,'FontWeight','normal');

                hold(ax,'off');      
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
        
        % The menu is static so that one menu can serve many instances of the class
        function menuobj = constructMenu(fig,control)            
            % init the appdata for the menu     
            appdata = struct('gridflag',false);
            setappdata(fig,'bdTimePortrait',appdata);
            
            % construct menu items
            menuobj = uimenu('Parent',fig, 'Label','Time Portrait', 'Tag','bdTimePortraitMenu');
            uimenu('Parent',menuobj, ...
                   'Label','Grid', ...
                   'Checked','off', ...
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
                            appdata.gridflag = false;
                            menuitem.Checked='off';
                        case 'off'
                            appdata.gridflag = true;
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
