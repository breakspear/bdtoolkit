classdef bdTimePortrait < bdPanel
    %bdTimePortrait Display panel for plotting time series data in bdGUI.
    %  The panel includes an upper and lower axes which independently plot
    %  the time traces of selected variables.
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
        ax1             % Handle to the upper plot axes
        ax2             % Handle to the lower plot axes
        t               % Time steps of the solution (1 x t)
        y1              % Trajectories of the upper plot (n1 x t)
        y2              % Trajectories of the lower plot (n2 x t)
    end
    
    properties (Access=private)
        tranmenu        % handle to TRANSIENTS menu item
        markmenu        % handle to MARKERS menu item
        pointmenu       % handle to POINTS menu item
        gridmenu        % handle to GRID menu item
        holdmenu        % handle to HOLD menu item
        submenu1        % handle to subpanel1 (upper plot) selector menu item
        submenu2        % handle to subpanel2 (lower plot) selector menu item
        listener        % handle to our listener object
    end
    
    methods
        
        function this = bdTimePortrait(tabgroup,control)
            % Construct a new Time Portrait in the given tabgroup

            % initialise the base class (specifically this.menu and this.tab)
            this@bdPanel(tabgroup);
            
            % assign default values to missing options in sys.panels.bdTimePortrait
            control.sys.panels.bdTimePortrait = bdTimePortrait.syscheck(control.sys);

            % configure the pull-down menu
            this.menu.Text = control.sys.panels.bdTimePortrait.title;
            this.InitCalibrateMenu(control);
            this.InitTransientsMenu(control);
            this.InitMarkerMenu(control);
            this.InitPointsMenu(control);
            this.InitGridMenu(control);
            this.InitHoldMenu(control);
            this.InitExportMenu(control);
            this.InitCloseMenu(control);

            % configure the panel graphics
            this.tab.Title = control.sys.panels.bdTimePortrait.title;
            this.InitSubpanel1(control);
            this.InitSubpanel2(control);
            
            % listen to the control panel for redraw events
            this.listener = listener(control,'redraw',@(~,~) this.redraw(control));    
        end
        
    end
    
    methods (Access=private)
        
        % Initialise the CALIBRATE menu item
        function InitCalibrateMenu(this,control)
            % construct the menu item
            uimenu(this.menu, ...
               'Text','Calibrate Axes', ...
                'Callback', @CalibrateMenuCallback );
            
            % Menu callback function
            function CalibrateMenuCallback(~,~)
                % if the TRANSIENT menu is checked then ...
                switch this.tranmenu.Checked
                    case 'on'
                        % adjust the limits to fit all of the data
                        tindx = true(size(control.tindx));
                    case 'off'
                        % adjust the x-limits to fit the non-transient data only
                        tindx = control.tindx;
                end

                % adjust the limits to the visible data (upper plot)
                lo = min(this.y1(tindx));
                hi = max(this.y1(tindx));
                varindx1 = this.submenu1.UserData.xxxindx;
                control.sys.vardef(varindx1).lim = bdPanel.RoundLim(lo,hi);

                % adjust the limits to the visible data (lower plot)
                lo = min(this.y2(tindx));
                hi = max(this.y2(tindx));
                varindx2 = this.submenu2.UserData.xxxindx;
                control.sys.vardef(varindx2).lim = bdPanel.RoundLim(lo,hi);
                
                % refresh the control widgets
                notify(control,'refresh');
                
                % redraw all panels (because the new limits apply to all panels)
                notify(control,'redraw');
            end

        end
        
        % Initiliase the TRANISENTS menu item
        function InitTransientsMenu(this,control)
            % get the default transient menu setting from sys.panels
            if control.sys.panels.bdTimePortrait.transients
                checkflag = 'on';
            else
                checkflag = 'off';
            end

            % construct the menu item
            this.tranmenu = uimenu(this.menu, ...
                'Text','Transients', ...
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
            if control.sys.panels.bdTimePortrait.markers
                checkflag = 'on';
            else
                checkflag = 'off';
            end

            % construct the menu item
            this.markmenu = uimenu(this.menu, ...
                'Text','Markers', ...
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
        
        % Initiliase the DISCRETE POINTS menu item
        function InitPointsMenu(this,control)
            % get the points menu setting from sys.panels
            if control.sys.panels.bdTimePortrait.points
                checkflag = 'on';
            else
                checkflag = 'off';
            end

            % construct the menu item
            this.pointmenu = uimenu(this.menu, ...
                'Text','Discrete Points', ...
                'Checked',checkflag, ...
                'Callback', @PointsMenuCallback);

            % Menu callback function
            function PointsMenuCallback(menuitem,~)
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
            if control.sys.panels.bdTimePortrait.grid
                gridcheck = 'on';
            else
                gridcheck = 'off';
            end

            % construct the menu item
            this.gridmenu = uimenu(this.menu, ...
                'Text','Grid', ...
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
                grid(this.ax1, menuitem.Checked);
                grid(this.ax2, menuitem.Checked);
            end
        end
        
        % Initialise the HOLD menu item
        function InitHoldMenu(this,control)
             % get the hold menu setting from sys.panels options
            if control.sys.panels.bdTimePortrait.hold
                holdcheck = 'on';
            else
                holdcheck = 'off';
            end
            
            % construct the menu item
            this.holdmenu = uimenu(this.menu, ...
                'Text','Hold', ...
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
               'Text','Export Figure', ...
               'Callback',@callback);
           
            function callback(~,~)
                % Construct a new figure
                fig = figure();    
                
                % Change mouse cursor to hourglass
                set(fig,'Pointer','watch');
                drawnow;
                
                % Copy the plot data to the new figure
                ax1new = copyobj(this.ax1,fig);
                ax1new.OuterPosition = [0 0.525 1 0.45];
                ax2new = copyobj(this.ax2,fig);
                ax2new.OuterPosition = [0 0.025 1 0.45];

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
                   'Text','Close', ...
                   'Callback',@(~,~) this.close());
        end
        
        % Initialise the upper panel
        function InitSubpanel1(this,control)
            % construct the subpanel
            [this.ax1,cmenu] = bdPanel.Subpanel(this.tab,[0 0.5 1 0.5],[0 0.05 1 0.9]);
            xlabel(this.ax1,'time');
            
            % construct a selector menu comprising items from sys.vardef
            this.submenu1 = bdPanel.SelectorMenuFull(cmenu, ...
                control.sys.vardef, ...
                @callback1, ...
                'off', 'mb1',1,1);
            
            % Callback function for the subpanel selector menu
            function callback1(menuitem,~)
                % check 'on' the selected menu item and check 'off' all others
                bdPanel.SelectorCheckItem(menuitem);
                % update our handle to the selected menu item
                this.submenu1 = menuitem;
                % redraw the panel
                this.redraw(control);
            end
        end
        
        % Initialise the lower panel
        function InitSubpanel2(this,control)
            % construct the subpanel
            [this.ax2,cmenu] = bdPanel.Subpanel(this.tab,[0 0.0 1 0.5],[0 0.05 1 0.9]);
            xlabel(this.ax2,'time');
            
            % construct a selector menu comprising items from sys.vardef
            this.submenu2 = bdPanel.SelectorMenuFull(cmenu, ...
                control.sys.vardef, ...
                @callback2, ...
                'off', 'mb2',min(2,numel(control.sys.vardef)),1);

            % Callback function for the subpanel selector menu
            function callback2(menuitem,~)
                % check 'on' the selected menu item and check 'off' all others
                bdPanel.SelectorCheckItem(menuitem);
                % update our handle to the selected menu item
                this.submenu2 = menuitem;
                % redraw the panel
                this.redraw(control);
            end
        end
   
        % Redraw the data plots
        function redraw(this,control)
            %disp('bdTimePortrait.redraw()')
            
            % get the details of the variable currently selected in the upper panel menu
            varname1  = this.submenu1.UserData.xxxname;          % generic name of variable
            varlabel1 = this.submenu1.UserData.label;            % plot label for selected variable
            varindx1  = this.submenu1.UserData.xxxindx;          % index of selected variable in sys.vardef
            valindx1  = this.submenu1.UserData.valindx;          % indices of selected entries in sys.vardef.value
            solindx1  = control.sys.vardef(varindx1).solindx;    % indices of selected entries in sol
            ylim1     = control.sys.vardef(varindx1).lim;        % axis limits of the selected variable
            
            % get the details of the variable currently selected in the lower panel menu
            varname2  = this.submenu2.UserData.xxxname;          % generic name of variable
            varlabel2 = this.submenu2.UserData.label;            % plot label for selected variable
            varindx2  = this.submenu2.UserData.xxxindx;          % index of selected variable in sys.vardef
            valindx2  = this.submenu2.UserData.valindx;          % indices of selected entries in sys.vardef.value
            solindx2  = control.sys.vardef(varindx2).solindx;    % indices of selected entries in sol
            ylim2     = control.sys.vardef(varindx2).lim;        % axis limits of the selected variable

            % set the y-axes limits
            this.ax1.YLim = ylim1 + [-1e-6 +1e-6];
            this.ax2.YLim = ylim2 + [-1e-6 +1e-6];
            
            % if the TRANSIENT menu is enabled then  ...
            switch this.tranmenu.Checked
                case 'on'
                    % set the x-axes limits to the full time span
                    this.ax1.XLim = control.sys.tspan + [-1e-6 0];
                    this.ax2.XLim = control.sys.tspan + [-1e-6 0];
                case 'off'
                    % limit the x-axes to the non-transient part of the time domain
                    this.ax1.XLim = [control.sys.tval control.sys.tspan(2)] + [-1e-6 0];
                    this.ax2.XLim = [control.sys.tval control.sys.tspan(2)] + [-1e-6 0];
            end
            
            % if the POINTS menu is checked then ...
            switch this.pointmenu.Checked
                case 'on'
                    % set our plot style to discrete points
                    markerstyle = '.';
                    linestyle = 'none';
                case 'off'
                    % set our plot style to continuous lines
                    markerstyle = 'none';
                    linestyle = '-';
            end
            
            % if 'hold' menu is checked then ...
            switch this.holdmenu.Checked
                case 'on'
                    % Change existing plots to thin grey lines 
                    set( findobj(this.ax1,'Type','Line'), 'LineWidth',0.5, 'Color',[0.75 0.75 0.75]);               
                    set( findobj(this.ax2,'Type','Line'), 'LineWidth',0.5, 'Color',[0.75 0.75 0.75]);               
                case 'off'
                    % Clear the plot axis
                    cla(this.ax1);
                    cla(this.ax2);
            end          
           
            % get the solution data (including the transient part)
            this.t = control.sol.x;
            this.y1 = control.sol.y(solindx1,:);
            this.y2 = control.sol.y(solindx2,:);

            % plot the background traces as thin grey lines
            plot(this.ax1, this.t, this.y1', 'color',[0.75 0.75 0.75], 'HitTest','off');
            plot(this.ax2, this.t, this.y2', 'color',[0.75 0.75 0.75], 'HitTest','off');

            % get the indices of the non-transient time steps in this.t
            tindx = control.tindx;      % logical indices of the non-transient time steps
            indxt = find(tindx>0,1);    % numerical index of the first non-transient step (may be empty)

            % (re)plot the non-transient part of the variable of interest as a heavy black line
            plot(this.ax1, this.t(tindx), this.y1(valindx1,tindx), 'color','k', 'Marker',markerstyle, 'LineStyle',linestyle, 'Linewidth',1.5);
            plot(this.ax2, this.t(tindx), this.y2(valindx2,tindx), 'color','k', 'Marker',markerstyle, 'LineStyle',linestyle, 'Linewidth',1.5);
            
            % if the MARKERS menu is checked then ...
            switch this.markmenu.Checked
                case 'on'
                    % mark the initial conditions with a pentagram
                    plot(this.ax1, this.t(1), this.y1(valindx1,1), 'Marker','p', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',10);
                    plot(this.ax2, this.t(1), this.y2(valindx2,1), 'Marker','p', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',10);

                    % mark the start of the non-transient trajectory with an open circle
                    if ~isempty(indxt)
                        plot(this.ax1, this.t(indxt), this.y1(valindx1,indxt), 'Marker','o', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',6);
                        plot(this.ax2, this.t(indxt), this.y2(valindx2,indxt), 'Marker','o', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',6);
                    end
            end
            
            % update the titles
            title(this.ax1,varname1);
            title(this.ax2,varname2);
            
            % update the ylabels
            ylabel(this.ax1, varlabel1);
            ylabel(this.ax2, varlabel2);
        end

    end
    
    methods (Static)
        
        function syspanel = syscheck(sys)
            % Assign default values to missing fields in sys.panels.bdTimePortrait

            % Default panel settings
            syspanel.title = 'Time Portrait';
            syspanel.transients = true;
            syspanel.markers = true;
            syspanel.points = false;
            syspanel.grid = false;
            syspanel.hold = false;
            
            % Nothing more to do if sys.panels.bdTimePortrait is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdTimePortrait')
                return;
            end
            
            % sys.panels.bdTimePortrait.title
            if isfield(sys.panels.bdTimePortrait,'title')
                syspanel.title = sys.panels.bdTimePortrait.title;
            end
            
            % sys.panels.bdTimePortrait.transients
            if isfield(sys.panels.bdTimePortrait,'transients')
                syspanel.transients = sys.panels.bdTimePortrait.transients;
            end
            
            % sys.panels.bdTimePortrait.markers
            if isfield(sys.panels.bdTimePortrait,'markers')
                syspanel.markers = sys.panels.bdTimePortrait.markers;
            end
            
            % sys.panels.bdTimePortrait.points
            if isfield(sys.panels.bdTimePortrait,'points')
                syspanel.points = sys.panels.bdTimePortrait.points;
            end
            
            % sys.panels.bdTimePortrait.grid
            if isfield(sys.panels.bdTimePortrait,'grid')
                syspanel.grid = sys.panels.bdTimePortrait.grid;
            end
            
            % sys.panels.bdTimePortrait.hold
            if isfield(sys.panels.bdTimePortrait,'hold')
                syspanel.hold = sys.panels.bdTimePortrait.hold;
            end
            
        end
        
    end
    
end
