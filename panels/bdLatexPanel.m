classdef bdLatexPanel < handle
    %bdLatexPanel - Brain Dynamics Toolbox panel for Latex equations.
    %   This class displays latex equations in the graphical user interface
    %   of the Brain Dynamics Toolbox (bdGUI) using the MATLAB built-in
    %   latex interpreter. Users never call this class directly. They
    %   instead instruct the bdGUI application to load the panel by
    %   specifying options in their model's sys struct. 
    %
    %SYS OPTIONS
    %   sys.panels.bdLatexPanel.title = 'Equations'
    %   sys.panels.bdLatexPanel.latex = {'latex string','latex string',...}
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
        tab             % handle to uitab object
    end

    methods        
        function this = bdLatexPanel(tabgroup,control)
            % Construct a new tab panel in the parent tabgroup.
            % Usage:
            %    bdLatexPanel(tabgroup,control)
            % where 
            %    tabgroup is a handle to the parent uitabgroup object.
            %    control is a handle to the GUI control object.

            % apply default settings to sys.panels.bdLatexPanel
            control.sys.panels.bdLatexPanel = bdLatexPanel.syscheck(control.sys);

            % construct the uitab
            this.tab = uitab(tabgroup, 'title',control.sys.panels.bdLatexPanel.title, 'Tag','bdLatexPanelTab', 'Units','points');

            % get tab geometry (in points)
            %parentx = this.tab.Position(1);
            %parenty = this.tab.Position(2);
            %parentw = this.tab.Position(3);
            parenth = this.tab.Position(4);

            % construct the axes
            ax = axes('Parent',this.tab, ...
                'Units','normal', ...
                'Position',[0 0 1 1], ...
                'XTick', [], ...
                'YTick', [], ...
                'XColor', [1 1 1], ...
                'YColor', [1 1 1]);
            
            % Render the latex strings one line at a time. This is better
            % than rendering the latex strings in a single text box
            % because (i) the latex interpreter has limited memory for
            % monumental strings, and (ii) it is difficult for the user
            % to locate latex syntax errors in monumental strings.
            yoffset = 4;   % points
            latex = control.sys.panels.bdLatexPanel.latex;
            for l = 1:numel(latex)
                
                % special case: small skip for empty strings
                if numel(latex{l})==0
                    yoffset = yoffset + 8;      % small skip
                    continue;
                end 
                
                % render the text
                obj = text(4,parenth-yoffset, latex{l}, ...
                    'interpreter','latex', ...
                    'Parent',ax, ...
                    'Units','points', ...
                    'FontSize',16, ...
                    'VerticalAlignment','top', ...
                    'Tag', 'bdLatexPanelWidget', ...
                    'UserData', yoffset); 
               
                % error handling 
                if obj.Extent(4)==0
                    % latex syntax error occured. Colour the offending text red.
                    obj.Color = [1 0 0];                    
                    % issue a syntax error
                    uiwait( warndlg({'latex syntax error in sys.panels.bdLatexPanel.latex',latex{l}},'bdLatexPanel','modal') );
                    yoffset = yoffset + 24;                   % skip one line (approx)
                else
                    yoffset = yoffset + 1.1*obj.Extent(4);    % skip one line (exactly)
                end       
                
            end
            
            % construct the tab context menu
            this.tab.UIContextMenu = uicontextmenu;
            uimenu(this.tab.UIContextMenu,'Label','Close Panel', 'Callback',@(~,~) this.delete());

            % register a callback for resizing the panel
            set(this.tab,'SizeChangedFcn', @(~,~) SizeChanged(this,this.tab));
        end
        
        % Destructor
        function delete(this)
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
            objs = findobj(panel,'Tag','bdLatexPanelWidget');
            
            % for each widget, adjust its y position according to its preferred position
            for indx = 1:numel(objs)
                obj = objs(indx);                       % get the widget handle
                yoffset = obj.UserData;                 % retrieve the preferred y position from UserData.
                obj.Position(2) = panelh - yoffset;     % apply the preferred y position
            end            
        end
    
    end
    
    methods (Static)
        
        % Check the sys.panels struct
        function syspanel = syscheck(sys)
            % Default panel settings
            syspanel.title = 'Equations';
            syspanel.latex = {'\textbf{No latex equations to display}',
                              '\textsl{sys.panels.bdLatexPanel.latex} = \{`latex string 1'', `latex string 2'', ... \}',
                              'is undefined for this model'};
            
            % Nothing more to do if sys.panels.bdLatexPanel is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdLatexPanel')
                return;
            end
            
            % sys.panels.bdLatexPanel.title
            if isfield(sys.panels.bdLatexPanel,'title')
                syspanel.title = sys.panels.bdLatexPanel.title;
            end
            
            % sys.panels.bdLatexPanel.latex
            if isfield(sys.panels.bdLatexPanel,'latex')
                syspanel.latex = sys.panels.bdLatexPanel.latex;
            end            
        end   
        
    end
end

