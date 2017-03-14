classdef bdSolverPanel < handle
    %bdSolverPanel Brain Dynamics GUI panel for solver options.
    %   This class implements phase portraits for the graphical user interface
    %   of the Brain Dynamics Toolbox (bdGUI). Users never call this class
    %   directly. They instead instruct the bdGUI application to load the
    %   panel by specifying options in their model's sys struct. 
    %   
    %SYS OPTIONS
    %   sys.panels.bdSolverPanel.title = 'Solver'
    %   sys.panels.bdSolverPanel.grid = false
    %
    %AUTHORS
    %  Stewart Heitmann (2016a, 2017a)

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
        fig             % handle to parent figure
        tab             % handle to uitab object
        ax1             % handle to axis 1 (upper)
        ax2             % handle to axis 2 (lower)
        plt1            % handle to plot line (axis 1)
        plt2            % handle to plot line (axis 2)        
        listener1       % handle to listener
        listener2       % handle to listener
        gridflag        % grid menu flag
    end
 
    methods        
        function this = bdSolverPanel(tabgroup,control)
            
            % apply default settings to sys.panels.bdSolverPanel
            control.sys.panels.bdSolverPanel = bdSolverPanel.syscheck(control.sys);

            % get handle to parent figure
            this.fig = ancestor(tabgroup,'figure');

            % construct the uitab
            this.tab = uitab(tabgroup,'title',control.sys.panels.bdSolverPanel.title, 'Tag','bsSolverPanelTab', 'Units','pixels');
            
            % get tab geometry
            parentw = this.tab.Position(3);
            parenth = this.tab.Position(4);

            % compute axes geometry
            axesh = (parenth-200)/2;
            axesw = parentw-100;
            
            % construct the dydt axes
            this.ax1 = axes('Parent',this.tab, ...
                'Units','pixels', ...
                'Position', [60 150+axesh  axesw axesh]);
            this.plt1 = stairs(0,0, 'parent',this.ax1, 'color','k', 'Linewidth',1);
            set(this.ax1,'TickDir','out');
            %xlabel('time (t)','FontSize',14);
            ylabel('||dY||','FontSize',14);

            % construct the step-size axes
            this.ax2 = axes('Parent',this.tab, ...
                'Units','pixels', ...
                'Position', [60 130 axesw axesh]);
            this.plt2 = stairs(0,0, 'parent',this.ax2, 'color','k', 'Linewidth',1);
            set(this.ax2,'TickDir','out');
            xlabel('time (t)','FontSize',14);
            ylabel('step size (dt)','FontSize',14);
            
            % construct panel for odeoptions
            this.odePanel(this.tab,control);
            
            % construct the tab context menu
            this.contextMenu(control);

            % register a callback for resizing the panel
            set(this.tab,'SizeChangedFcn', @(~,~) this.SizeChanged(this.tab));

            % listen to the control panel for redraw events
            this.listener1 = addlistener(control,'redraw',@(~,~) this.render(control));    
        end
        
        % Destructor
        function delete(this)
            delete(this.listener1);
            delete(this.listener2);
            delete(this.tab);          
        end       
        
    end
    
    methods (Access=private)
        
        function panel = odePanel(this,parent,control)
            % edit box geometry
            boxw = 50;
            boxh = 20;
            boxx = 60;

            % get parent geometry
            parentw = parent.Position(3);
            
            % construct panel
            panel = uipanel('Parent',parent, ...
                'Units','pixels', ...
                'Position',[0 0 parentw 80], ...
                'bordertype','none');

            % Error Control
            uicontrol('Style','text', ...
                'String','Error Control', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontWeight','bold', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+2*boxh 2*boxw+5 boxh]);

            % construct edit box for AbsTol
            fieldname = 'AbsTol';
            AbsTol = uicontrol('Style','edit', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Absolute error tolerance', ...
                'Parent', panel, ...
                'Callback', @(hObj,~) editboxCallback(hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 5;
            
            % construct edit box for RelTol
            fieldname = 'RelTol';
            RelTol = uicontrol('Style','edit', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Relative error tolerance', ...
                'Parent', panel, ...
                'Callback', @(hObj,~) editboxCallback(hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 20;

            % Step Size
            uicontrol('Style','text', ...
                'String','Step Size', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontWeight','bold', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+2*boxh 2*boxw+5 boxh]);

            % construct edit box for InitialStep
            fieldname = 'InitialStep';
            InitialStep = uicontrol('Style','edit', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Initial step size', ...
                'Parent', panel, ...
                'Callback', @(hObj,~) editboxCallback(hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String','Initial', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 5;

            % construct edit box for MaxStep
            fieldname = 'MaxStep';
            MaxStep = uicontrol('Style','edit', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', panel, ...
                'TooltipString', 'Maximum step size', ...
                'Callback', @(hObj,~) editboxCallback(hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 20;

            % Statistics
            uicontrol('Style','text', ...
                'String','Statistics', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontWeight','bold', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+2*boxh 3*boxw+10 boxh]);

            % nsteps
            nsteps = uicontrol('Style','text', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontWeight','normal', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String','nsteps', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 5;

            % nfailed
            nfailed = uicontrol('Style','text', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontWeight','normal', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String','nfailed', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 5;

            % nfevals
            nfevals = uicontrol('Style','text', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontWeight','normal', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String','nfevals', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+boxh boxw boxh]);
            
            % update the edit box contents
            renderboxes;
            
            % listen to the control panel for redraw events
            this.listener2 = addlistener(control,'redraw',@(~,~) renderboxes);    

            % Listener function for updating the edit boxes
            function renderboxes
                %disp('bdSolverPanel.odePanel.renderboxes()')
                solvertype = control.solvermap(control.solveridx).solvertype;
                switch solvertype
                    case 'odesolver'
                        AbsTol.String = num2str(odeget(control.sys.odeoption,'AbsTol'),'%g');
                        RelTol.String = num2str(odeget(control.sys.odeoption,'RelTol'),'%g');
                        InitialStep.String = num2str(odeget(control.sys.odeoption,'InitialStep'),'%g');
                        MaxStep.String = num2str(odeget(control.sys.odeoption,'MaxStep'),'%g');
                        AbsTol.Enable = 'on';
                        RelTol.Enable = 'on';
                        InitialStep.Enable = 'on';
                        MaxStep.Enable = 'on';
                    case 'ddesolver'
                        AbsTol.String = num2str(ddeget(control.sys.ddeoption,'AbsTol'),'%g');
                        RelTol.String = num2str(ddeget(control.sys.ddeoption,'RelTol'),'%g');
                        InitialStep.String = num2str(ddeget(control.sys.ddeoption,'InitialStep'),'%g');
                        MaxStep.String = num2str(ddeget(control.sys.ddeoption,'MaxStep'),'%g');
                        AbsTol.Enable = 'on';
                        RelTol.Enable = 'on';
                        InitialStep.Enable = 'on';
                        MaxStep.Enable = 'on';
                    case 'sdesolver'
                        if isfield(control.sys.sdeoption,'InitialStep')
                            InitialStep.String = num2str(control.sys.sdeoption.InitialStep,'%g');
                        end
                        AbsTol.Enable = 'off';
                        RelTol.Enable = 'off';
                        InitialStep.Enable = 'on';
                        MaxStep.Enable = 'off';
                end
                if ~isempty(control.sol)
                    nsteps.String = num2str(control.sol.stats.nsteps,'%d');
                    nfailed.String = num2str(control.sol.stats.nfailed,'%d');
                    nfevals.String = num2str(control.sol.stats.nfevals,'%d');
                end
            end
            
            % Callback for user input to the edit boxes
            function editboxCallback(uibox,fieldname)
                %disp('bdSolverPanel.odePanel.editboxCallback()')
                % convert the edit box string into an odeoption value
                if isempty(uibox.String)
                    val = [];               % use an empty odeoption value for an empty edit box
                else    
                    % get the incoming value from a non-empty edit box
                    val = str2double(uibox.String);
                    if isnan(val)
                        % invalid number
                        dlg = errordlg(['''', uibox.String, ''' is not a valid number'],'Invalid Number','modal');
                        % restore previous edit box value/string
                        val = uibox.Value;    
                        uibox.String = num2str(val,'%0.4g');
                        % wait for dialog box to close
                        uiwait(dlg);
                    end
                end
                
                % remember the new value
                uibox.Value = val;
                
                % update the solver options
                switch control.solvermap(control.solveridx).solvertype
                    case 'odesolver'
                        control.sys.odeoption = setfield(control.sys.odeoption,fieldname,val);
                    case 'ddesolver'
                        control.sys.ddeoption = setfield(control.sys.ddeoption,fieldname,val);
                    case 'sdesolver'
                        control.sys.sdeoption = setfield(control.sys.sdeoption,fieldname,val);
                        control.sys.sdeoption.randn = [];
                end

                % recompute
                notify(control,'recompute');
            end           
        end
        
        function render(this,control)
            %disp('bdSolverPanel.render()')
            tsteps = control.sol.x;
                        
            % render dy/dt versus time
            dydt = diff(control.sol.y,1,2);
            nrm = sqrt( sum(dydt.^2,1) );
            set(this.plt1, 'XData',tsteps, 'YData',nrm([1:end,end]));
            
            % render the step size versus time
            stepsize = diff(control.sol.x);
            set(this.plt2, 'XData',tsteps, 'YData',stepsize([1:end,end]));
            ylim(this.ax2,[0 max(stepsize)*1.1]); 

            % show gridlines (or not)
            if this.gridflag
                grid(this.ax1,'on');
                grid(this.ax2,'on');
            else
                grid(this.ax1,'off')
                grid(this.ax2,'off')
            end
        end
          
        function contextMenu(this,control)            
            % init the menu flags from the sys.panels options     
            this.gridflag = control.sys.panels.bdSolverPanel.grid;
            
            % grid menu check string
            if this.gridflag
                gridcheck = 'on';
            else
                gridcheck = 'off';
            end
            
            % construct the tab context menu
            this.tab.UIContextMenu = uicontextmenu;

            % construct menu items
            uimenu(this.tab.UIContextMenu, ...
                   'Label','Grid', ...
                   'Checked',gridcheck, ...
                   'Callback', @(menuitem,~) ContextCallback(menuitem) );
            uimenu(this.tab.UIContextMenu, ...
                   'Label','Close', ...
                   'Callback',@(~,~) this.delete());

            % Context Menu Item Callback
            function ContextCallback(menuitem)
                switch menuitem.Label
                    case 'Grid'
                        switch menuitem.Checked
                            case 'on'
                                this.gridflag = false;
                                menuitem.Checked='off';
                            case 'off'
                                this.gridflag = true;
                                menuitem.Checked='on';
                        end
                end
                % redraw this panel
                this.render(control);
            end
        end        
              
            
        % Callback for tab panel resizing.
        function SizeChanged(this,parent)
            %disp('bdSolverPanel.SizeChanged()')
            
            % get new parent geometry
            parentw = parent.Position(3);
            parenth = parent.Position(4);

            % compute axes geometry
            axesh = (parenth-200)/2;
            axesw = parentw-100;

            % resize axes
            this.ax1.Position(2) = 180 + axesh;
            this.ax1.Position(3) = axesw;
            this.ax1.Position(4) = axesh;
            this.ax2.Position(3) = axesw;
            this.ax2.Position(4) = axesh;
        end
        
    end
    
    
    methods (Static)
        
        % Check the sys.panels struct
        function syspanel = syscheck(sys)
            % Default panel settings
            syspanel.title = 'Solver';
            syspanel.grid = false;
            
            % Nothing more to do if sys.panels.bdSolverPanel is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdSolverPanel')
                return;
            end
            
            % sys.panels.bdSolverPanel.title
            if isfield(sys.panels.bdSolverPanel,'title')
                syspanel.title = sys.panels.bdSolverPanel.title;
            end
            
            % sys.panels.bdSolverPanel.grid
            if isfield(sys.panels.bdSolverPanel,'grid')
                syspanel.grid = sys.panels.bdSolverPanel.grid;
            end
        end
        
     end    
    
end

