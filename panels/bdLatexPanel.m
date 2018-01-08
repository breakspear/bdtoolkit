classdef bdLatexPanel < bdPanel
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        latex       % cell array of latex strings
    end
    
    methods
        
        function this = bdLatexPanel(tabgroup,control)
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
        
        function render(this,control)
        end
        
    end
    
    
    methods (Static)
        
        % Apply default values to missing fields in sys.panels.bdLatexPanel
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
