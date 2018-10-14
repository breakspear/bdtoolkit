classdef bdControl < handle
    %bdControl  Control panel for the Brain Dynamics Toolbox GUI.
    %  The bdControl class implements the graphical control panel used
    %  by bdGUI. It is not intended to be called directly by users.
    % 
    %AUTHORS
    %  Stewart Heitmann (2016a,2017a-c,2018a-b)

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
    end
    
    properties (Access=private)
        fig             % handle to the parent figue
        cpanel          % handle to control panel
        spanel          % handle to solver panel

        % Widgets in the control panel
        ui_hold         % handle to the noise HOLD button (SDE only)
        ui_evolve       % handle to the EVOLVE button
        ui_perturb      % handle to the PERTURB button
        ui_rand         % handle to the RAND button
        ui_run          % handle to the RUN button
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
            
            % force a refresh of all widgets at startup
            this.RefreshListener();
            
            % listen for future widget refresh events
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
       
        % Load a user-supplied sol structure.
        function LoadSol(this,sol)
            % Load the solution structure
            this.sol = sol;

            % Replicate some of the post-compute operations normally done by this.Recompute()
            
            % 1. Remember the parameters of the (to be computed) solution in the control.par struct.
            for indx = 1:numel(this.sys.pardef)
                name = this.sys.pardef(indx).name;
                value = this.sys.pardef(indx).value;
                this.par.(name) = value;
            end

            % 2. Remember the lag parameters too (if applicable)
            if isfield(this.sys,'lagdef')
                for indx = 1:numel(this.sys.lagdef)
                    name = this.sys.lagdef(indx).name;
                    value = this.sys.lagdef(indx).value;
                    this.lag.(name) = value;
                end
            end
            
            % 3. Update the indices of the non-transient steps in sol.x
            this.tindx = (this.sol.x >= this.sys.tval) & min(isfinite(this.sol.y));
            
            % notify all listeners that a redraw is required
            notify(this,'redraw');
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
        
        % Force a recompute and wait until complete
        function RecomputeWait(this)
            this.recomputeflag = false;
            this.Recompute();
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
            
%             % REVERSE button
%             this.ui_reverse = uicontrol('Style','radio', ...
%                 'String','Reverse', ...
%                 'Value',this.reverse, ...
%                 'HorizontalAlignment','left', ...
%                 'FontUnits','pixels', ...
%                 'FontSize',12, ...
%                 'Parent', scroll.panel, ...
%                 'ToolTipString', 'Run the simulation backwards in time', ...
%                 'Position',[col3 ypos col5-col3 boxh]);
%                         
%             % next row
%             ypos = ypos + 1.25*boxh;                        

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
                'Value',this.sys.evolve, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', scroll.panel, ...
                'Callback', @(src,~) this.EvolveCallback(src), ...
                'ToolTipString', 'Replace the Initial Conditions with the final state before each run', ...
                'Position',[col1+3 ypos col3-col1 boxh]);
            
            % PERTURB button
            this.ui_perturb = uicontrol('Style','radio', ...
                'String','Perturb', ...
                'Value',this.sys.perturb, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', scroll.panel, ...
                'Callback', @(src,~) this.PerturbCallback(src), ...
                'ToolTipString', 'Perturb the Initial Conditions (5%) before each run', ...
                'Position',[85 ypos 70 boxh]);
            
            % RAND button
            this.ui_rand = uicontrol('Style','pushbutton', ...
                'String','RAND', ...
                'Value',0, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', scroll.panel, ...
                'Callback', @(src,~) this.RandCallback(src), ...
                'ToolTipString', 'Assign Uniform Random values to all Initial Conditions', ...
                'Position',[col4-1 ypos col5-col4-5 boxh]);

            % RUN button
            this.ui_run = uicontrol('Style','pushbutton', ...
                'String','RUN', ...
                'Value',0, ...
                'Visible','off', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', scroll.panel, ...
                'Callback', @(src,~) notify(this,'recompute'), ...
                'ToolTipString', 'Run (evolve) the simulation once more', ...
                'Position',[col4-1 ypos col5-col4-5 boxh]);

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
                        bdControlVector(this,'vardef',varindx,scroll.panel,ypos,varcheckbox);
                        ypos = ypos + bdControlVector.rowh; 
                    case 3
                        % construct a matrix widget
                        bdControlMatrix(this,'vardef',varindx,scroll.panel,ypos,varcheckbox);
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
                            bdControlVector(this,'lagdef',lagindx,scroll.panel,ypos,lagcheckbox);
                            ypos = ypos + bdControlVector.rowh; 
                        case 3
                            % construct a matrix widget
                            bdControlMatrix(this,'lagdef',lagindx,scroll.panel,ypos,lagcheckbox);
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
                    'Callback', @(src,~) this.HoldCallback(src), ...
                    'Position',[col1+3 ypos col5-col1 boxh]);
                
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
                        bdControlVector(this,'pardef',parindx,scroll.panel,ypos,parcheckbox);
                        ypos = ypos + bdControlVector.rowh; 
                    case 3
                        % construct a matrix widget
                        bdControlMatrix(this,'pardef',parindx,scroll.panel,ypos,parcheckbox);
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
                'Value',this.sys.halt, ...
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
            this.ui_halt.Value = this.sys.halt;                

            if this.sys.halt
                % change the solver stats to red
                this.ui_nsteps.ForegroundColor = 'r';
                this.ui_nfailed.ForegroundColor = 'r';
                this.ui_nfevals.ForegroundColor = 'r';
                this.ui_cputime.ForegroundColor = 'r';
                this.ui_progress.ForegroundColor = 'r';
                %this.ui_cputime.String = '0.00s';
                %this.ui_progress.String = '-';
                
                % disable the RUN button
                this.ui_run.Enable = 'off';
                this.ui_run.ForegroundColor = 'r';
            else
                % change the solver stats to black
                this.ui_nsteps.ForegroundColor = 'k';
                this.ui_nfailed.ForegroundColor = 'k';
                this.ui_nfevals.ForegroundColor = 'k';
                this.ui_cputime.ForegroundColor = 'k';
                this.ui_progress.ForegroundColor = 'k';

                % enable the RUN button
                this.ui_run.Enable = 'on';
                this.ui_run.ForegroundColor = 'k';
            end
            
            % refresh the EVOLVE button
            this.ui_evolve.Value = this.sys.evolve;
            
            if this.sys.evolve
                % Hide the RAND button
                this.ui_rand.Visible = 'off';
                % Show the RUN button
                this.ui_run.Visible = 'on';
            else
                % Show the RAND button
                this.ui_rand.Visible = 'on';
                % Hide the RUN button
                this.ui_run.Visible = 'off';
            end
                
            % refresh the PERTURB button
            this.ui_perturb.Value = this.sys.perturb;
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
            if this.sys.halt
                return
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
                        
            % clear the last warning message
            lastwarn('');            
            oldwarn = warning('off','backtrace');                

            % if the EVOLVE button is ON then ....
            if this.sys.evolve
                % Update the initial conditions and compute the new solution
                this.Evolve();
            else
                % Compute the solution without altering the initial conditions
                this.Solve();
            end
            
            % restore the old warning state
            warning(oldwarn.state,'backtrace'); 

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
            
            % Hold the SDEnoise if the HOLD button is 'on'
            switch this.solvertype
                case 'sdesolver'
                    if this.ui_hold.Value==1 && isempty(this.sys.sdeoption.randn) 
                         dt = this.sol.x(2) - this.sol.x(1);
                         this.sys.sdeoption.randn = this.sol.dW ./ sqrt(dt);
                    end
            end
            
            % notify all listeners that a redraw is required
            notify(this,'redraw');
            
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
        
        % Returns a uniform pertubation that is suitable for the initial
        % conditions. The amp parameter dictates the amplitude of the
        % perturbation relative to [lo hi] limits of each variable.
        function P0 = Perturbation(this,amp)
            % Initialise P0 to the same size as Y0. The contents do not matter.
            P0 = bdGetValues(this.sys.vardef);

            % for each entry in sys.vardef
            for indx = 1:numel(this.sys.vardef)
                % determine the limits of the variable
                lo = this.sys.vardef(indx).lim(1);
                hi = this.sys.vardef(indx).lim(2);
                
                % get the indices of the variable in Y0
                solindx = this.sys.vardef(indx).solindx;

                % determine the size of the variable in Y0
                solsize = [numel(solindx) 1];

                % create the perturbation as a uniform random value scaled by 'amp'
                P0(solindx) = amp*(hi-lo)*(rand(solsize)-0.5);
            end            
        end
        
        % Call the solver 
        function Solve(this)
            % Get the initial conditions
            Y0 = bdGetValues(this.sys.vardef);
            
            % If the perturb button state is ON then ...
            if this.sys.perturb
                % Add 5 percent perturbation to the initial conditions
                Y0 = Y0 + this.Perturbation(0.05);           
            end         

            % Get the system parameters as a cell array
            parcell = {this.sys.pardef.value};
            
            % The type of the solver function determines how we apply it 
            switch this.solvertype
                case 'odesolver'
                    % case of an ODE solver (eg ode45)
                    odeoption = odeset(this.sys.odeoption, 'OutputFcn',@this.odeOutputFcn, 'OutputSel',[]);
                    this.sol = this.solver(this.sys.odefun, ...
                        this.sys.tspan, ...
                        Y0, ...
                        odeoption, ...
                        parcell{:});

                case 'ddesolver'
                    % case of a DDE solver (eg dde23)
                    ddeoption = ddeset(this.sys.ddeoption, 'OutputFcn',@this.odeOutputFcn, 'OutputSel',[]);
                    lags = bdGetValues(this.sys.lagdef); 
                    this.sol = this.solver(this.sys.ddefun, ...
                        lags, ...
                        Y0, ...
                        this.sys.tspan, ...
                        ddeoption, ...
                        parcell{:});

                case 'sdesolver'
                    % case of an SDE solver
                    sdeoption = this.sys.sdeoption;
                    sdeoption.OutputFcn = @this.odeOutputFcn;
                    sdeoption.OutputSel = [];      
                    this.sol = this.solver(this.sys.sdeF, ...
                        this.sys.sdeG, ...
                        this.sys.tspan, ...
                        Y0, ...
                        sdeoption, ...
                        parcell{:});
            end
            
            % Update the indices of the non-transient steps of sol.x
            % Note: tindx can be all zeros in cases where the solver
            % terminated early because of blow-out or tolerance failures.
            this.tindx = (this.sol.x >= this.sys.tval) & min(isfinite(this.sol.y));
        end

        % Call the solver using the final state of the previous run
        % as the initial conditions for the current run
        function Evolve(this)
            % copy the final states in sol.y to the initial conditions in sys.vardef
            if ~isempty(this.sol.y)
                if all(isfinite(this.sol.y(:,end)))
                    for indx=1:numel(this.sys.vardef)
                        valsize = size(this.sys.vardef(indx).value);        % size of the variable value
                        solindx = this.sys.vardef(indx).solindx;            % corresponding indices of the variable in sol
                        val = reshape( this.sol.y(solindx,end), valsize);   % the final value in the solution ...
                        this.sys.vardef(indx).value = val;                  % ... replaces the initial value    
                    end                
                    % notify the vardef widgets to refresh themselves
                    notify(this,'vardef');
                else
                    % warn about Infs and NaNs
                    oldwarn = warning('off','backtrace');                
                    warning('bdGUI:Overflow','The computed solution exceeds machine limits.');
                    warning(oldwarn.state,'backtrace'); 
                    
                    % turn the EVOLVE button OFF
                    this.sys.evolve = false;
                    
                    % turn the HALT button ON
                    this.sys.halt = true;
                    
                    % notify the widgets to refresh themselves
                    notify(this,'refresh');
                end
            end
            
            % Get the system parameters as a cell array
            parcell = {this.sys.pardef.value};

            % The type of the solver function determines how we apply it 
            switch this.solvertype
                case 'odesolver'
                    % Case of an ODE solver (eg ode45)
                    odeoption = odeset(this.sys.odeoption, 'OutputFcn',@this.odeOutputFcn, 'OutputSel',[]);

                    % Get the initial conditions
                    Y0 = bdGetValues(this.sys.vardef);
            
                    % If the perturb button state is ON then ...
                    if this.sys.perturb
                        % Add 5 percent perturbation to the initial conditions
                        Y0 = Y0 + this.Perturbation(0.05);           
                    end         

                    % Call the solver
                    this.sol = this.solver(this.sys.odefun, ...
                        this.sys.tspan, ...
                        Y0, ...
                        odeoption, ...
                        parcell{:});

                case 'ddesolver'
                    % Case of a DDE solver (eg dde23)
                    ddeoption = ddeset(this.sys.ddeoption, 'OutputFcn',@this.odeOutputFcn, 'OutputSel',[]);

                    % Get the time lag parameters
                    lags = bdGetValues(this.sys.lagdef); 
                    
                    % Call the solver using the values of the previous run as history.
                    % The History function perturbs the historical data if required.
                    this.sol = this.solver(this.sys.ddefun, ...
                        lags, ...
                        @(t,varargin) this.History(t), ...
                        this.sys.tspan, ...
                        ddeoption, ...
                        parcell{:});

                case 'sdesolver'
                    % Case of an SDE solver (eg sdeEM)
                    sdeoption = this.sys.sdeoption;
                    sdeoption.OutputFcn = @this.odeOutputFcn;
                    sdeoption.OutputSel = [];      
                    
                    % Get the initial conditions
                    Y0 = bdGetValues(this.sys.vardef);
            
                    % If the perturb button state is ON then ...
                    if this.sys.perturb
                        % Add 5 percent perturbation to the initial conditions
                        Y0 = Y0 + this.Perturbation(0.05);           
                    end         

                    % Call the solver
                    this.sol = this.solver(this.sys.sdeF, ...
                        this.sys.sdeG, ...
                        this.sys.tspan, ...
                        Y0, ...
                        sdeoption, ...
                        parcell{:});
            end
            
            % Update the indices of the non-transient steps of sol.x
            % Note: tindx can be all zeros in cases where the solver
            % terminated early because of blow-out or tolerance failures.
            this.tindx = (this.sol.x >= this.sys.tval) & min(isfinite(this.sol.y));
        end
                
        % History function used by dde23 solver when the EVOLVE button is active
        function Y0 = History(this,t)
            %disp('bdControl.History');
            
            % if there is no previous solution then ...
            if ~isfield(this.sol,'solver')
                % Use the initial conditions from sys.vardef as constant history
                Y0 = bdGetValues(this.sys.vardef);
            
                % If the perturb button state is ON then ...
                if this.sys.perturb
                    % Add 5 percent perturbation to the initial conditions
                    Y0 = Y0 + this.Perturbation(0.05);           
                end         
            else
                % Use the previous solution as history for the current solution.

                % Shift historical time for this run into the time span of the previous run
                t = t + this.sol.x(end) - this.sol.x(1);

                % Truncate time lags that lie beyond the time domain of the current solution
                if t < this.sol.x(1)
                    oldwarn = warning('off','backtrace');                
                    warning('bdGUI:HistoryTruncation','Time span is too small to accomodate all time lags.');
                    warning(oldwarn.state,'backtrace');                
                    t = this.sol.x(1);
                end
            
                % interpolate the historical value
                Y0 = deval(this.sol,t);

                % If the perturb button state is ON then ...
                if this.sys.perturb
                    % Add 5 percent perturbation to the historical value
                    Y0 = Y0 + this.Perturbation(0.05);           
                end         
            end
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
                   if this.sys.halt~=1
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
            status = this.sys.halt;
        end
        
        % Callback for the noise HOLD button (SDE only)
        function HoldCallback(this,holdbutton)
            if holdbutton.Value==1
                dt = this.sol.x(2) - this.sol.x(1);
                this.sys.sdeoption.randn = this.sol.dW ./ sqrt(dt);
            else
                this.sys.sdeoption.randn = [];
            end
        end
        
        % Callback for the HALT button
        function HaltCallback(this,haltbutton)
            this.sys.halt = haltbutton.Value;
            if this.sys.halt
                notify(this,'refresh');             % notify widgets to refresh themselves
                notify(this,'redraw');
            else
                notify(this,'refresh');             % notify widgets to refresh themselves
                notify(this,'recompute');           % recompute the new solution
            end
        end
    
        % Callback for the EVOLVE button
        function EvolveCallback(this,evobutton)
            this.sys.evolve = evobutton.Value;
            if this.sys.evolve
                notify(this,'refresh');             % notify widgets to refresh themselves
                notify(this,'recompute');           % recompute the new solution
            else
                notify(this,'refresh');             % notify widgets to refresh themselves
             end
         end
    
        % Callback for the PERTURB button
        function PerturbCallback(this,button)
            this.sys.perturb = button.Value;
            if this.sys.perturb
                notify(this,'refresh');             % notify widgets to refresh themselves
                notify(this,'recompute');           % recompute the new solution
            else
                notify(this,'refresh');             % notify widgets to refresh themselves
             end
         end
    
        % Callback for the RAND button
        function RandCallback(this,button)
            %disp('bdControl.RandCallback()');
            
            % for each entry in sys.vardef
            for indx = 1:numel(this.sys.vardef)
                % determine the limits of the random values
                lo = this.sys.vardef(indx).lim(1);
                hi = this.sys.vardef(indx).lim(2);

                % update the control panel.
                valsize = size(this.sys.vardef(indx).value);
                this.sys.vardef(indx).value = (hi-lo)*rand(valsize) + lo;
            end

            % notify all widgets sys.vardef has changed
            notify(this,'vardef');

            % tell the solver to recompute the solution
            notify(this,'recompute');
        end
                
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


