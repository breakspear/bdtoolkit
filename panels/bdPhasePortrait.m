classdef bdPhasePortrait < handle
    %bdPhasePortrait Brain Dynamics GUI panel for phase portraits.
    %   This class implements phase portraits for the graphical user interface
    %   of the Brain Dynamics Toolbox (bdGUI). Users never call this class
    %   directly. They instead instruct the bdGUI application to load the
    %   panel by specifying options in their model's sys struct. 
    %   
    %SYS OPTIONS
    %   sys.panels.bdPhasePortrait.title = 'Phase Portrait'
    %   sys.panels.bdPhasePortrait.vecfield = false
    %   sys.panels.bdPhasePortrait.markinit = true
    %   sys.panels.bdPhasePortrait.grid = false
    %   sys.panels.bdPhasePortrait.hold = false
    %   sys.panels.bdPhasePortrait.autolim = true
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
        fig                 % handle to parent figure
        tab                 % handle to uitab object
        ax                  % handle to plot axes
        popupx              % handle to X popup
        popupy              % handle to Y popup
        popupz              % handle to Z popup
        checkbox3D          % handle to 3D checkbox
        solMap              % maps rows in sol.y to entries in vardef
        listener            % handle to listener
    end
    
    methods
        function this = bdPhasePortrait(tabgroup,control)
            % Construct a new tab panel in the parent tabgroup.
            % Usage:
            %    bdPhasePortrait(tabgroup,title,control)
            % where 
            %    tabgroup is a handle to the parent uitabgroup object.
            %    title is a string defining the name given to the new tab.
            %    control is a handle to the GUI control panel.
            % validate the sys.panels settings

            % apply default settings to sys.panels.bdPhasePortrait
            control.sys.panels.bdPhasePortrait = bdPhasePortrait.syscheck(control.sys);

            % get handle to parent figure
            this.fig = ancestor(tabgroup,'figure');

            % map vardef and auxdef entries to rows in sol and sal
            this.solMap = bd.solMap(control.sys.vardef);
            
            % number of entries in vardef
            nvardef = numel(control.sys.vardef);
            
            % construct the uitab
            this.tab = uitab(tabgroup,'title',control.sys.panels.bdPhasePortrait.title, 'Tag','bdPhasePortraitTab', 'Units','pixels');
            
            % get tab geometry
            parentw = this.tab.Position(3);
            parenth = this.tab.Position(4);

            % axes
            posx = 50;
            posy = 80;
            posw = parentw-65;
            posh = parenth-90;
            this.ax  = axes('Parent',this.tab, 'Units','pixels', 'Position',[posx posy posw posh]);           
            hold(this.ax,'on');
            
            % x selector
            posx = 10;
            posy = 10;
            posw = 100;
            posh = 20;
            popupval = 1;            
            this.popupx = uicontrol('Style','popup', ...
                'String', {this.solMap.name}, ...
                'Value', popupval, ...
                'Callback', @(~,~) this.selectorCallback(control), ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', this.tab, ...
                'Position',[posx posy posw posh]);

            % y selector
            posx = 110;
            posy = 10;
            posw = 100;
            posh = 20; 
            if nvardef>=2
                popupval = numel(control.sys.vardef(1).value) + 1;
            end
            this.popupy = uicontrol('Style','popup', ...
                'String', {this.solMap.name}, ...
                'Value', popupval, ...
                'Callback', @(~,~) this.selectorCallback(control), ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', this.tab, ...
                'Position',[posx posy posw posh]);
            
            % z selector
            posx = 210;
            posy = 10;
            posw = 100;
            posh = 20;
            if nvardef>=3
                popupval = numel(control.sys.vardef(1).value) + numel(control.sys.vardef(2).value) + 1;
            end
            this.popupz = uicontrol('Style','popup', ...
                'String', {this.solMap.name}, ...
                'Value', popupval, ...
                'Enable','off', ...
                'Callback', @(~,~) this.selectorCallback(control), ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', this.tab, ...
                'Position',[posx posy posw posh]);
            
            % 3D toggle
            posx = 310;
            posy = 10;
            posw = 100;
            posh = 20;
            this.checkbox3D = uicontrol('Style','checkbox', ...
                'String', '3D', ...
                'Value',0, ...
                'Callback', @(~,~) this.check3DCallback(control), ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', this.tab, ...
                'Position',[posx posy posw posh]);

           
            % construct the PhasePortrait menu (if it does not already exist)
            obj = findobj(this.fig,'Tag','bdPhasePortraitMenu');
            if isempty(obj)
                bdPhasePortrait.constructMenu(this.fig,control);
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
            % delete the PhasePortrait menu if no more PhasePortaits exist
            obj = findobj(this.fig,'Tag','bdPhasePortraitTab');
            if isempty(obj)
                obj = findobj(this.fig,'Tag','bdPhasePortraitMenu');
                if ~isempty(obj)
                    delete(obj);
                end
            end
        end
            
    end
    
    methods (Access=private)   
        
        function render(this,control)
            %disp('bdPhasePortrait.render()')
            
            % retrieve the menu appdata
            appdata = getappdata(this.fig,'bdPhasePortrait');

            % convergence test
            steadystate = convergence(control);
            
            % read the popup widgets
            xindx = this.popupx.Value;
            yindx = this.popupy.Value;
            zindx = this.popupz.Value;
            xstr = this.popupx.String{xindx};
            ystr = this.popupy.String{yindx};
            zstr = this.popupz.String{zindx};
            
            % current time domain
            tindx = find(control.sol.x>=0);
            
            % if 'hold' menu is checked then ...
            if appdata.hold
                % Change existing plots to thin lines 
                objs = findobj(this.ax);
                set(objs,'LineWidth',0.5);               
            else
                % Clear the plot axis
                cla(this.ax); 
            end
            
            % 
            if this.checkbox3D.Value
                % plot current trajectory in 3D
                x = control.sol.y(xindx,tindx);
                y = control.sol.y(yindx,tindx);
                z = control.sol.y(zindx,tindx);

                plot3(this.ax, x,y,z, 'color','k','Linewidth',1);
                if appdata.markinit
                    plot3(this.ax, x(1),y(1),z(1), 'color','k', 'marker','pentagram', 'markerfacecolor','y', 'markersize',12);
                end
                if steadystate
                    plot3(this.ax, x(end),y(end),z(end), 'color','k', 'marker','o', 'markerfacecolor','k', 'markersize',6);               
                end
                
                xlabel(this.ax,xstr, 'FontSize',16);
                ylabel(this.ax,ystr, 'FontSize',16);
                zlabel(this.ax,zstr, 'FontSize',16);

                if appdata.vecfield
                    % compute vector field
                    xlimit = this.ax.XLim;
                    ylimit = this.ax.YLim;
                    [xmesh,ymesh,dxmesh,dymesh] = this.VectorField2D(control,tindx(1),xindx,yindx,xlimit,ylimit);

                    zmesh = ones(size(xmesh)) .* z(1);
                    dzmesh = zeros(size(zmesh));
                    
                    % plot vector field
                    quiver3(xmesh,ymesh,zmesh,dxmesh,dymesh,dzmesh,'parent',this.ax, 'color',[0.5 0.5 0.5]);
                    % dont let the quiver plot change the original axes limits
                    this.ax.XLim = xlimit;
                    this.ax.YLim = ylimit;
                end

           else
                % plot current trajectory in 2D
                x = control.sol.y(xindx,tindx);
                y = control.sol.y(yindx,tindx);

                plot(this.ax, x,y, 'color','k','Linewidth',1);
                if appdata.markinit
                    plot(this.ax, x(1),y(1), 'color','k', 'marker','pentagram', 'markerfacecolor','y', 'markersize',12);
                end
                if steadystate
                    plot(this.ax, x(end),y(end), 'color','k', 'marker','o', 'markerfacecolor','k', 'markersize',6);               
                end
                
                xlabel(this.ax,xstr, 'FontSize',16);
                ylabel(this.ax,ystr, 'FontSize',16);
                
                if appdata.vecfield
                    % compute vector field
                    xlimit = this.ax.XLim;
                    ylimit = this.ax.YLim;
                    [xmesh,ymesh,dxmesh,dymesh] = this.VectorField2D(control,tindx(1),xindx,yindx,xlimit,ylimit);

                    % plot vector field
                    quiver(xmesh,ymesh,dxmesh,dymesh, 'parent',this.ax, 'color',[0.5 0.5 0.5]);
                    % dont let the quiver plot change the original axes limits
                    this.ax.XLim = xlimit;
                    this.ax.YLim = ylimit;
                end
                
                % adjust the y limits (or not)
                if appdata.autolim
                    xlim(this.ax,'auto')
                    ylim(this.ax,'auto')
                else
                    xlim(this.ax,'manual');
                    ylim(this.ax,'manual');
                end
            end
            
            % show gridlines (if appropriate)
            if appdata.grid
                grid(this.ax,'on');
            else
                grid(this.ax,'off');
            end

        end
        
        % Evaluate the 2D vector field 
        function [xmesh,ymesh,dxmesh,dymesh] = VectorField2D(this,control,tindx,xindx,yindx,xlimit,ylimit)
            %disp('bdPhasePortrait.VectorField2D()');

            % Determine the type of the active solver
            solvertype = control.solvermap(control.solveridx).solvertype;

            % Do not compute vector fields for delay differential equations 
            if strcmp(solvertype,'ddesolver')
                xmesh=[];
                ymesh=[];
                dxmesh=[];
                dymesh=[];
                return
            end
            
            % compute a mesh for the domain
            xdomain = linspace(xlimit(1),xlimit(2), 21);
            ydomain = linspace(ylimit(1),ylimit(2), 21);
            [xmesh,ymesh] = meshgrid(xdomain,ydomain);
            dxmesh = NaN(size(xmesh));
            dymesh = dxmesh;
            meshlen = numel(xmesh);
            
            % evaluate the vector field at trajectory end
            %Y0 = control.sol.y(:,end);
            
            % evaluate the vector field at t(tindx)
            Y0 = control.sol.y(:,tindx);
            
            % curent parameter values
            P0  = {control.sys.pardef.value};

            
            % evaluate vector field
            for idx=1:meshlen
                % set initial conditions to curent mesh point
                Y0(xindx) = xmesh(idx);
                Y0(yindx) = ymesh(idx);
                % evaluate ODE
                dY = control.sys.odefun(0,Y0,P0{:});
                % save results
                dxmesh(idx) = dY(xindx);
                dymesh(idx) = dY(yindx);
            end
        end

%         % Evaluate the 3D vector field 
%         function [xmesh,ymesh,zmesh,dxmesh,dymesh,dzmesh] = VectorField3D(this,control,tindx,xindx,yindx,zindx,xlimit,ylimit,zlimit)
%             %disp('bdPhasePortrait.VectorField3D()');
% 
%             % Determine the type of the active solver
%             solvertype = control.solvermap(control.solveridx).solvertype;
%             
%             % Do not compute vector fields for delay differential equations 
%             if strcmp(solvertype,'ddesolver')
%                 xmesh=[];
%                 ymesh=[];
%                 zmesh=[];
%                 dxmesh=[];
%                 dymesh=[];
%                 dzmesh=[];
%                 return
%             end
%             
%             % compute a mesh for the domain
%             xdomain = linspace(xlimit(1),xlimit(2), 7);
%             ydomain = linspace(ylimit(1),ylimit(2), 7);
%             zdomain = linspace(zlimit(1),zlimit(2), 7);
%             [xmesh,ymesh,zmesh] = meshgrid(xdomain,ydomain,zdomain);
%             dxmesh = NaN(size(xmesh));
%             dymesh = dxmesh;
%             dzmesh = dxmesh;
%             meshlen = numel(xmesh);
%             
%             % evaluate vector field at trajectory end
%             Y0 = control.sol.y(:,end);
%             
%             % curent parameter values
%             P0 = {control.sys.pardef.value};
%             
%             % evaluate vector field
%             for idx=1:meshlen
%                 % set initial conditions to curent mesh point
%                 Y0(xindx) = xmesh(idx);
%                 Y0(yindx) = ymesh(idx);
%                 Y0(zindx) = zmesh(idx);
%                 % compute ODE (assume t=0)
%                 dY = control.sys.odefun(0,Y0,P0{:});
%                 % save results
%                 dxmesh(idx) = dY(xindx);
%                 dymesh(idx) = dY(yindx);
%                 dzmesh(idx) = dY(zindx);
%             end
%         end       
        
        % Callback for panel resizing. 
        function SizeChanged(this,parent)
            % get new parent geometry
            parentw = parent.Position(3);
            parenth = parent.Position(4);            
            % resize the axes
            this.ax.Position = [50, 80, parentw-65, parenth-90];
        end
        
        % Callback function for the plot variable selectors
        function selectorCallback(this,control)
            this.render(control);
        end
        
        % Callback function for the 3D checkbox
        function check3DCallback(this,control)
            if this.checkbox3D.Value
                set(this.popupz,'Enable','on');
                this.ax.View=[-37.5 0.3];
            else
                set(this.popupz,'Enable','off');
                this.ax.View=[0 90];
            end
            this.render(control);           
        end
        
    end
    
    
    methods (Static)
                
        % Check the sys.panels struct
        function syspanel = syscheck(sys)
            % Default panel settings
            syspanel.title = 'Phase Portrait';
            syspanel.vecfield = false;
            syspanel.markinit = true;
            syspanel.grid = false;
            syspanel.hold = false;
            syspanel.autolim = true;
            
            % Nothing more to do if sys.panels.bdPhasePortrait is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdPhasePortrait')
                return;
            end
            
            % sys.panels.bdPhasePortrait.title
            if isfield(sys.panels.bdPhasePortrait,'title')
                syspanel.title = sys.panels.bdPhasePortrait.title;
            end
            
            % sys.panels.bdPhasePortrait.grid
            if isfield(sys.panels.bdPhasePortrait,'grid')
                syspanel.grid = sys.panels.bdPhasePortrait.grid;
            end
            
            % sys.panels.bdPhasePortrait.hold
            if isfield(sys.panels.bdPhasePortrait,'hold')
                syspanel.hold = sys.panels.bdPhasePortrait.hold;
            end
            
            % sys.panels.bdPhasePortrait.autolim
            if isfield(sys.panels.bdPhasePortrait,'autolim')
                syspanel.autolim = sys.panels.bdPhasePortrait.autolim;
            end
        end

        % The menu is static so that one menu can serve many instances of the class
        function menuobj = constructMenu(fig,control)            
            % init the appdata for the menu
            appdata.vecfield = control.sys.panels.bdPhasePortrait.vecfield;
            appdata.markinit = control.sys.panels.bdPhasePortrait.markinit;
            appdata.grid = control.sys.panels.bdPhasePortrait.grid;
            appdata.hold = control.sys.panels.bdPhasePortrait.hold;
            appdata.autolim = control.sys.panels.bdPhasePortrait.autolim;            
            setappdata(fig,'bdPhasePortrait',appdata);
            
            % vector-field menu check string
            if appdata.vecfield
                vecfieldcheck = 'on';
            else
                vecfieldcheck = 'off';
            end
            
            % initial conditions markers menu check string
            if appdata.markinit
                markinitcheck = 'on';
            else
                markinitcheck = 'off';
            end
            
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
            menuobj = uimenu('Parent',fig, 'Label','Phase Portrait', 'Tag','bdPhasePortraitMenu');
            uimenu('Parent',menuobj, ...
                   'Label','Vector Field', ...
                   'Checked',vecfieldcheck, ...
                   'Callback', @(menuitem,~) bdPhasePortrait.MenuCallback(fig,menuitem,control) );          
            uimenu('Parent',menuobj, ...
                   'Label','Initial Conditions', ...
                   'Checked',markinitcheck, ...
                   'Callback', @(menuitem,~) bdPhasePortrait.MenuCallback(fig,menuitem,control) );          
            uimenu('Parent',menuobj, ...
                   'Label','Grid', ...
                   'Checked',gridcheck, ...
                   'Callback', @(menuitem,~) bdPhasePortrait.MenuCallback(fig,menuitem,control) );
            uimenu('Parent',menuobj, ...
                   'Label','Hold', ...
                   'Checked',holdcheck, ...
                   'Callback', @(menuitem,~) bdPhasePortrait.MenuCallback(fig,menuitem,control) );
            uimenu('Parent',menuobj, ...
                   'Label','Auto Limits', ...
                   'Checked',autolimcheck, ...
                   'Callback', @(menuitem,~) bdPhasePortrait.MenuCallback(fig,menuitem,control) );
        end        
        
        % Menu Item Callback
        function MenuCallback(fig,menuitem,control)
            % retrieve the appdata
            appdata = getappdata(fig,'bdPhasePortrait');
            
            switch menuitem.Label
                case 'Vector Field'
                    switch menuitem.Checked
                        case 'on'
                            appdata.vecfield = false;
                            menuitem.Checked='off';
                        case 'off'
                            appdata.vecfield = true;
                            menuitem.Checked='on';
                    end
                    
                case 'Initial Conditions'
                    switch menuitem.Checked
                        case 'on'
                            appdata.markinit = false;
                            menuitem.Checked='off';
                        case 'off'
                            appdata.markinit = true;
                            menuitem.Checked='on';
                    end
                    
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
            setappdata(fig,'bdPhasePortrait',appdata);
            
            % notify all panels to redraw
            notify(control,'redraw');
        end
        
    end
    
end


% Returns TRUE if the trajectory has converged to a fixed point
% otherwise returns FALSE.
function flag = convergence(control)
    dt = diff(control.sol.x(end-1:end));
    dY1 = diff(control.sol.y(:,end-2:end),1,2); 
    dY2 = diff(dY1,1,2);
    if isempty(dY2)
        flag=false;
    else
        flag = (norm(dY2) < (1e-3 * dt));
    end
end
    
