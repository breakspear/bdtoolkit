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
        fontsize    % Font size
    end
    
    properties (Access=private)
        ax              % Handle to the axes
        scrollpanel     % Handle to the scrollpanel
    end
    
    methods
        function this = bdLatexPanel(tabgroup,control)
            % Construct a new LaTeX panel in the given tabgroup
            
            % initialise the base class (specifically this.tab and this.menu)
            this@bdPanel(tabgroup);
            
            % apply default settings to sys.panels.bdLatexPanel
            control.sys.panels.bdLatexPanel = bdLatexPanel.syscheck(control.sys);

            % get the initial fontsize
            this.fontsize = control.sys.panels.bdLatexPanel.fontsize;
            
            % customise the menu
            this.menu.Label = control.sys.panels.bdLatexPanel.title;
            uimenu('Parent',this.menu, 'Label','Larger Font', 'Callback',@(~,~) this.FontCallback(1.25));
            uimenu('Parent',this.menu, 'Label','Smaller Font', 'Callback',@(~,~) this.FontCallback(0.8));
            uimenu('Parent',this.menu, 'Label','Close', 'Callback',@(~,~) close(this)); 

            % customise the tab
            this.tab.Title = control.sys.panels.bdLatexPanel.title;
            
            % get the latex string from the sys structure
            this.latex = control.sys.panels.bdLatexPanel.latex;

            % construct scrolling uipanel
            panelh = numel(this.latex)*this.fontsize;      % only approximate (exact height depends on font:pixel ratio)
            this.scrollpanel = bdScroll(this.tab,900,panelh,'BackgroundColor',[1 1 1]); 

            % get panel height
            parenth = this.scrollpanel.panel.Position(4);

            % construct the axes
            this.ax = axes('Parent',this.scrollpanel.panel, ...
                'Units','normal', ...
                'Position',[0 0 1 1], ...
                'XTick', [], ...
                'YTick', [], ...
                'XColor', [1 1 1], ...
                'YColor', [1 1 1]);

            % render the equations
            this.redraw();
        end
        
    end
    
    methods (Access=private)

        function redraw(this)
            % celar the axes
            cla(this.ax);

            % init yoffset near the bottom of the panel
            yoffset = this.fontsize;        % pixels
            xmax = 100;                     % pixels            

            % Render the latex strings one line at a time (in reverse order).
            % Rendering each string separately is better than rendering
            % them all at once in a single text box because (i) the latex
            % interpreter has limited memory for monumental strings, and
            % (ii) it is difficult for the user to locate latex syntax
            % errors in monumental strings.
            for l = numel(this.latex):-1:1
                
                % special case: small skip for empty strings
                if numel(this.latex{l})==0
                    yoffset = yoffset + 0.25*this.fontsize;      % small skip
                    continue;
                end 
            
                % render the text
                obj = text(8,yoffset, this.latex{l}, ...
                    'interpreter','latex', ...
                    'Parent',this.ax, ...
                    'Units','pixels', ...
                    'FontUnits','pixels', ...
                    'FontSize',this.fontsize, ...
                    'VerticalAlignment','bottom'); 
                
                % error handling 
                if obj.Extent(4)==0
                    % latex syntax error occured. Colour the offending text red.
                    obj.Color = [1 0 0];                    
                    yoffset = yoffset + this.fontsize;         % skip one line (approx)
                else
                    yoffset = yoffset + 1.1*obj.Extent(4);     % skip one line (exactly)
                    xmax = max(xmax,obj.Extent(1)+obj.Extent(3));
                end
                
            end
            
            % skip half a line at the top
            yoffset = yoffset + 0.5*this.fontsize;
            
            % adjust the size of the scroll panel to fit the text
            this.scrollpanel.panel.Position(3) = xmax + 10;
            this.scrollpanel.panel.Position(4) = yoffset;
        end
        
        function FontCallback(this,scale)
            this.fontsize = scale * this.fontsize;
            this.redraw();
        end
    end
    
    methods (Static)
        
        function syspanel = syscheck(sys)
            % Apply default values to missing fields in sys.panels.bdLatexPanel

            % Default panel settings
            syspanel.title = bdLatexPanel.title;
            syspanel.latex = {'\textbf{No latex equations to display}',
                              '', 
                              'The \texttt{latex} strings need to be defined for this model.',
                              ''
                              '\texttt{sys.panels.bdLatexPanel.latex} = \{`latex string 1'', `latex string 2'', ... \};',
                              ''
                              'See the section on \textsl{LaTeX Equations} in the Handbook for the Brain Dynamics Toolbox.'};
            syspanel.fontsize = 16;              
            
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
            
            % sys.panels.bdLatexPanel.fontsize
            if isfield(sys.panels.bdLatexPanel,'fontsize')
                syspanel.fontsize = sys.panels.bdLatexPanel.fontsize;
            end            
        end   
    end
    
end
