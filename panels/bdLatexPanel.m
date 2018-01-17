classdef bdLatexPanel < bdPanel
    %bdLatexPanel Display panel for rendering LaTeX equations in bdGUI.
    %It renders the LaTeX strings found in the sys.panels.bdLatexPanel.latex
    %field of the system structure.
    %
    %AUTHORS
    %Stewart Heitmann (2016a,2017a-c,2018a)   
    
    % Copyright (C) 2016-2018 QIMR Berghofer Medical Research Institute
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
   
    properties (Constant)
        title = 'Equations';
    end    

    properties
        latex       % A copy of the latex strings being rendered.
    end
    
    methods        
        function this = bdLatexPanel(tabgroup,control)
            % Construct a new LaTeX panel in the given tabgroup
            
            % initialise the base class (specifically this.tab and this.menu)
            this@bdPanel(tabgroup);
            
            % apply default settings to sys.panels.bdLatexPanel
            control.sys.panels.bdLatexPanel = bdLatexPanel.syscheck(control.sys);

            % customise the menu
            this.menu.Label = control.sys.panels.bdLatexPanel.title;
            uimenu('Parent',this.menu, 'Label','Close', 'Callback',@(~,~) close(this)); 

            % customise the tab
            this.tab.Title = control.sys.panels.bdLatexPanel.title;
            
            % get the latex string from the sys structure
            this.latex = control.sys.panels.bdLatexPanel.latex;

            % construct scrolling uipanel
            panelh = numel(this.latex)*32 + 32;      % only approximate (exact height depends on font:pixel ratio)
            scrollpanel = bdScroll(this.tab,900,panelh,'BackgroundColor',[1 1 1]); 

            % get panel height
            parenth = scrollpanel.panel.Position(4);

            % construct the axes
            ax = axes('Parent',scrollpanel.panel, ...
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
            yoffset = 8;   % points
            for l = 1:numel(this.latex)
                
                % special case: small skip for empty strings
                if numel(this.latex{l})==0
                    yoffset = yoffset + 8;      % small skip
                    continue;
                end 
                
                % render the text
                obj = text(8,parenth-yoffset, this.latex{l}, ...
                    'interpreter','latex', ...
                    'Parent',ax, ...
                    'Units','pixels', ...
                    'FontUnits','pixels', ...
                    'FontSize',16, ...
                    'VerticalAlignment','top', ...
                    'UserData', yoffset); 
               
                % error handling 
                if obj.Extent(4)==0
                    % latex syntax error occured. Colour the offending text red.
                    obj.Color = [1 0 0];                    
                    % issue a syntax error
                    uiwait( warndlg('latex syntax error','bdLatexPanel','modal') );                   
                    yoffset = yoffset + 24;                   % skip one line (approx)
                else
                    yoffset = yoffset + 1.1*obj.Extent(4);    % skip one line (exactly)
                end       
                
            end
            
        end
        
    end
    
    
    methods (Static)
        
        function syspanel = syscheck(sys)
            % Apply default values to missing fields in sys.panels.bdLatexPanel

            % Default panel settings
            syspanel.title = bdLatexPanel.title;
            syspanel.latex = {'\textbf{No latex equations to display}', ...
                              '\textsl{sys.panels.bdLatexPanel.latex} = \{`latex string 1'', `latex string 2'', ... \}', ...
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
