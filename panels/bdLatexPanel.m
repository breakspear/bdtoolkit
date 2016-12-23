classdef bdLatexPanel < handle
    %bdLatexPanel - Brain Dynamics GUI panel for Latex equations.
    %   Displays mathematical equations in the Brain Dynamics Toolbox GUI
    %   using the MATLAB built-in latex interpreter.
    %
    %SYS OPTIONS
    %   sys.gui.bdLatexPanel.title      String name of the panel (optional)
    %   sys.gui.bdLatexPanel.latex      Cell array of latex strings
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

    methods        
        function this = bdLatexPanel(tabgroup,control)
            % Construct a new tab panel in the parent tabgroup.
            % Usage:
            %    bdLatexPanel(tabgroup,control)
            % where 
            %    tabgroup is a handle to the parent uitabgroup object.
            %    control is a handle to the GUI control object.


            % default sys.gui settings
            title = 'Equations';
            latex = {'\textbf{bdLatexPanel}'; 'Undefined \textsl{sys.gui.bdLatexPanel.latex} field'};

            % sys.gui.bdLatexPanel.title
            if isfield(control.sys.gui,'bdLatexPanel') && isfield(control.sys.gui.bdLatexPanel,'title')
                title = control.sys.gui.bdLatexPanel.title;
            end
            
            % sys.gui.bdLatexPanel.latex
            if isfield(control.sys.gui,'bdLatexPanel') && isfield(control.sys.gui.bdLatexPanel,'latex')
                latex = control.sys.gui.bdLatexPanel.latex;
            end
            
            % construct the uitab
            tab = uitab(tabgroup, 'title',title, 'Units','points');

            % get tab geometry (in points)
            %parentx = tab.Position(1);
            %parenty = tab.Position(2);
            %parentw = tab.Position(3);
            parenth = tab.Position(4);

            % construct the axes
            ax = axes('Parent',tab, ...
                'Units','normal', ...
                'Position',[0 0 1 1], ...
                'XTick', [], ...
                'YTick', [], ...
                'XColor', [1 1 1], ...
                'YColor', [1 1 1]);
            
            % render the latex text as one large action
            %text(0.01,0.98,latex, 'interpreter','latex', 'Parent',ax, 'FontSize',16, 'VerticalAlignment','top');
            
            % Render the latex strings one line at a time. This is better
            % than rendering the latex strings in a single text box
            % because (i) the latex interpreter has limited memory for
            % monumental strings, and (ii) it is difficult for the user
            % to locate latex syntax errors in monumental strings.
            yoffset = 4;   % points
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
                    uiwait( warndlg({'latex syntax error in sys.gui.bdLatexPanel.latex',latex{l}},'bdLatexPanel','modal') );
                    yoffset = yoffset + 24;                   % skip one line (approx)
                else
                    yoffset = yoffset + 1.1*obj.Extent(4);    % skip one line (exactly)
                end       
                
            end
            
            % register a callback for resizing the panel
            set(tab,'SizeChangedFcn', @(~,~) SizeChanged(this,tab));
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
end

