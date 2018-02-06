classdef bdSolverPanel < bdPanel
    %bdSolverPanel Display panel for solver options in bdGUI.
    %   The solver panel allows the user to modify the various options
    %   for the solver algorithm, such as the error tolerances and step
    %   size control.
    %
    %AUTHORS
    %  Stewart Heitmann (2016a,2017a,2018a)

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
        title = 'Solver';
    end    

    properties
        dt              % Time steps of the solution (1 x t-1)
        dy              % Increments of the solution (1 x t-1)
    end
    
    properties (Access=private) 
        ax1             % Handle to the upper plot axes
        ax2             % Handle to the lower plot axes
        gridmenu        % handle to GRID menu item
        plt1            % handle to plot line (axis 1)
        plt2            % handle to plot line (axis 2)     
        AbsTol          % handle to AbsTol edit box
        RelTol          % handle to RelTol edit box
        InitialStep     % handle to InitialStep edit box
        MaxStep         % handle to MaxStep edit box
        listener        % handle to listener
    end
 
    methods        
        function this = bdSolverPanel(tabgroup,control)
            % Construct a new Solver Panel in the given tabgroup
            
            % initialise the base class (specifically this.menu and this.tab)
            this@bdPanel(tabgroup);

            % assign default values to missing options in sys.panels.bdSolverPanel
            control.sys.panels.bdSolverPanel = bdSolverPanel.syscheck(control.sys);

            % configure the pull-down menu
            this.menu.Label = control.sys.panels.bdSolverPanel.title;
            this.InitCalibrateMenu(control);
            this.InitGridMenu(control);
            this.InitExportMenu(control);
            this.InitCloseMenu(control);

            % configure the panel graphics
            this.tab.Title = control.sys.panels.bdSolverPanel.title;
            this.InitPanel(control);

            % register a callback for resizing the panel
            set(this.tab,'SizeChangedFcn', @(~,~) this.SizeChanged());

            % listen to the control panel for redraw events
            this.listener = addlistener(control,'redraw',@(~,~) this.redraw(control));    
        end
        
        % Destructor
        function delete(this)
            delete(this.listener);
            delete(this.tab);          
        end       
        
    end
    
    methods (Access=private)
                
        % Initialise the CALIBRATE menu item
        function InitCalibrateMenu(this,control)
            % construct the menu item
            uimenu(this.menu, ...
               'Label','Calibrate Axes', ...
                'Callback', @CalibrateMenuCallback );
            
            % Menu callback function
            function CalibrateMenuCallback(~,~)
                % find the limits of the upper and lower plots
                hi1 = max(this.plt1.YData);
                hi2 = max(this.plt2.YData);
                
                % adjust the y-limits of the upper and lower plots
                this.ax1.YLim = bdPanel.RoundLim(-1e-4, hi1 + 1e-4);
                this.ax2.YLim = bdPanel.RoundLim(-1e-4, hi2 + 1e-4);
            end

        end       

        % Initiliase the GRID menu item
        function InitGridMenu(this,control)
            % get the default grid menu setting from sys.panels
            if control.sys.panels.bdSolverPanel.grid
                gridcheck = 'on';
            else
                gridcheck = 'off';
            end

            % construct the menu item
            this.gridmenu = uimenu(this.menu, ...
                'Label','Grid', ...
                'Checked',gridcheck, ...
                'Callback', @GridMenuCallback);

            % Menu callback function
            function GridMenuCallback(menuitem,~)
                switch menuitem.Checked
                    case 'on'
                        menuitem.Checked='off';
                        grid(this.ax1,'off');
                        grid(this.ax2,'off');
                    case 'off'
                        menuitem.Checked='on';
                        grid(this.ax1,'on');
                        grid(this.ax2,'on');
                end
            end
        end     
        
        % Initialise the EXPORT menu item
        function InitExportMenu(this,control)
            % construct the menu item
            uimenu(this.menu, ...
               'Label','Export Figure', ...
               'Callback',@callback);
           
            function callback(~,~)
                % Construct a new figure
                fig = figure();    
                
                % Change mouse cursor to hourglass
                set(fig,'Pointer','watch');
                drawnow;
                
                % Copy the upper axes to the new figure
                ax1new = copyobj(this.ax1,fig);
                ax1new.Units = 'normal';
                ax1new.OuterPosition = [0 0.5 1 0.5];
                xlabel(ax1new,'time (t)');
                title(ax1new,'Vector Norm of the Solution Increment');

               % Copy the lower axes to the new figure
                ax2new = copyobj(this.ax2,fig);
                ax2new.Units = 'normal';
                ax2new.OuterPosition = [0 0 1 0.5];
                title(ax2new,'Time Steps');

                % Allow the user to hit everything in the new figure
                objs = findobj(ax1new,'-property', 'HitTest');
                set(objs,'HitTest','on');
                objs = findobj(ax2new,'-property', 'HitTest');
                set(objs,'HitTest','on');
                
                % Change mouse cursor to arrow
                set(fig,'Pointer','arrow');
                drawnow;
            end
        end

        % Initialise the CLOSE menu item
        function InitCloseMenu(this,control)
            % construct the menu item
            uimenu(this.menu, ...
                   'Label','Close', ...
                   'Callback',@(~,~) this.close());
        end
        
        % Initialise the panel
        function InitPanel(this,control)
            %disp('bdSolverPanel.InitPanel');
            
            % Construct the uipanel container
            spanel = uipanel(this.tab, ...
                        'Units','normal', ...
                        'Position',[0 0 1 1], ...
                        'BorderType','beveledout');

            % get tab geometry
            tabw = this.tab.Position(3);
            tabh = this.tab.Position(4);

            % compute axes geometry
            axesh = (tabh-160)/2;
            axesw = tabw-120;

            % construct the dydt axes
            this.ax1 = axes('Parent',spanel, ...
                'Units','pixels', ...
                'Position', [70 140+axesh  axesw axesh], ...
                'FontSize',12, ...
                'Box','on');
            this.plt1 = stairs(0,0, 'parent',this.ax1, 'color','k', 'Linewidth',1);
            set(this.ax1,'TickDir','out');
            %xlabel('time','FontSize',14);
            ylabel(this.ax1,'||dY||');
            ylim(this.ax1,[-0.1 1.1]);
            %title(this.ax1,'Vector Norm of Solution Increment');

            % construct the step-size axes
            this.ax2 = axes('Parent',spanel, ...
                'Units','pixels', ...
                'Position', [70 110 axesw axesh], ...
                'FontSize',12, ...
                'Box','on');
            this.plt2 = stairs(0,0, 'parent',this.ax2, 'color','k', 'Linewidth',1);
            set(this.ax2,'TickDir','out');
            xlabel(this.ax2,'time (t)');
            ylabel(this.ax2,'time step (dt)');
            ylim(this.ax2,[-0.1 1.1]);
            %title(this.ax2,'Step Size');

            % edit box geometry
            boxw = 50;
            boxh = 20;
            boxx = 5;

            % Error Control
            uicontrol('Style','text', ...
                'String','Error Control', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontWeight','bold', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', spanel, ...
                'Position',[boxx 10+2*boxh 2*boxw+5 boxh]);

            % construct edit box for AbsTol
            fieldname = 'AbsTol';
            this.AbsTol = uicontrol('Style','edit', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Absolute error tolerance', ...
                'Parent', spanel, ...
                'Callback', @(hObj,~) editboxCallback(control,hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', spanel, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 5;
            
            % construct edit box for RelTol
            fieldname = 'RelTol';
            this.RelTol = uicontrol('Style','edit', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Relative error tolerance', ...
                'Parent', spanel, ...
                'Callback', @(hObj,~) editboxCallback(control,hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', spanel, ...
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
                'Parent', spanel, ...
                'Position',[boxx 10+2*boxh 2*boxw+5 boxh]);

            % construct edit box for InitialStep
            fieldname = 'InitialStep';
            this.InitialStep = uicontrol('Style','edit', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Initial step size', ...
                'Parent', spanel, ...
                'Callback', @(hObj,~) editboxCallback(control,hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String','Initial', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', spanel, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 5;

            % construct edit box for MaxStep
            fieldname = 'MaxStep';
            this.MaxStep = uicontrol('Style','edit', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', spanel, ...
                'TooltipString', 'Maximum step size', ...
                'Callback', @(hObj,~) editboxCallback(control,hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', spanel, ...
                'Position',[boxx 10+boxh boxw boxh]);
            
            % fill the edit boxes
            switch control.solvertype
                case 'odesolver'
                    this.AbsTol.String = num2str(odeget(control.sys.odeoption,'AbsTol'),'%g');
                    this.RelTol.String = num2str(odeget(control.sys.odeoption,'RelTol'),'%g');
                    this.InitialStep.String = num2str(odeget(control.sys.odeoption,'InitialStep'),'%g');
                    this.MaxStep.String = num2str(odeget(control.sys.odeoption,'MaxStep'),'%g');
                case 'ddesolver'
                    this.AbsTol.String = num2str(ddeget(control.sys.ddeoption,'AbsTol'),'%g');
                    this.RelTol.String = num2str(ddeget(control.sys.ddeoption,'RelTol'),'%g');
                    this.InitialStep.String = num2str(ddeget(control.sys.ddeoption,'InitialStep'),'%g');
                    this.MaxStep.String = num2str(ddeget(control.sys.ddeoption,'MaxStep'),'%g');
                case 'sdesolver'
                    if isfield(control.sys.sdeoption,'InitialStep')
                        this.InitialStep.String = num2str(control.sys.sdeoption.InitialStep,'%g');
                    end
            end
            
        end
        
    end
    
    methods (Access=private)
        
        % Redraw the data plots
        function redraw(this,control)
            %disp('bdSolverPanel.redraw()')
            
            % compute the time steps
            this.dt = diff(control.sol.x);
            
            % compute dy
            this.dy = diff(control.sol.y,1,2);
            
            % render the norm of dy versus time
            nrm = sqrt( sum(this.dy.^2,1) );
            set(this.plt1, 'XData',control.sol.x, 'YData',nrm([1:end,end]));
            
            % render the step size versus time
            set(this.plt2, 'XData',control.sol.x, 'YData',this.dt([1:end,end]));
            
            % Enable/Disable the edit boxes for special cases
            switch control.solvertype
                case 'odesolver'
                    switch func2str(control.solver)
                        case 'odeEul'
                            this.AbsTol.Enable = 'off';
                            this.RelTol.Enable = 'off';
                            this.InitialStep.Enable = 'on';
                            this.MaxStep.Enable = 'off';
                        otherwise
                            this.AbsTol.Enable = 'on';
                            this.RelTol.Enable = 'on';
                            this.InitialStep.Enable = 'on';
                            this.MaxStep.Enable = 'on';
                    end
                case 'ddesolver'
                    this.AbsTol.Enable = 'on';
                    this.RelTol.Enable = 'on';
                    this.InitialStep.Enable = 'on';
                    his.MaxStep.Enable = 'on';
                case 'sdesolver'
                    this.AbsTol.Enable = 'off';
                    this.RelTol.Enable = 'off';
                    this.InitialStep.Enable = 'on';
                    this.MaxStep.Enable = 'off';
            end

        end
          
        % Callback for panel resizing.
        function SizeChanged(this)
            %disp('bdSolverPanel.SizeChanged()')
            
            % get new parent geometry
            tabw = this.tab.Position(3);
            tabh = this.tab.Position(4);

            % compute axes geometry
            axesh = (tabh-160)/2;
            axesw = tabw-120;

            % resize axes
            this.ax1.Position(2) = 140 + axesh;
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
            syspanel.title = bdSolverPanel.title;
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

% Callback for user input to the edit boxes
function editboxCallback(control,uibox,fieldname)
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
    switch control.solvertype
        case 'odesolver'
            control.sys.odeoption.(fieldname) = val;
        case 'ddesolver'
            control.sys.ddeoption.(fieldname) = val;
        case 'sdesolver'
            control.sys.sdeoption.(fieldname) = val;
            control.sys.sdeoption.randn = [];
    end

    % recompute
    notify(control,'recompute');
end           

