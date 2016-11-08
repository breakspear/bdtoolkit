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
        tab         % handle to uitab object
        ax          % handle to plot axes
        popupx      % handle to X popup
        popupy      % handle to Y popup
        popupz      % handle to Z popup
        checkbox3D  % handle to 3D checkbox
        Ymap        % map Y elements to variable name and indices
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

            % plot axes
            posx = 50;
            posy = 80;
            posw = parentw-65;
            posh = parenth-90;
            this.ax = axes('Parent',this.tab, 'Units','pixels', 'Position',[posx posy posw posh]);           
            
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
            disp('bdPhasePortrait.render()')
            xindx = this.popupx.Value;
            yindx = this.popupy.Value;
            zindx = this.popupz.Value;
            xstr = this.popupx.String{xindx};
            ystr = this.popupy.String{yindx};
            zstr = this.popupz.String{zindx};
            tindx = find(control.sol.x>=0);
            if this.checkbox3D.Value
                x = control.sol.y(xindx,tindx);
                y = control.sol.y(yindx,tindx);
                z = control.sol.y(zindx,tindx);
                plot3(this.ax, x,y,z, 'color','k','Linewidth',1);
                hold(this.ax, 'on');
                plot3(this.ax, x(1),y(1),z(1), 'color','k', 'marker','pentagram', 'markerfacecolor','y', 'markersize',10);
                hold(this.ax, 'off');                
                xlabel(this.ax,xstr, 'FontSize',16);
                ylabel(this.ax,ystr, 'FontSize',16);
                zlabel(this.ax,zstr, 'FontSize',16);
            else
                x = control.sol.y(xindx,tindx);
                y = control.sol.y(yindx,tindx);
                plot(this.ax, x,y, 'color','k','Linewidth',1);
                hold(this.ax, 'on');
                plot(this.ax, x(1),y(1), 'color','k', 'marker','pentagram', 'markerfacecolor','y', 'markersize',10);
                hold(this.ax, 'off');                
                xlabel(this.ax,xstr, 'FontSize',16);
                ylabel(this.ax,ystr, 'FontSize',16);
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


