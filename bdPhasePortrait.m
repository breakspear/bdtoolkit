classdef bdPhasePortrait < handle
    %bdPhasePortrait - a GUI tab panel for displaying phase portraits.
    %   Displays 2D and 3D trajectories in the Brain Dynamics Toolbox GUI.

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
        tab                 % handle to uitab object
        ax                  % handle to plot axes
        popupx              % handle to X popup
        popupy              % handle to Y popup
        popupz              % handle to Z popup
        checkbox3D          % handle to 3D checkbox
        Ymap                % map Y elements to variable name and indices
        vecfield = true     % vector field flag
    end
    
    methods
        function this = bdPhasePortrait(tabgroup,title,sys,control)
            % Construct a new tab panel in the parent tabgroup.
            % Usage:
            %    bdPhasePortrait(tabgroup,title,sys,control)
            % where 
            %    tabgroup is a handle to the parent uitabgroup object.
            %    title is a string defining the name given to the new tab.
            %    sys is the system struct defining the model.
            %    control is a handle to the GUI control panel.
            
            % map all variables to their names and group indexes
            this.Ymap = enumerate(sys.vardef);
            nvardef = size(sys.vardef,1);

            % construct the uitab
            this.tab = uitab(tabgroup,'title',title, 'Units','pixels');
            
            % get tab geometry
            parentx = this.tab.Position(1);
            parenty = this.tab.Position(2);
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
                'String', {this.Ymap.name}, ...
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
                popupval = numel(sys.vardef{1,2}) + 1;
            end
            this.popupy = uicontrol('Style','popup', ...
                'String', {this.Ymap.name}, ...
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
                popupval = numel(sys.vardef{1,2}) + numel(sys.vardef{2,2}) + 1;
            end
            this.popupz = uicontrol('Style','popup', ...
                'String', {this.Ymap.name}, ...
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

            % register a callback for resizing the panel
            set(this.tab,'SizeChangedFcn', @(~,~) SizeChanged(this,this.tab));

            % listen to the control panel for redraw events
            addlistener(control,'redraw',@(~,~) this.render(control));    
        end
        
        function render(this,control)
            %disp('bdPhasePortrait.render()')
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
                plot3(this.ax, x(1),y(1),z(1), 'color','k', 'marker','pentagram', 'markerfacecolor','y', 'markersize',12);
                hold(this.ax, 'off');                
                xlabel(this.ax,xstr, 'FontSize',16);
                ylabel(this.ax,ystr, 'FontSize',16);
                zlabel(this.ax,zstr, 'FontSize',16);

                if this.vecfield
                    % compute vector field
                    xlimit = this.ax.XLim;
                    ylimit = this.ax.YLim;
                    zlimit = this.ax.ZLim;
                    [xmesh,ymesh,zmesh,dxmesh,dymesh,dzmesh] = this.VectorField3D(control,xindx,yindx,zindx,xlimit,ylimit,zlimit);

                    % plot vector field in axv
                    hold(this.ax, 'on');                                
                    quiver3(xmesh,ymesh,zmesh,dxmesh,dymesh,dzmesh,'parent',this.ax, 'color',[0.5 0.5 0.5]);
                    % dont let the quiver plot change the original axes limits
                    this.ax.XLim = xlimit;
                    this.ax.YLim = ylimit;
                    this.ax.ZLim = zlimit;
                    hold(this.ax, 'off');                
                end
            else
                % plot current trajectory in 2D
                x = control.sol.y(xindx,tindx);
                y = control.sol.y(yindx,tindx);
                plot(this.ax, x,y, 'color','k','Linewidth',1);
                hold(this.ax, 'on');
                plot(this.ax, x(1),y(1), 'color','k', 'marker','pentagram', 'markerfacecolor','y', 'markersize',12);
                hold(this.ax, 'off');                
                xlabel(this.ax,xstr, 'FontSize',16);
                ylabel(this.ax,ystr, 'FontSize',16);
                
                if this.vecfield
                    % compute vector field
                    xlimit = this.ax.XLim;
                    ylimit = this.ax.YLim;
                    [xmesh,ymesh,dxmesh,dymesh] = this.VectorField2D(control,xindx,yindx,xlimit,ylimit);

                    % plot vector field in axv
                    hold(this.ax, 'on');                                
                    quiver(xmesh,ymesh,dxmesh,dymesh, 'parent',this.ax, 'color',[0.5 0.5 0.5]);
                    % dont let the quiver plot change the original axes limits
                    this.ax.XLim = xlimit;
                    this.ax.YLim = ylimit;
                    hold(this.ax, 'off');                
                end
            end
        end
        
    end
    
    methods (Access=private)   
        
        % Evaluate the 2D vector field 
        function [xmesh,ymesh,dxmesh,dymesh] = VectorField2D(this,control,xindx,yindx,xlimit,ylimit)
            %disp('bdPhasePortrait.VectorField2D()');
    
            % Do not compute vector fields for delay differential equations 
            if strcmp(control.solver,'dde23')
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
            P0 = {control.pardef{:,2}};
            
            % evaluate vector field
            for idx=1:meshlen
                % set initial conditions to curent mesh point
                Y0(xindx) = xmesh(idx);
                Y0(yindx) = ymesh(idx);
                % evaluate ODE
                dY = control.odefun(0,Y0,P0{:});
                % save results
                dxmesh(idx) = dY(xindx);
                dymesh(idx) = dY(yindx);
            end
        end

        % Evaluate the 3D vector field 
        function [xmesh,ymesh,zmesh,dxmesh,dymesh,dzmesh] = VectorField3D(this,control,xindx,yindx,zindx,xlimit,ylimit,zlimit)
            %disp('bdPhasePortrait.VectorField3D()');
            
            % Do not compute vector fields for delay differential equations 
            if strcmp(control.solver,'dde23')
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
            P0 = {control.pardef{:,2}};
            
            % evaluate vector field
            for idx=1:meshlen
                % set initial conditions to curent mesh point
                Y0(xindx) = xmesh(idx);
                Y0(yindx) = ymesh(idx);
                Y0(zindx) = zmesh(idx);
                % compute ODE (assume t=0)
                dY = control.odefun(0,Y0,P0{:});
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
    
end


% Returns a mapping for each entry in vardef where
% map.name = the string name of the variable
% map.def = the row index of vardef{}
% map.grp = the Y indices of all variables with this name.
function map = enumerate(xxxdef)
    map = [];
    ndef = size(xxxdef,1);
    pos = 0;
    for def=1:ndef
        len = numel(xxxdef{def,2});
        for c=1:len
            if len==1
                name = xxxdef{def,1};        
            else
                name = num2str(c,[xxxdef{def,1},'_{%d}']);        
            end                
            map(end+1).name = name;
            map(end).def = def;
            map(end).grp = [1:len]+pos;
        end
        pos = pos + len;
    end
end


function vec = GetDefValues(xxxdef)
%GetDefValues returns the values stored in a pardef or vardef cell array.
%This function is useful for extracting the values stored in a user-defined
%vardef array as a single vector for use by the ODE solver.
%Usage:
%   vec = GetDefValues(xxxdef)
%where xxxdef is a cell array of {'name',value} pairs. 
%Example:
%  vardef = {'a',1;
%            'b',[2 3 4];
%            'c',[5 8; 6 9; 7 10]};
%  y0 = GetDefValues(vardef);
%  ...
%  sol = ode45(@odefun,tspan,y0,...)

    % extract the second column of xxxdef
    vec = xxxdef(:,2);
    
    % convert each cell entry to a column vector
    for indx=1:numel(vec)
        vec{indx} = reshape(vec{indx},[],1);
    end
    
    % concatenate the column vectors to a simple vector
    vec = cell2mat(vec);
end
