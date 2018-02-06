classdef bdControl < handle
    %bdControl  Control panel for the Brain Dynamics Toolbox GUI.
    %  The bdControl class implements the graphical control panel used
    %  by bdGUI. It is not intended to be called directly by users.
    % 
    %AUTHORS
    %  Stewart Heitmann (2016a,2017a-c,2018a)

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
    
    properties
        sys             % working copy of the user-supplied system definition
        sol = []        % solution struct returned by the matlab solver
        par = []        % copy of the the parameters used to compute sol
        lag = []        % copy of the the lag parameters used to compute sol
        tindx           % indices of the non-transient time steps in sol.x 
        solver          % the active solver function
        solvertype      % solver type string ('odesolver' or 'ddesolver' or 'sdesolver')
        reverse = 0     % state of the REVERSE button
        halt = 0        % state of the HALT button
    end
    
    properties (Access=private)
        fig             % handle to the parent figue
        cpanel          % handle to control panel
        spanel          % handle to solver panel

        % Widgets in the control panel
        ui_hold         % handle to the noise HOLD button (SDE only)
        ui_evolve       % handle to the EVOLVE button
        ui_jitter       % handle to the JITTER button
        ui_transient    % handle to the TRANSIENT button
        ui_reverse      % handle to the REVERSE button
        
        % Widgets in the solver panel
        ui_solver       % handle to the SOLVER popup menu
        ui_halt         % handle to the HALT button
        ui_nsteps       % handle to the NSTEPS counter
        ui_nfailed      % handle to the NFAILED counter
        ui_nfevals      % handle to the NFEVALS counter
        ui_cputime      % handle to the CPU counter
        ui_progress     % handle to the PROGRESS counter
        ui_warning      % handle to the WARNING text

        % internal states
        recomputeflag   % flag for recompute events
        cpustart        % cpu start time
        timer           % handle to timer object
    end
    
    properties (Constant)
        cpanely = 0;     % vertical position of the control panel
        cpanelm = 0;     % vertical margin at top of control panel
        cpanelw = 244;   % width of the control panel
    end

    events
        recompute   % notifies the control panel that sol must be recomputed
        redraw      % notifes all display panels that sol must be replotted
        refresh     % notifies the control panel widgets to refresh their values
        vardef      % notifies the control panel widgets that sys.vardef has changed
        pardef      % notifies the control panel widgets that sys.pardef has changed
        lagdef      % notifies the control panel widgets that sys.lagdef has changed
    end
    
    methods
        % Constructor. 
        function this = bdControl(fig,sys)
            % Check the contents of sys and fill any missing fields with
            % default values. Rethrow any problems back to the caller.
            try
                this.sys = bd.syscheck(sys);
            catch ME
                throwAsCaller(MException('bdtoolkit:bdControl',ME.message));
            end
            
            % init the recompute flag
            this.recomputeflag = false;
            
            % remember the parent figure
            this.fig = fig;
            
            % init the sol struct
            this.sol.x=[];
            this.sol.y=[];
            this.sol.yp=[];
            this.sol.stats.nsteps=0;
            this.sol.stats.nfailed=0;
            this.sol.stats.nfevals=0;
            
            % init the indicies of the non-transient time steps in sol.x
            this.tindx = (this.sol.x >= this.sys.tval);
            
            % currently active solver (FIX ME TO ALLOW SOLVER SELECTION BEYOND THE FIRST SOLVER ONLY)
            if isfield(this.sys,'odesolver')
                this.solver = this.sys.odesolver{1};
                this.solvertype = 'odesolver';
            end
            if isfield(this.sys,'ddesolver')
                this.solver = this.sys.ddesolver{1};
                this.solvertype = 'ddesolver';
            end
            if isfield(this.sys,'sdesolver')
                this.solver = this.sys.sdesolver{1};
                this.solvertype = 'sdesolver';
            end
            
            % initialise the control panel
            this.ControlPanelInit();
                                    
            % initialise the solver panel
            this.SolverPanelInit();
            
            % listen for widget refresh events
            addlistener(this,'refresh',@(~,~) this.RefreshListener());    
   
            % listen for redraw events
            %addlistener(this,'redraw',@(~,~) this.RedrawListener());    
            
            % listen for recompute events
            addlistener(this,'recompute',@(~,~) this.RecomputeListener());

            % init the timer object and start it.           
            this.timer = timer('BusyMode','drop', ...
                'ExecutionMode','fixedSpacing', ...
                'Period',0.05, ...
                'TimerFcn', @(~,~) this.TimerFcn());
            start(this.timer);
        end
        
        
        function pos = CanvasPosition(this)
            % get parent figure geometry
            figw = this.fig.Position(3);
            figh = this.fig.Position(4);
            % get cpanel width
            cpanelw = this.cpanel.Position(3);
            % position of canvas
            pos = [0 50  figw-cpanelw figh-50];
        end
        
        % Resize the control panel to fit the figure window.
        function SizeChanged(this,fig)
            % get parent figure geometry
            figw = fig.Position(3);
            figh = fig.Position(4);

            % new geometry of the control panel
            x = figw - this.cpanelw;
            y = this.cpanely;
            w = this.cpanelw;
            h = figh - this.cpanely - this.cpanelm;
            this.cpanel.Position = [x y w h];
            
            % new geometry of the solver panel
            x = 5;
            y = 5;
            w = figw - bdControl.cpanelw - 5;
            h = 50;
            this.spanel.Position = [x y w h];
        end
       
        % Destructor
        function delete(this)
            stop(this.timer);
            delete(this.timer);
        end
    end
    
    
    methods (Access=private)  
        
        function ControlPanelInit(this)
            % get parent figure geometry
            figw = this.fig.Position(3);
            figh = this.fig.Position(4);

            % construct the container uipanel
            x = figw - this.cpanelw;
            y = this.cpanely;
            w = this.cpanelw;
            h = figh - this.cpanely - this.cpanelm;
            this.cpanel = uipanel(this.fig,'Units','pixels','Position',[x y w h],'BorderType','none');

            % construct a scrolling panel within the container panel
            scroll = bdScroll(this.cpanel,220,600);
            
            % eliminate the border on the scroll viewport
            scroll.vpanel.BorderType = 'none';

            % Widget geometry constants
            rowh = 22;
            boxw = 50;
            boxh = 20;
            col1 = 4;
            col2 = col1 + boxw + 5;
            col3 = col2 + boxw + 5;
            col4 = col3 + boxw + 5;
            col5 = col4 + boxw + 5;

            % Populate the scroll panel with widgets from bottom to top.
            % It makes it easier to resizie the scroll panel to its final height.
            ypos = 0.5*rowh;
            
            % REVERSE button
            this.ui_reverse = uicontrol('Style','radio', ...
                'String','Reverse', ...
                'Value',this.reverse, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', scroll.panel, ...
                'ToolTipString', 'Run the simulation backwards in time', ...
                'Position',[col3 ypos col5-col3 boxh]);
                        
            % next row
            ypos = ypos + 1.25*boxh;                        

            % Time Domain" checkbox (drawn in the wrong place but we need it now)
            timecheckbox = uicontrol('Style','checkbox',...
                'String','Time Domain', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Value',1, ...       
                'Callback', @(~,~) notify(this,'refresh'), ...                 
                'Parent', scroll.panel, ...
                'Position',[col1 ypos col5-col1 boxh]);

            % Add the time domain control widget
            bdControlTime(this,scroll.panel,ypos,timecheckbox);

            % next row
            ypos = ypos + 1.25*boxh;                        
                      
            % Move the "Initial Conditions" checkbox to its proper position
            timecheckbox.Position = [col1 ypos col5-col1 boxh];

            % next row
            ypos = ypos + 2*boxh;                        
                      
            % EVOLVE button
            this.ui_evolve = uicontrol('Style','radio', ...
                'String','Evolve', ...
                'Value',0, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', scroll.panel, ...
            ... 'Callback', @(src,~) set(src,'ForegroundColor','k'), ...
                'ToolTipString', 'Replace initial conditions with final values', ...
                'Position',[col1+3 ypos col3-col1 boxh]);
            
            % JITTER button
            this.ui_jitter = uicontrol('Style','radio', ...
                'String','Jitter', ...
                'Value',0, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', scroll.panel, ...
                'ToolTipString', 'Add jitter (5%) to the initial conditions', ...
                'Position',[col3 ypos col5-col3 boxh]);
            
            % next row
            ypos = ypos + 1.25*boxh;   
            
            % "Initial Conditions" checkbox (drawn in the wrong place but we need it now)
            varcheckbox = uicontrol('Style','checkbox',...
                'String','Initial Conditions', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Value',1, ...
                'Callback', @(~,~) notify(this,'vardef'), ...
                'Parent', scroll.panel, ...
                'Position',[col1 ypos col5-col1 boxh]);
            
            % ODE var widgets (initial conditions)
            for varindx=numel(this.sys.vardef):-1:1
                % switch depending on the value being a scalar, vector or matrix
                switch ScalarVectorMatrix(this.sys.vardef(varindx).value)
                    case 1
                        % construct a scalar edit box widget
                        bdControlScalar(this,'vardef',varindx,scroll.panel,ypos,varcheckbox);
                        ypos = ypos + bdControlScalar.rowh; 
                    case 2
                        % construct a vector widget
                        bdControlVector(this,'vardef',varindx,scroll.panel,ypos);
                        ypos = ypos + bdControlVector.rowh; 
                    case 3
                        % construct a matrix widget
                        bdControlMatrix(this,'vardef',varindx,scroll.panel,ypos);
                        ypos = ypos + bdControlMatrix.rowh; 
                end
            end

            % Move the "Initial Conditions" checkbox to its proper position
            varcheckbox.Position = [col1 ypos col5-col1 boxh];

            % DDE lag widgets (if applicable)
            if isfield(this.sys,'lagdef')
                % next row
                ypos = ypos + 2*boxh;                        
                        
                % "Lag Parameters" checkbox (drawn in the wrong place but we need it now)
                lagcheckbox = uicontrol('Style','checkbox', ...
                    'String','Time Lags', ...
                    'HorizontalAlignment','left', ...
                    'FontUnits','pixels', ...
                    'FontSize',12, ...
                    'FontWeight','bold', ...
                    'Value',1, ...
                    'Callback', @(~,~) notify(this,'lagdef'), ...                 
                    'Parent', scroll.panel, ...
                    'Position',[col1 ypos col5-col1 boxh]);

                % for each lagdef entry
                for lagindx=numel(this.sys.lagdef):-1:1
                    % switch depending on the value being a scalar, vector or matrix
                    switch ScalarVectorMatrix(this.sys.lagdef(lagindx).value)
                        case 1              
                            % construct a scalar edit box widget
                            bdControlScalar(this,'lagdef',lagindx,scroll.panel,ypos,lagcheckbox);
                            ypos = ypos + bdControlScalar.rowh; 
                        case 2
                            % construct a vector widget
                            bdControlVector(this,'lagdef',lagindx,scroll.panel,ypos);
                            ypos = ypos + bdControlVector.rowh; 
                        case 3
                            % construct a matrix widget
                            bdControlMatrix(this,'lagdef',lagindx,scroll.panel,ypos);
                            ypos = ypos + bdControlMatrix.rowh; 
                    end
                end     

                % Move the "Lag Parameters" checkbox to its proper position
                lagcheckbox.Position = [col1 ypos col5-col1 boxh];
            end
            
            % SDE random-hold widgets (if applicable)
            if isfield(this.sys,'sdeF')
                % next row
                ypos = ypos + 2*boxh;
                
                % HOLD button
                this.ui_hold = uicontrol('Style','radio', ...
                    'String','Hold', ...
                    'Value', (isfield(this.sys.sdeoption,'randn') && ~isempty(this.sys.sdeoption.randn) ), ...
                    'HorizontalAlignment','left', ...
                    'FontUnits','pixels', ...
                    'FontSize',12, ...
                    'FontWeight','normal', ...
                    'ForegroundColor', 'k', ...
                    'Parent', scroll.panel, ...
                    'ToolTipString', 'Hold the random samples fixed', ...
                    'Callback', @(~,~) this.HoldCallback(), ...
                    'Position',[col1 ypos col5-col1 boxh]);
                
                % next row
                ypos = ypos + boxh;                        

                % Noise title
                uicontrol('Style','text', ...
                    'String','Noise Samples', ...
                    'HorizontalAlignment','left', ...
                    'FontUnits','pixels', ...
                    'FontSize',12, ...
                    'FontWeight','bold', ...
                    'Parent', scroll.panel, ...
                    'Position',[col1 ypos col5-col1 boxh]);
            end
            
            % next row
            ypos = ypos + 2*boxh;                        
            
            % "Parameters" checkbox (drawn in the wrong place but we need it now)
            parcheckbox = uicontrol('Style','checkbox', ...
                'String','Parameters', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Value',1, ... 
                'Callback', @(~,~) notify(this,'pardef'), ...                
                'Parent', scroll.panel, ...
                'Position',[col1 ypos col5-col1 boxh]);

            % ODE parameter widgets
            for parindx=numel(this.sys.pardef):-1:1
                % switch depending on the value being a scalar, vector or matrix
                switch ScalarVectorMatrix(this.sys.pardef(parindx).value)
                    case 1 
                        % construct a scalar edit box widget
                        bdControlScalar(this,'pardef',parindx,scroll.panel,ypos,parcheckbox);
                        ypos = ypos + bdControlScalar.rowh; 
                    case 2
                        % construct a vector widget
                        bdControlVector(this,'pardef',parindx,scroll.panel,ypos);
                        ypos = ypos + bdControlVector.rowh; 
                    case 3
                        % construct a matrix widget
                        bdControlMatrix(this,'pardef',parindx,scroll.panel,ypos);
                        ypos = ypos + bdControlMatrix.rowh; 
                end
            end
            
            % Move the "Parameters" checkbox to its proper position
            parcheckbox.Position = [col1 ypos col5-col1 boxh];
            
            % next row
            ypos = ypos + 1.5*boxh;                        
            
            % adjust the height of the scroll panel so that it fits the widgets snugly
            scroll.panel.Position(4) = ypos;
        end
           
        function SolverPanelInit(this)
            % get figure geometry
            figw = this.fig.Position(3);
            figh = this.fig.Position(4);

            % Widget geometry constants
            row1 = 2;
            row2 = row1 + 20;
            row3 = row2 + 27;
            col1 = 4;
            col2 = col1 + 100;
            col3 = col2 + 55;
            col4 = col3 + 55;
            col5 = col4 + 60;
            col6 = col5 + 55;
            col7 = col6 + 60;
            col8 = col7 + 70;
            
            % construct the container uipanel
            x = 5;
            y = 5;
            w = figw - bdControl.cpanelw - 5;
            this.spanel = uipanel(this.fig,'Units','pixels','Position',[x y w row3],'BorderType','none');
            
            % SOLVER pop-up menu 
            this.ui_solver = uicontrol('Style','popupmenu',...
                'String', this.SolverStrings(), ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',14, ...
                'FontWeight','normal', ...
                'Parent', this.spanel, ...
                'Position',[col1 row2+2 col2-col1 25], ...
                'Callback', @(menuitem,~) this.SolverMenuCallback(menuitem), ...
                'ToolTipString','Solver');
            
            % HALT button
            this.ui_halt = uicontrol('Style','radio', ...
                'String','HALT', ...
                'Value',this.halt, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',14, ...
                'FontWeight','bold', ...
                'ForegroundColor', 'r', ...
                'Parent', this.spanel, ...
                'ToolTipString', 'Halt the solver', ...
                'Callback', @(src,~) this.HaltCallback(src), ...
                'Position',[col1+4 row1 col2-col1 row2-row1]);            

            % nsteps Heading
            uicontrol('Style','text', ...
                'String','nsteps', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','normal', ...
                'Parent', this.spanel, ...
                'Position',[col2 row2 col3-col2 20]);

            % nsteps counter 
            this.ui_nsteps = uicontrol('Style','text',...
                'String','0', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',14, ...
                'FontWeight','normal', ...
                'Parent', this.spanel, ...
                'ToolTipString','Number of steps taken by the solver', ...
                'Position',[col2 row1 col3-col2 row2-row1]);
            
            % nfailed Heading
            uicontrol('Style','text', ...
                'String','nfailed', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','normal', ...
                'Parent', this.spanel, ...
                'Position',[col3 row2 col4-col3 20]);

            % nfailed counter 
            this.ui_nfailed = uicontrol('Style','text',...
                'String','0', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',14, ...
                'FontWeight','normal', ...
                'Parent', this.spanel, ...
                'ToolTipString','Number of steps that failed', ...
                'Position',[col3 row1 col4-col3 row2-row1]);

            % nfevals Heading
            uicontrol('Style','text', ...
                'String','nfevals', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','normal', ...
                'Parent', this.spanel, ...
                'Position',[col4 row2 col5-col4 20]);

            % nfevals counter 
            this.ui_nfevals = uicontrol('Style','text',...
                'String','0', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',14, ...
                'FontWeight','normal', ...
                'Parent', this.spanel, ...
                'ToolTipString','Number of function evaluations', ...
                'Position',[col4 row1 col5-col4 row2-row1]);
                        
            % Progress Heading
            uicontrol('Style','text', ...
                'String','Progress', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','normal', ...
                'Parent', this.spanel, ...
                'Position',[col5 row2 col6-col5 20]);

            % Progress counter  
            this.ui_progress = uicontrol('Style','text',...
                'String','0%', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',14, ...
                'FontWeight','normal', ...
        ...        'ForegroundColor', [0.5 0.5 0.5], ...
                'Parent', this.spanel, ...
                'ToolTipString','Progress of the solver algorithm', ...
                'Position',[col5 row1 col6-col5 row2-row1]);
            
            % CPU Heading
            uicontrol('Style','text', ...
                'String','CPU', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','normal', ...
                'Parent', this.spanel, ...
                'Position',[col6 row2 col7-col6 20]);

            % CPU time 
            this.ui_cputime = uicontrol('Style','text',...
                'String','0.00s', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',14, ...
                'FontWeight','normal', ...
                'Parent', this.spanel, ...
                'ToolTipString','CPU time (secs)', ...
                'Position',[col6 row1 col7-col6 row2-row1]);
            
            % Warning Heading
            uicontrol('Style','text', ...
                'String','Warning', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','normal', ...
                'Parent', this.spanel, ...
                'Position',[col7 row2 col8-col7 20]);

            % WARNING text
            this.ui_warning = uicontrol('Style','text',...
                'String','none', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',14, ...
                'FontWeight','normal', ...
                'ForegroundColor','k', ...
                'Parent', this.spanel, ...
                'ToolTipString','Solver Warning Message', ...
                'Position',[col7 row1 150 row2-row1]);
        end
        
        % Return a cell array of strings for the solver functions
        function str = SolverStrings(this)
            str = {};
            if isfield(this.sys,'odesolver')
                for indx=1:numel(this.sys.odesolver)
                    str{indx} = func2str(this.sys.odesolver{indx});
                end
            end
            if isfield(this.sys,'ddesolver')
                for indx=1:numel(this.sys.ddesolver)
                    str{indx} = func2str(this.sys.ddesolver{indx});
                end
            end
            if isfield(this.sys,'sdesolver')
                for indx=1:numel(this.sys.sdesolver)
                    str{indx} = func2str(this.sys.sdesolver{indx});
                end
            end
        end
        
        % Solver Popup Menu Callback
        function SolverMenuCallback(this,menuitem)
            % Set the index of the active solver
            %this.solveridx = menuitem.UserData;
            strindx = menuitem.Value;
            this.solver = str2func(menuitem.String{strindx});
            
            % Recompute using the new solver
            notify(this,'recompute');  
        end
                    
        % Listener for widget REFRESH events
        function RefreshListener(this)
            %disp('bdControl.RefreshListener');
            
            % refresh the NSTEPS counter
            this.ui_nsteps.String = num2str(this.sol.stats.nsteps,'%d');

            % refresh the NFAILED counter
            this.ui_nfailed.String = num2str(this.sol.stats.nfailed,'%d');

            % refresh the NFEVALS counter
            this.ui_nfevals.String = num2str(this.sol.stats.nfevals,'%d');

            % refresh the HALT button
            this.ui_halt.Value = this.halt;                

            if this.halt
                % change the solver stats to red
                this.ui_nsteps.ForegroundColor = 'r';
                this.ui_nfailed.ForegroundColor = 'r';
                this.ui_nfevals.ForegroundColor = 'r';
                this.ui_cputime.ForegroundColor = 'r';
                this.ui_progress.ForegroundColor = 'r';
                %this.ui_cputime.String = '0.00s';
                %this.ui_progress.String = '-';
            else
                % change the solver stats to black
                this.ui_nsteps.ForegroundColor = 'k';
                this.ui_nfailed.ForegroundColor = 'k';
                this.ui_nfevals.ForegroundColor = 'k';
                this.ui_cputime.ForegroundColor = 'k';
                this.ui_progress.ForegroundColor = 'k';
            end
        end
        
        % Listener for RECOMPUTE events
        function RecomputeListener(this)
            % Recompute events often come faster than we can recompute the
            % solution. So we just note the arrival of the event here and
            % let the timer loop do the actual computation when it is ready. 
            this.recomputeflag = true;
        end
        
        % Recompute the solution (called by the timer)
        function Recompute(this)
            % Do nothing if the HALT button is active
            if this.halt
                return
            end
            
            % We use the ODE OutputFcn to track progress in our solver and to detect halt events. 
            switch this.solvertype
                case 'odesolver'
                    this.sys.odeoption = odeset(this.sys.odeoption, 'OutputFcn',@this.odeOutputFcn, 'OutputSel',[]);
                case 'ddesolver'
                    this.sys.ddeoption = ddeset(this.sys.ddeoption, 'OutputFcn',@this.odeOutputFcn, 'OutputSel',[]);
                case 'sdesolver'
                    this.sys.sdeoption.OutputFcn = @this.odeOutput;
                    this.sys.sdeoption.OutputSel = [];      
            end

            % Remember the parameters of the (to be computed) solution in the control.par struct.
            % We do this because the controls can change the values in sys.pardef
            % faster than the solver can keep up.
            for indx = 1:numel(this.sys.pardef)
                name = this.sys.pardef(indx).name;
                value = this.sys.pardef(indx).value;
                this.par.(name) = value;
            end

            % Remember the lag parameters too (if applicable)
            if isfield(this.sys,'lagdef')
                for indx = 1:numel(this.sys.lagdef)
                    name = this.sys.lagdef(indx).name;
                    value = this.sys.lagdef(indx).value;
                    this.lag.(name) = value;
                end
            end
            
            % evolve the initial conditions (if applicable)
            if this.ui_evolve.Value
                inlim = false;

                % check that any initial condition is within the axis limits
                for indx=1:numel(this.sys.vardef)
                    val = this.sys.vardef(indx).value;        % initial value
                    lim = this.sys.vardef(indx).lim;          % limit
                    if any( lim(1)<=val & val<=lim(2) )
                        inlim = true;
                    end
                end
                
                if ~inlim
                    oldwarn = warning('off','backtrace');                
                    warning('bdGUI:outlimit','Initial Conditions were not advanced because they are beyond the axes limits.');
                    warning(oldwarn.state,'backtrace');                
                else
                    % for each entry in vardef
                    for indx=1:numel(this.sys.vardef)
                        valsize = size(this.sys.vardef(indx).value);        % size of the variable value
                        solindx = this.sys.vardef(indx).solindx;            % corresponding indices of the variable in sol
                        val = reshape( this.sol.y(solindx,end), valsize);   % the final value in the solution ...
                        this.sys.vardef(indx).value = val;                  % ... replaces the initial value    
                    end
                    % notify the vardef widgets to refresh themselves
                    notify(this,'vardef');
                end
            end            

            % clear the last warning message
            lastwarn('');            

            % Call the solver
            if this.ui_jitter.Value
                % Make a working copy of the sys
                worksys = this.sys;
                % Apply a small jitter to each variable
                for indx = 1:numel(worksys.vardef)
                    % determine the limits of the variable
                    lo = worksys.vardef(indx).lim(1);
                    hi = worksys.vardef(indx).lim(2);
                    % determine the size of the variable
                    valsize = size(worksys.vardef(indx).value);
                    % perturb the variable by 5% uniform random
                    worksys.vardef(indx).value =  worksys.vardef(indx).value + ...
                        0.05*(hi-lo)*(rand(valsize)-0.5);
                end
                
                % call the solver using the working copy of sys
                oldwarn = warning('off','backtrace');                
                this.sol = bd.solve(worksys,this.sys.tspan,this.solver,this.solvertype);
                warning(oldwarn.state,'backtrace');                
            else
                % call the solver using the sys 
                oldwarn = warning('off','backtrace');                
                this.sol = bd.solve(this.sys,this.sys.tspan,this.solver,this.solvertype);
                warning(oldwarn.state,'backtrace');                
            end
            
            % Display any warnings from the solver
            [msg,msgid] = lastwarn();
            ix = find(msgid==':',1,'last');
            if ~isempty(ix)
                this.ui_warning.String = msgid((ix+1):end);
                this.ui_warning.TooltipString = msg;
                this.ui_warning.ForegroundColor = 'r';
            else
                this.ui_warning.String = 'none';
                this.ui_warning.TooltipString = 'Solver Warning Message';
                this.ui_warning.ForegroundColor = 'k';
            end
            if ~isempty(msgid) & this.ui_evolve.Value
                % enable the HALT state
                %this.halt=1;
                % disable the EVOLVE state
                this.ui_evolve.Value = 0;
                %this.ui_evolve.ForegroundColor='r';
                %notify(this,'refresh');
            end
            
            % Hold the SDEnoise if the HOLD button is 'on'
            switch this.solvertype
                case 'sdesolver'
                    if this.ui_hold.Value==1 && isempty(this.sys.sdeoption.randn) 
                         dt = this.sol.x(2) - this.sol.x(1);
                         this.sys.sdeoption.randn = this.sol.dW ./ sqrt(dt);
                    end
            end
            
            % update the indices of the non-transient steps in sol.x
            % Note: tindx can be all zeros in cases where the solver
            % terminated early because of blow-out or tolerance failures.
            this.tindx = (this.sol.x >= this.sys.tval) & min(isfinite(this.sol.y));
            
            % notify all listeners that a redraw is required
            notify(this,'redraw');
            
%             % evolve the initial conditions (if required)
%             if this.ui_evolve.Value
%                 offset = 0;
%                 % for each vardef entry ...
%                 for indx=1:numel(this.sys.vardef)
%                     s = size(this.sys.vardef(indx).value);
%                     n = numel(this.sys.vardef(indx).value);
%                     val = this.sol.y([1:n]+offset,end);
%                     val = reshape(val,s);
%                     this.sys.vardef(indx).value = val; 
%                     offset = offset+n;
%                     
% %                     % Disengage the EVOLVE button if the initial conditions
% %                     % have breached the var limits. This prevents run-away blow-out.
% %                     minval = min(val(:));
% %                     maxval = max(val(:));
% %                     if minval < this.sys.vardef(indx).lim(1) || maxval > this.sys.vardef(indx).lim(2)
% %                         this.ui_evolve.Value = 0;
% %                         beep;
% %                     end
%                 end
%                 % notify all widgets to refresh (we only really need to refresh the initial conditions)
%                 %notify(this,'refresh');
%                 notify(this,'vardef');
%             end
            
            % refresh the solver NSTEPS counter
            this.ui_nsteps.String = num2str(this.sol.stats.nsteps,'%d');

            % refresh the solver NFAILED counter
            this.ui_nfailed.String = num2str(this.sol.stats.nfailed,'%d');

            % refresh the solver NFEVALS counter
            this.ui_nfevals.String = num2str(this.sol.stats.nfevals,'%d');
            
            % update the CPU time to include the time to redraw/refresh the GUI
            cpu = cputime - this.cpustart;
            this.ui_cputime.String = num2str(cpu,'%5.2fs');
        end
   
        function TimerFcn(this)
            %disp('TimerFcn');
            
            % if the application figure is gone then... 
            if ~ishghandle(this.fig)
                stop(this.timer);       % stop the timer
                return
            end
            
            % recompute the solution if required
            if this.recomputeflag
                this.recomputeflag = false;
                this.Recompute();
            end
            
%             % If either of the EVOLVE or JITTER buttons are active
%             % then initate another recompute event.
%             if (this.ui_jitter.Value || this.ui_evolve.Value)
%                 this.recomputeflag = true;
%             end
        end
        
        % Callback function for ODE solver output
        function status = odeOutputFcn(this,t,~,flag,varargin)
            persistent tictime
            switch flag
                case 'init'
                    tictime = tic;
                    this.cpustart = cputime;
                    this.ui_nsteps.ForegroundColor = [0.75 0.75 0.75];
                    this.ui_nfailed.ForegroundColor = [0.75 0.75 0.75];
                    this.ui_nfevals.ForegroundColor = [0.75 0.75 0.75];
                    this.ui_progress.String = '  0%';
                    drawnow;
                case ''
                    % Update the solver stats whenever the elapsed time exceed 0.1 secs
                    elapsed = toc(tictime);
                    if elapsed>0.1
                        % reset our start time
                        tictime = tic;
                        % update the solver stats
                        cpu = cputime - this.cpustart;
                        this.ui_cputime.String = num2str(cpu,'%5.2fs');
                        this.ui_progress.String = num2str(100*t(1)/this.sys.tspan(2),'%3.0f%%');
                        drawnow;
                    end
                case 'done'
                   if this.halt~=1
                        cpu = cputime - this.cpustart;
                        this.ui_cputime.String = num2str(cpu,'%5.2fs');
                        this.ui_progress.String = '100%';
                        this.ui_nsteps.ForegroundColor = [0 0 0];
                        this.ui_nfailed.ForegroundColor = [0 0 0];
                        this.ui_nfevals.ForegroundColor = [0 0 0];            
                        drawnow;
                   end
            end   
            % return the state of the HALT button
            status = this.halt;
        end
        
        % Callback for the noise HOLD button (SDE only)
        function HoldCallback(this)
            if this.hld.Value==1
                dt = this.sol.x(2) - this.sol.x(1);
                this.sys.sdeoption.randn = this.sol.dW ./ sqrt(dt);
            else
                this.sys.sdeoption.randn = [];
            end
        end
        
        % Callback for the HALT button
        function HaltCallback(this,haltbutton)
            this.halt = haltbutton.Value;
            if this.halt
                notify(this,'refresh');             % notify widgets to refresh themselves
                notify(this,'redraw');
            else
                notify(this,'refresh');             % notify widgets to refresh themselves
                notify(this,'recompute');           % recompute the new solution
            end
        end
    
%         % Callback for the EVOLVE button
%         function EvolveCallback(this,evobutton)
%             if evobutton.Value
%                 % EVOLVE button is now ON
%             else
%                 % EVOLVE button is now OFF
%             end
%         end
    
    end
end

% Utility function to classify X as scalar (1), vector (2) or matrix (3)
function val = ScalarVectorMatrix(X)
    [nr,nc] = size(X);
    if nr*nc==1
        val = 1;        % X is scalar (1x1)
    elseif nr==1 || nc==1
        val = 2;        % X is vector (1xn) or (nx1)
    else
        val = 3;        % X is matrix (mxn)
    end
end


