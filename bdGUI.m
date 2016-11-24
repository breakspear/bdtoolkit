classdef bdGUI
    %bdGUI - The Brain Dynamics Toolbox graphic User Interface.
    %   Opens a dynamical system model (sys) which the user can
    %   interactively explore in a graphical user interface.
    %   
    %   Example:
    %      sys = ODEdemo1();
    %      bdGUI(sys);
    
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

    properties
        control         % handle to the bdControl object
    end
    
    properties (Access=private)
        fig             % handle to application figure
        panel1          % handle to uipanel 1
        panel2          % handle to uipanel 2
        tabgroup        % handle to tabgroup in panel1
    end
    
    methods
        % Class constructor
        function this = bdGUI(sys,pos)
            
            % use default position if none specified by caller
            if ~exist('pos','var')
                pos = [randi(100,1,1) randi(100,1,1) 900 600];
            end            
            
            % construct figure
            this.fig = figure('Units','pixels', ...
                'Position',pos, ...
                'MenuBar','none', ...
                'Toolbar','figure');
            
            % construct menu
            menuobj = uimenu('Parent',this.fig, 'Label','Toolkit');
            uimenu('Parent',menuobj, 'Label','About');
            uimenu('Parent',menuobj, 'Label','Quit');
            
            % construct the LHS panel (using an approximate position)
            this.panel1 = uipanel(this.fig,'Units','pixels','Position',[5 5 600 600],'BorderType','none');
            this.tabgroup = uitabgroup(this.panel1);
            
            % construct the RHS panel (using an approximate position)
            this.panel2 = uipanel(this.fig,'Units','pixels','Position',[5 5 300 600],'BorderType','none');

            % construct the control panel
            this.control = bdControl(this.panel2,sys);

            % resize the panels (putting them in their exact position)
            this.SizeChanged();

            % load each gui panel listed in sys.gui
            if isfield(sys,'gui')
                panels = fieldnames(sys.gui);
                for indx = 1:numel(panels)
                    classname = panels{indx};
                    if exist(classname,'class')
                        feval(classname,this.tabgroup,this.control);
                    else
                        dlg = warndlg({['''', classname, '.m'' not found'],'That panel will not be displayed'},'Missing file','modal');
                        uiwait(dlg);
                    end
                end
            end
            
            % register a callback for resizing the figure
            set(this.fig,'SizeChangedFcn', @(~,~) this.SizeChanged());

            % force a recompute
            notify(this.control,'recompute');
        end
    end
    
    methods (Access=private)
        function SizeChanged(this)
            % get the new figure size
            figw = this.fig.Position(3);
            figh = this.fig.Position(4);
            
            % dont allow small figures to cramp our panels
            figw = max(figw,300);
            figh = max(figh,300);
            
            % width of the RHS panel
            panel2w = 105;
            
            % resize the LHS panel
            w1 = figw - panel2w - 10;
            h1 = figh - 10;
            this.panel1.Position = [5 5 w1 h1];
            
            % resize the RHS panel
            w2 = panel2w;
            h2 = figh - 10;
            this.panel2.Position = [8+w1 5 w2 h2];            
        end
    end
    
end


