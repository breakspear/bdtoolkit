classdef bdPhasePortrait < handle
    %bdPhasePortrait Brain Dynamics GUI panel for phase portraits.
    %   Displays 2D and 3D trajectories in the Brain Dynamics Toolbox GUI.
    %
    %SYS OPTIONS
    %   sys.gui.bdPhasePortrait.title      Name of the panel (optional)
    %
    %AUTHORS
    %  Stewart Heitmann (2016a)

    % Copyright (C) 2016, QIMR Berghofer Medical Research Institute
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
            % validate the sys.gui settings

            if ~isfield(control.sys.gui,'bdPhasePortrait')
                return      % we aren't wanted so quietly do nothing.
            end
            
            % sys.gui.bdTimePortrait.title (optional)
            if isfield(control.sys.gui.bdPhasePortrait,'title')
                title = control.sys.gui.bdPhasePortrait.title;
            else
                title = 'Phase Portrait';
            end

            % get handle to parent figure
            this.fig = ancestor(tabgroup,'figure');

            % map vardef and auxdef entries to rows in sol and sal
            this.solMap = bdUtils.solMap(control.sys.vardef);
            
            % number of entries in vardef
            nvardef = size(control.sys.vardef,1);
            
            % construct the uitab
            this.tab = uitab(tabgroup,'title',title, 'Units','pixels');
            
            % get tab geometry
            parentw = this.tab.Position(3);
            parenth = this.tab.Position(4);

            % axes
            posx = 50;
            posy = 80;
            posw = parentw-65;
            posh = parenth-90;
            this.ax  = axes('Parent',this.tab, 'Units','pixels', 'Position',[posx posy posw posh]);           
            
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
                popupval = numel(control.sys.vardef{1,2}) + 1;
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
                popupval = numel(control.sys.vardef{1,2}) + numel(control.sys.vardef{2,2}) + 1;
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
            
            % register a callback for resizing the panel
            set(this.tab,'SizeChangedFcn', @(~,~) SizeChanged(this,this.tab));

            % listen to the control panel for redraw events
            addlistener(control,'redraw',@(~,~) this.render(control));            
        end
            
    end
    
    methods (Access=private)   
        
        function render(this,control)
            %disp('bdPhasePortrait.render()')
            
            % retrieve the menu appdata
            appdata = getappdata(this.fig,'bdPhasePortrait');

            % convergence test
            steadystate = convergence(control);
            
            xindx = this.popupx.Value;
            yindx = this.popupy.Value;
            zindx = this.popupz.Value;
            xstr = this.popupx.String{xindx};
            ystr = this.popupy.String{yindx};
            zstr = this.popupz.String{zindx};
            tindx = find(control.sol.x>=0);
            if this.checkbox3D.Value
                % plot current trajectory in 3D
                x = control.sol.y(xindx,tindx);
                y = control.sol.y(yindx,tindx);
                z = control.sol.y(zindx,tindx);

                plot3(this.ax, x,y,z, 'color','k','Linewidth',1);
                hold(this.ax, 'on');
                if appdata.initflag
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
                    zlimit = this.ax.ZLim;
                    [xmesh,ymesh,zmesh,dxmesh,dymesh,dzmesh] = this.VectorField3D(control,xindx,yindx,zindx,xlimit,ylimit,zlimit);

                    % plot vector field in axv
                    quiver3(xmesh,ymesh,zmesh,dxmesh,dymesh,dzmesh,'parent',this.ax, 'color',[0.5 0.5 0.5]);
                    % dont let the quiver plot change the original axes limits
                    this.ax.XLim = xlimit;
                    this.ax.YLim = ylimit;
                    this.ax.ZLim = zlimit;
                end
                
                % show gridlines (if appropriate) 
                if appdata.gridflag
                    grid(this.ax,'on');
                else
                    grid(this.ax,'off');
                end                    
                
                hold(this.ax, 'off');
           else
                % plot current trajectory in 2D
                x = control.sol.y(xindx,tindx);
                y = control.sol.y(yindx,tindx);

                plot(this.ax, x,y, 'color','k','Linewidth',1);
                hold(this.ax, 'on');
                if appdata.initflag
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
                    [xmesh,ymesh,dxmesh,dymesh] = this.VectorField2D(control,xindx,yindx,xlimit,ylimit);

                    % plot vector field in axv
                    quiver(xmesh,ymesh,dxmesh,dymesh, 'parent',this.ax, 'color',[0.5 0.5 0.5]);
                    % dont let the quiver plot change the original axes limits
                    this.ax.XLim = xlimit;
                    this.ax.YLim = ylimit;
                end
                
                % show gridlines (if appropriate)
                if appdata.gridflag
                    grid(this.ax,'on');
                else
                    grid(this.ax,'off');
                end                    
                
                hold(this.ax, 'off');
            end
        end
        
        % Evaluate the 2D vector field 
        function [xmesh,ymesh,dxmesh,dymesh] = VectorField2D(this,control,xindx,yindx,xlimit,ylimit)
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
            Y0 = control.sol.y(:,end);
            
            % curent parameter values
            P0 = {control.sys.pardef{:,2}};
            
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

        % Evaluate the 3D vector field 
        function [xmesh,ymesh,zmesh,dxmesh,dymesh,dzmesh] = VectorField3D(this,control,xindx,yindx,zindx,xlimit,ylimit,zlimit)
            %disp('bdPhasePortrait.VectorField3D()');

            % Determine the type of the active solver
            solvertype = control.solvermap(control.solveridx).solvertype;
            
            % Do not compute vector fields for delay differential equations 
            if strcmp(solvertype,'ddesolver')
                xmesh=[];
                ymesh=[];
                zmesh=[];
                dxmesh=[];
                dymesh=[];
                dzmesh=[];
                return
            end
            
            % compute a mesh for the domain
            xdomain = linspace(xlimit(1),xlimit(2), 7);
            ydomain = linspace(ylimit(1),ylimit(2), 7);
            zdomain = linspace(zlimit(1),zlimit(2), 7);
            [xmesh,ymesh,zmesh] = meshgrid(xdomain,ydomain,zdomain);
            dxmesh = NaN(size(xmesh));
            dymesh = dxmesh;
            dzmesh = dxmesh;
            meshlen = numel(xmesh);
            
            % evaluate vector field at trajectory end
            Y0 = control.sol.y(:,end);
            
            % curent parameter values
            P0 = {control.sys.pardef{:,2}};
            
            % evaluate vector field
            for idx=1:meshlen
                % set initial conditions to curent mesh point
                Y0(xindx) = xmesh(idx);
                Y0(yindx) = ymesh(idx);
                Y0(zindx) = zmesh(idx);
                % compute ODE (assume t=0)
                dY = control.sys.odefun(0,Y0,P0{:});
                % save results
                dxmesh(idx) = dY(xindx);
                dymesh(idx) = dY(yindx);
                dzmesh(idx) = dY(zindx);
            end
        end       
        
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
            else
                set(this.popupz,'Enable','off');
            end
            this.render(control);
        end
        
    end
    
    
    methods (Static)
        
        % The menu is static so that one menu can serve many instances of the class
        function menuobj = constructMenu(fig,control)            
            % init the appdata for the menu     
            appdata = struct('gridflag',false, 'vecfield',false, 'initflag',true);
            setappdata(fig,'bdPhasePortrait',appdata);
            
            % construct menu items
            menuobj = uimenu('Parent',fig, 'Label','Phase Portrait', 'Tag','bdPhasePortraitMenu');
            uimenu('Parent',menuobj, ...
                   'Label','Vector Field', ...
                   'Checked','off', ...
                   'Callback', @(menuitem,~) bdPhasePortrait.MenuCallback(fig,menuitem,control) );          
            uimenu('Parent',menuobj, ...
                   'Label','Initial Conditions', ...
                   'Checked','on', ...
                   'Callback', @(menuitem,~) bdPhasePortrait.MenuCallback(fig,menuitem,control) );          
            uimenu('Parent',menuobj, ...
                   'Label','Grid', ...
                   'Checked','off', ...
                   'Callback', @(menuitem,~) bdPhasePortrait.MenuCallback(fig,menuitem,control) );
        end        
        
        % Menu Item Callback
        function MenuCallback(fig,menuitem,control)
            % retrieve the appdata
            appdata = getappdata(fig,'bdPhasePortrait');
            
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
                            appdata.initflag = false;
                            menuitem.Checked='off';
                        case 'off'
                            appdata.initflag = true;
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
    
% function vec = GetDefValues(xxxdef)
% %GetDefValues returns the values stored in a pardef or vardef cell array.
% %This function is useful for extracting the values stored in a user-defined
% %vardef array as a single vector for use by the ODE solver.
% %Usage:
% %   vec = GetDefValues(xxxdef)
% %where xxxdef is a cell array of {'name',value} pairs. 
% %Example:
% %  vardef = {'a',1;
% %            'b',[2 3 4];
% %            'c',[5 8; 6 9; 7 10]};
% %  y0 = GetDefValues(vardef);
% %  ...
% %  sol = ode45(@odefun,tspan,y0,...)
% 
%     % extract the second column of xxxdef
%     vec = xxxdef(:,2);
%     
%     % convert each cell entry to a column vector
%     for indx=1:numel(vec)
%         vec{indx} = reshape(vec{indx},[],1);
%     end
%     
%     % concatenate the column vectors to a simple vector
%     vec = cell2mat(vec);
% end
