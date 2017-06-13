classdef bdTrapPanel < handle
    %bdTrapPanel - Brain Dynamics Toolbox panel for debugging other panels.
    %   This class contsructs a dummy axis which it uses to detect (trap)
    %   erroneous drawing commands from other panels. Its purpose is to
    %   detect the most common error in GUI panels - that of drawing to
    %   the current graphics axes rather than a speccific axes handle.
    %   Load this panel to test whether another panel is misbehaving.
    %
    %SYS OPTIONS
    %   sys.panels.bdTrapPanel.title = 'Trap'
    %
    %AUTHORS
    %  Stewart Heitmann (2017b)

    % Copyright (C) 2017 QIMR Berghofer Medical Research Institute
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
        tab             % handle to uitab object
        ax              % handle to the trap axis
        listener        % handle to listener
    end

    methods        
        function this = bdTrapPanel(tabgroup,control)
            % apply default settings to sys.panels.bdTrapPanel
            control.sys.panels.bdTrapPanel = bdTrapPanel.syscheck(control.sys);

            % construct the uitab
            this.tab = uitab(tabgroup, ...
                'title',control.sys.panels.bdTrapPanel.title, ...
                'Tag','bdTrapPanelTab', ...
                'Units','points', ...
                'TooltipString','Right click for menu');

            % construct the trap axes
            this.ax = axes('Parent',this.tab, ...
                'Units','normal', 'Position',[0.1 0.5 0.85 0.45]);
                
            % construct the message box
            msg = ['This panel detects mis-behaving GUI panels by ' ...
                   'trapping erroneous drawing commands to the current ' ...
                   'axis. It is the most common programming error in ' ...
                   'user-defined panels. The axis above should always appear blank. ' ...
                   'If not then there is a bug in one of the panels that ' ...
                   'are currently loaded. Detection is not guaranteed.'];
            uicontrol('Style','Text', ...
                'String',msg, ...
                'Parent',this.tab, ...
                'Units','normal', ...
                'Position',[0.02 0 0.96 0.4], ...
                'FontSize', 14, ...
                'HorizontalAlignment', 'left' );
            
            % construct the tab context menu
            this.tab.UIContextMenu = uicontextmenu;
            uimenu(this.tab.UIContextMenu,'Label','Close', 'Callback',@(~,~) this.delete());

            % register a callback for resizing the panel
            set(this.tab,'SizeChangedFcn', @(~,~) SizeChanged(this,this.tab));
            
            % listen to the control panel for redraw events
            this.listener = addlistener(control,'redraw',@(~,~) this.render(control));
            
            % Set the current axis to this.ax. This is the honey in the trap.
            axes(this.ax);
        end
        
        % Destructor
        function delete(this)
            delete(this.listener);
            delete(this.tab);          
        end

    end
    
    methods (Access = private)
    
        % Callback for panel resizing. This function relies on each
        % widget having its desired yoffset stored in its UserData field.
        function SizeChanged(~,panel)
            % get new parent geometry
            panelh = panel.Position(4);
            
            % find all widgets in the control panel
            objs = findobj(panel,'Tag','bdTrapPanelWidget');
            
            % for each widget, adjust its y position according to its preferred position
            for indx = 1:numel(objs)
                obj = objs(indx);                       % get the widget handle
                yoffset = obj.UserData;                 % retrieve the preferred y position from UserData.
                obj.Position(2) = panelh - yoffset;     % apply the preferred y position
            end            
        end
       
       function render(this,~)
            % debugging 
            %disp('bdTrapPanel.render()') 
            
            % Error messages are accumulate in this cell array.
            errmsgs = {};
            
            % Detect illegal drawing activity
            if ~isempty(this.ax.Children)
                errmsgs{end+1} = '* Plotting has been detected.';
            end            
            if ~isequal(this.ax.ALim,[0 1])
                errmsgs{end+1} = '* The ALIM property has been altered.';
            end            
            if ~strcmp(this.ax.Box,'off')
                errmsgs{end+1} = '* The BOX property has been altered';
            end            
            if ~isequal(this.ax.CLim,[0 1])
                errmsgs{end+1} = '* The CLIM property has been altered.';
            end            
            if ~strcmp(this.ax.Clipping,'on')
                errmsgs{end+1} = '* The CLIPPING property has been altered';
            end            
            if ~isequal(this.ax.Color,[1 1 1])
                errmsgs{end+1} = '* The COLOR property has been altered.';
            end            
            if ~strcmp(this.ax.FontAngle,'normal')
                errmsgs{end+1} = '* The FONTANGLE property has been altered';
            end            
            if ~strcmp(this.ax.FontName,'Helvetica')
                errmsgs{end+1} = '* The FONTNAME property has been altered';
            end            
            if this.ax.FontSize ~= 10
                errmsgs{end+1} = '* The FONTSIZE property has been altered';
            end            
            if ~strcmp(this.ax.FontUnits,'points')
                errmsgs{end+1} = '* The FONTUNITS property has been altered';
            end            
            if ~strcmp(this.ax.FontWeight,'normal')
                errmsgs{end+1} = '* The FONTWEIGHT property has been altered';
            end            
            if ~strcmp(this.ax.GridLineStyle,'-')
                errmsgs{end+1} = '* The GRIDLINESTYLE property has been altered';
            end            
            if ~strcmp(this.ax.Projection,'orthographic')
                errmsgs{end+1} = '* The ORTHOGRAPHIC property has been altered';
            end            
            if ~isempty(this.ax.Title.String)
                errmsgs{end+1} = '* The TITLE property has been altered';
            end
            if ~isempty(this.ax.UserData)
                errmsgs{end+1} = '* The USERDATA property has been altered.';
            end            
            if ~isequal(this.ax.View,[0 90])
                errmsgs{end+1} = '* The VIEW property has been altered';
            end
            if ~strcmp(this.ax.XGrid,'off')
                errmsgs{end+1} = '* The XGRID property has been altered';
            end            
            if ~isequal(this.ax.XLim,[0 1])
                errmsgs{end+1} = '* The XLIM property has been altered.';
            end            
            if ~strcmp(this.ax.XScale,'linear')
                errmsgs{end+1} = '* The XSCALE property has been altered';
            end            
            if ~strcmp(this.ax.YGrid,'off')
                errmsgs{end+1} = '* The YGRID property has been altered';
            end            
            if ~isequal(this.ax.YLim,[0 1])
                errmsgs{end+1} = '* The YLIM property has been altered';
            end            
            if ~strcmp(this.ax.YScale,'linear')
                errmsgs{end+1} = '* The YSCALE property has been altered';
            end               
            if ~strcmp(this.ax.ZGrid,'off')
                errmsgs{end+1} = '* The ZGRID property has been altered';
            end            
            if ~isequal(this.ax.ZLim,[0 1])
                errmsgs{end+1} = '* The ZLIM property has been altered.';
            end            
            if ~strcmp(this.ax.ZScale,'linear')
                errmsgs{end+1} = '* The ZSCALE property has been altered';
            end            
            
            if ~isempty(errmsgs)
                msg = ['A GUI panel has illegally drawn into the Trap axis.', ...
                       errmsgs, ...
                       'This indicates a drawing error by one of the panels.', ...
                       'Panels should never draw into the current axis.'];
                for indx = 1:numel(msg)
                    disp(msg{indx});
                end
                waitfor(warndlg(msg,'Trap Panel','modal'));
            end
            
            % Reset the axis properties to defaults
            cla(this.ax);
            reset(this.ax);

            % Make this.ax the current axis. This is the honey in the trap.
            axes(this.ax);     
       end
       
    end
    
    methods (Static)
        
        % Check the sys.panels struct
        function syspanel = syscheck(sys)
            % Default panel settings
            syspanel.title = 'Trap';
            
            % Nothing more to do if sys.panels.bdTrapPanel is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdTrapPanel')
                return;
            end
            
            % sys.panels.bdTrapPanel.title
            if isfield(sys.panels.bdTrapPanel,'title')
                syspanel.title = sys.panels.bdTrapPanel.title;
            end
        end   
        
    end
end

