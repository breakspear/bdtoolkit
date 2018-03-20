classdef bdSurrogate < bdPanel
    %bdSurrogate  Display panel for the Surrogate data transform.
    %   This display panel constructs phase-randomized surrogate data from
    %   simulated data by adding random numbers to the phase component of
    %   the data using an amplitude-adjusted algorithm. 
    %   
    %AUTHORS
    %  Stewart Heitmann (2017b,2017c,2018a)
    %  Incorporating original code from Michael Breakspear.

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
        title = 'Surrogate';
    end    
    
    properties (Access=public)
        t               % equi-spaced time points
        y               % time series of selected variable(s)
        ysurr           % surrogate version of y
    end
    
    properties (Access=private) 
        ax1             % handle to plot 1 axes
        ax2             % handle to plot 2 axes
        tranmenu        % handle to TRANSIENTS menu item
        markmenu        % handle to MARKERS menu item        
        gridmenu        % handle to GRID menu item
%        holdmenu        % handle to HOLD menu item
        submenu         % handle to subpanel selector menu item
        listener        % handle to our listener object
    end
    
    methods
        function this = bdSurrogate(tabgroup,control)
             % Construct a new Surrogate Panel in the given tabgroup

            % initialise the base class (specifically this.menu and this.tab)
            this@bdPanel(tabgroup);
            
            % assign default values to missing options in sys.panels.bdSurrogate
            control.sys.panels.bdSurrogate = bdSurrogate.syscheck(control.sys);
            
            % configure the pull-down menu
            this.menu.Label = control.sys.panels.bdSurrogate.title;
            this.InitCalibrateMenu(control);
            this.InitTransientsMenu(control);
            this.InitMarkerMenu(control);
            this.InitGridMenu(control);
            %this.InitHoldMenu(control);
            this.InitExportMenu(control);
            this.InitCloseMenu(control);
            
            % configure the panel graphics
            this.tab.Title = control.sys.panels.bdSurrogate.title;
            this.InitSubpanel(control);

            % listen to the control panel for redraw events
            this.listener = addlistener(control,'redraw',@(~,~) this.redraw(control));    
        end
        
        function delete(this)
            % Destructor
            delete(this.listener)
        end
         
        function redraw(this,control)
            %disp('bdSurrogate.redraw()')
            
            % get the details of the variable currently selected variable
            varname  = this.submenu.UserData.xxxname;          % generic name of variable
            varlabel = this.submenu.UserData.label;            % plot label for selected variable
            varindx  = this.submenu.UserData.xxxindx;          % index of selected variable in sys.vardef
            valindx  = this.submenu.UserData.valindx;          % indices of selected entries in sys.vardef.value
            solindx  = control.sys.vardef(varindx).solindx;    % indices of selected entries in sol
            ylim     = control.sys.vardef(varindx).lim;        % axis limits of the selected variable
           % tval     = control.sys.tval;                       % current time slider value
            
            % clear the axes
            cla(this.ax1);
            cla(this.ax2);
            
            % set the y-axes limits
            this.ax1.YLim = ylim + [-1e-4 +1e-4];
            this.ax2.YLim = ylim + [-1e-4 +1e-4];

            % if the TRANSIENT menu is enabled then  ...
            switch this.tranmenu.Checked
                case 'on'
                    % set the x-axes limits to the full time span
                    this.ax1.XLim = control.sys.tspan + [-1e-4 0];
                    this.ax2.XLim = control.sys.tspan + [-1e-4 0];

                    % use all time steps in sol.x
                    tindx = true(size(control.tindx));  % logical indices of all time steps in this.t
                    
                case 'off'
                    % limit the x-axes to the non-transient part of the time domain
                    this.ax1.XLim = [control.sys.tval control.sys.tspan(2)] + [-1e-4 0];
                    this.ax2.XLim = [control.sys.tval control.sys.tspan(2)] + [-1e-4 0];
                    
                    % use only the non-transient time steps in sol.x
                    tindx = control.tindx;              % logical indices of the non-transient time steps
            end
            
            % Our method asumes equi-spaced time steps but many of our
            % solvers generate variable time steps.  So we interpolate
            % the time-series to ensure equi-spaced time steps.
            % How we interpolate depends on the type of solver.
            switch control.solvertype
                case 'sde'
                    % The current SDE solvers only used fixed time steps
                    % so we can avoid interpolation altogether and simply
                    % use the solver's own time steps.
                    this.t = control.sol.x(tindx);

                otherwise
                    % We use interpolation for all other solvers to ensure
                    % that our correlation used fixed-size time steps.
                    % We choose the number of time steps of the interpolant
                    % to be similar to the number of steps chosen by the
                    % solver. This avoids over-sampling and under-sampling.
                    tt = control.sol.x(tindx);
                    this.t = linspace(tt(1),tt(end),numel(tt));                        
            end
            
            % interpolate the trajectory onto  equi-spaced time points 
            this.y = bdEval(control.sol,this.t,solindx);

            % compute the surrogate data
            this.ysurr = bdSurrogate.ampsurr(this.y);

            % update the ylabels
            ylabel(this.ax1, varlabel);
            ylabel(this.ax2, varlabel);

            % Plot the original signal in ax1
            % ... with the background traces in grey
            plot(this.ax1, this.t, this.y, 'color',[0.75 0.75 0.75], 'HitTest','off');              
            % ... and variable of interest in black
            plot(this.ax1, this.t, this.y(valindx,:), 'color','k', 'Linewidth',1.5);
            
            % Plot the surrogate signal in ax2
            % ... with the background traces in grey
            plot(this.ax2, this.t, this.ysurr, 'color',[0.75 0.75 0.75], 'HitTest','off');              
            % ... and variable of interest in black
            plot(this.ax2, this.t, this.ysurr(valindx,:), 'color','k', 'Linewidth',1.5);
            
            % if the TRANSIENT menu is enabled then  ...
            switch this.tranmenu.Checked
                case 'on'
                   % plot the pentagram marker (upper plot)
                    plot(this.ax1, this.t(1), this.y(valindx,1), ...
                        'Marker','p', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',10 , ...
                        'Visible',this.markmenu.Checked);

                    % plot the pentagram marker (lower plot)
                    plot(this.ax2, this.t(1), this.ysurr(valindx,1), ...
                        'Marker','p', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',10 , ...
                        'Visible',this.markmenu.Checked);

                case 'off'
                    % plot the circle marker (upper plot)
                    plot(this.ax1, this.t(1), this.y(valindx,1), ...
                        'Marker','o', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',6, ...
                        'Visible',this.markmenu.Checked);

                    % plot the circle marker (lower plot)
                    plot(this.ax2, this.t(1), this.ysurr(valindx,1), ...
                        'Marker','o', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',6, ...
                        'Visible',this.markmenu.Checked);
            end
            
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
                % if the TRANSIENT menu is checked then ...
                switch this.tranmenu.Checked
                    case 'on'
                        % adjust the limits to fit all of the data
                        tindx = true(size(control.tindx));
                    case 'off'
                        % adjust the limits to fit the non-transient data only
                        tindx = control.tindx;
                end

                % find the limits of the original data
                lo = min(min(this.y));
                hi = max(max(this.y));
                
                % get the index of the plot variable in sys.vardef
                varindx = this.submenu.UserData.xxxindx;
                
                % adjust the limits of the plot variables
                control.sys.vardef(varindx).lim = bdPanel.RoundLim(lo,hi);

                % refresh the vardef control widgets
                notify(control,'vardef');
                
                % redraw all panels (because the new limits apply to all panels)
                notify(control,'redraw');
            end

        end
        
        % Initiliase the TRANISENTS menu item
        function InitTransientsMenu(this,control)
            % get the default transient menu setting from sys.panels
            if control.sys.panels.bdSurrogate.transients
                checkflag = 'on';
            else
                checkflag = 'off';
            end

            % construct the menu item
            this.tranmenu = uimenu(this.menu, ...
                'Label','Transients', ...
                'Checked',checkflag, ...
                'Callback', @TranMenuCallback);

            % Menu callback function
            function TranMenuCallback(menuitem,~)
                switch menuitem.Checked
                    case 'on'
                        menuitem.Checked='off';
                    case 'off'
                        menuitem.Checked='on';
                end
                % redraw this panel only
                this.redraw(control);
            end
        end
        
        % Initiliase the MARKERS menu item
        function InitMarkerMenu(this,control)
            % get the marker menu setting from sys.panels
            if control.sys.panels.bdSurrogate.markers
                checkflag = 'on';
            else
                checkflag = 'off';
            end

            % construct the menu item
            this.markmenu = uimenu(this.menu, ...
                'Label','Markers', ...
                'Checked',checkflag, ...
                'Callback', @MarkMenuCallback);

            % Menu callback function
            function MarkMenuCallback(menuitem,~)
                switch menuitem.Checked
                    case 'on'
                        menuitem.Checked='off';
                    case 'off'
                        menuitem.Checked='on';
                end
                % redraw this panel only
                this.redraw(control);
            end
        end       

        % Initiliase the GRID menu item
        function InitGridMenu(this,control)
            % get the default grid menu setting from sys.panels
            if control.sys.panels.bdSurrogate.grid
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
        
        % Initialise the HOLD menu item
        function InitHoldMenu(this,control)
             % get the hold menu setting from sys.panels options
            if control.sys.panels.bdSurrogate.hold
                holdcheck = 'on';
            else
                holdcheck = 'off';
            end
            
            % construct the menu item
            this.holdmenu = uimenu(this.menu, ...
                'Label','Hold', ...
                'Checked',holdcheck, ...
                'Callback', @HoldMenuCallback );

            % Menu callback function
            function HoldMenuCallback(menuitem,~)
                switch menuitem.Checked
                    case 'on'
                        menuitem.Checked='off';
                    case 'off'
                        menuitem.Checked='on';
                end
                % redraw this panel
                this.redraw(control);
            end
        end
        
        % Initialise the EXPORT menu item
        function InitExportMenu(this,~)
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
                
                % Copy the plot data to the new figure
                ax1new = copyobj(this.ax1,fig);
                ax1new.OuterPosition = [0 0.51 1 0.47];
                ax2new = copyobj(this.ax2,fig);
                ax2new.OuterPosition = [0 0.03 1 0.47];

                % Allow the user to hit everything in ax1new
                objs = findobj(ax1new,'-property', 'HitTest');
                set(objs,'HitTest','on');
                
                % Allow the user to hit everything in ax2new
                objs = findobj(ax2new,'-property', 'HitTest');
                set(objs,'HitTest','on');
                
                % Change mouse cursor to arrow
                set(fig,'Pointer','arrow');
                drawnow;
            end
        end

        % Initialise the CLOSE menu item
        function InitCloseMenu(this,~)
            % construct the menu item
            uimenu(this.menu, ...
                   'Label','Close', ...
                   'Callback',@(~,~) this.close());
        end
        
        % Initialise the subpanel
        function InitSubpanel(this,control)
            % construct the subpanel
            [this.ax1,cmenu,spanel] = bdPanel.Subpanel(this.tab,[0 0 1 1],[0 0.51 1 0.47]);
            xlabel(this.ax1,'time');
            title(this.ax1,'Original');

            % construct the second axis
            this.ax2 = axes('Parent',spanel, ...
                'Units','normal', ...
                'OuterPosition',[0 0.03 1 0.47], ...
                'NextPlot','add', ...
                'FontSize',12, ...
                'Box','on');
            xlabel(this.ax2,'time');
            title(this.ax2,'Surrogate');

            % construct a selector menu comprising items from sys.vardef
            this.submenu = bdPanel.SelectorMenuFull(cmenu, ...
                control.sys.vardef, ...
                @callback, ...
                'off', 'mb1',1,1);
            
            % Callback function for the subpanel selector menu
            function callback(menuitem,~)
                % check 'on' the selected menu item and check 'off' all others
                bdPanel.SelectorCheckItem(menuitem);
                % update our handle to the selected menu item
                this.submenu = menuitem;
                % redraw the panel
                this.redraw(control);
            end
        end
        
        
    end
    
    
    methods (Static)
        
        % Check the sys.panels struct
        function syspanel = syscheck(sys)
            % Default panel settings
            syspanel.title = 'Surrogate';
            syspanel.transients = false;            
            syspanel.markers = true;
            syspanel.grid = false;
            %syspanel.hold = false;
            
            % Nothing more to do if sys.panels.bdSurrogate is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdSurrogate')
                return;
            end
            
            % sys.panels.bdSurrogate.title
            if isfield(sys.panels.bdSurrogate,'title')
                syspanel.title = sys.panels.bdSurrogate.title;
            end
            
            % sys.panels.bdSurrogate.transients
            if isfield(sys.panels.bdSurrogate,'transients')
                syspanel.transients = sys.panels.bdSurrogate.transients;
            end
            
            % sys.panels.bdSurrogate.markers
            if isfield(sys.panels.bdSurrogate,'markers')
                syspanel.markers = sys.panels.bdSurrogate.markers;
            end
            
            % sys.panels.bdSurrogate.grid
            if isfield(sys.panels.bdSurrogate,'grid')
                syspanel.grid = sys.panels.bdSurrogate.grid;
            end
            
          %  % sys.panels.bdSurrogate.hold
          %  if isfield(sys.panels.bdSurrogate,'hold')
          %      syspanel.hold = sys.panels.bdSurrogate.hold;
          %  end
        end
        
        
        % Creates surrogate multichannel data, by adding random numbers
        % to phase component of all channel data, using amplitude adjusted algorithm
        function y = ampsurr(x)
            [r,c] = size(x);
            if r < c
                x = x.';   % make each column a timeseries
            end;
            [n,cc] = size(x);
            m = 2^nextpow2(n);
            yy=zeros(n,cc);
            for i=1:cc    %create a gaussian timeseries with the same rank-order of x
               z=zeros(n,3); gs=sortrows(randn(n,1),1);
               z(:,1)=x(:,i); z(:,2)=[1:n]'; z=sortrows(z,1);
               z(:,3)=gs; z=sortrows(z,2); yy(:,i)=z(:,3);
            end
            phsrnd=zeros(m,cc);
            phsrnd(2:m/2,1)=rand(m/2-1,1)*2*pi; phsrnd(m/2+2:m,1)=-phsrnd(m/2:-1:2,1);
            for i=2:cc 
                phsrnd(:,i)=phsrnd(:,1);
            end
            m = 2^nextpow2(n);
            xx = fft(real(yy),m);
            phsrnd=zeros(m,cc);
            phsrnd(2:m/2,1)=rand(m/2-1,1)*2*pi; phsrnd(m/2+2:m,1)=-phsrnd(m/2:-1:2,1);
            for i=2:cc 
                phsrnd(:,i)=phsrnd(:,1);
            end
            xx = xx.*exp(phsrnd*sqrt(-1));
            xx = ifft(xx,m);
            xx = real(xx(1:n,:));
            y=zeros(n,cc);
            for i=1:cc    %reorder original timeseries to have the same rank-order of xx
               z=zeros(n,3); yst=sortrows(x(:,i));
               z(:,1)=xx(:,i); z(:,2)=[1:n]'; z=sortrows(z,1);
               z(:,3)=yst; z=sortrows(z,2); y(:,i)=z(:,3);
            end
            if r < c
               y = y.';
            end
            y=real(y);    %small imag. component created by rounding error
        end
        
    end
    
end
