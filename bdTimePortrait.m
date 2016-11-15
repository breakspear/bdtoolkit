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
        tab     % handle to uitab object
        ax1     % handle to plot 1 axes
        ax2     % handle to plot 2 axes
        popup1  % handle to popup selector 1
        popup2  % handle to popup selector 2
        Ymap
    end
    
    methods
        function this = bdTimePortrait(tabgroup,title,sys,control)
            % Construct a new tab panel in the parent tabgroup.
            % Usage:
            %    bdTimePortrait(tabgroup,title,sys,control)
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
            
            % plot 1 var selector
            posx = 10;
            posy = 10;
            posw = 100;
            posh = 20;
            popupval = 1;       
            this.popup1 = uicontrol('Style','popup', ...
                'String', {this.Ymap.name}, ...
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
                popupval = numel(sys.vardef{1,2}) + 1;
            end            
            this.popup2 = uicontrol('Style','popup', ...
                'String', {this.Ymap.name}, ...
                'Value', popupval, ...
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
            %disp('bdTimePortrait.render()')
            
            % render the upper and lower axes 
            renderax(this.ax1, this.popup1.Value);
            renderax(this.ax2, this.popup2.Value);            
            xlabel(this.ax2,'time', 'FontSize',14);

            % Yindx is the global index of the selected variable
            function renderax(ax,Yindx)
                % get detail of the selected variable
                name    = this.Ymap(Yindx).name;   % name string
                YYindx  = this.Ymap(Yindx).grp;    % index of group in Y
                yyindx  = Yindx - YYindx(1) + 1;   % relative index of selected variable in group index
                    
                % find non-negative time entries
                tindx = find(control.sol.x>=0);
            
                % the stuff we plot 
                t = control.sol.x(tindx);
                y = control.sol.y(YYindx,tindx);
                
                plot(ax, t, y, 'color',[0.9 0.9 0.9]);
                hold(ax,'on');
                plot(ax, t, y(yyindx,:), 'color','k', 'Linewidth',1.5);
                hold(ax,'off');      
                ylabel(ax,name, 'FontSize',16,'FontWeight','normal');
                %xlabel(ax,'time');
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

