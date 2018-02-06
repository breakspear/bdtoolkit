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

    properties (Constant)
        title = 'Time Portrait';
    end    

    properties
        t               % Time steps of the solution (1 x t)
        y1              % Trajectories of the upper plot (n1 x t)
        y2              % Trajectories of the lower plot (n2 x t)
    end
    
    properties (Access=private)
        ax1             % Handle to the upper plot axes
        ax2             % Handle to the lower plot axes
        modmenu         % handle to MODULO AXES menu item
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
            this.menu.Label = control.sys.panels.bdTimePortrait.title;
            this.InitCalibrateMenu(control);
            this.InitModuloMenu(control);
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
            this.listener = addlistener(control,'redraw',@(~,~) this.redraw(control));    
        end
        
        function delete(this)
            % Destructor
            delete(this.listener)
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

                % find the limits of the upper and lower plots
                lo1 = min(min(this.y1(:,tindx)));
                lo2 = min(min(this.y2(:,tindx)));
                hi1 = max(max(this.y1(:,tindx)));
                hi2 = max(max(this.y2(:,tindx)));
                
                % get the indices of the upper and lower variables in sys.vardef
                varindx1 = this.submenu1.UserData.xxxindx;
                varindx2 = this.submenu2.UserData.xxxindx;

                % special case: we may be plotting different elements
                % of the same vector-valued variable in both plot axes.
                if varindx1==varindx2
                    lo1 = min(lo1,lo2);  lo2 = lo1;
                    hi1 = max(hi1,hi2);  hi2 = hi1;
                end
                
                % adjust the limits of the upper and lower plot variables
                control.sys.vardef(varindx1).lim = bdPanel.RoundLim(lo1,hi1);
                control.sys.vardef(varindx2).lim = bdPanel.RoundLim(lo2,hi2);

                % refresh the vardef control widgets
                %notify(control,'refresh');
                notify(control,'vardef');
                
                % redraw all panels (because the new limits apply to all panels)
                notify(control,'redraw');
            end

        end
        
        % Initiliase the MODULO AXES menu item
        function InitModuloMenu(this,control)
            % get the mod menu setting from sys.panels
            if control.sys.panels.bdTimePortrait.mod
                checkflag = 'on';
            else
                checkflag = 'off';
            end

            % construct the menu item
            this.modmenu = uimenu(this.menu, ...
                'Label','Modulo Axes', ...
                'Checked',checkflag, ...
                'Callback', @ModuloMenuCallback);

            % Menu callback function
            function ModuloMenuCallback(menuitem,~)
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
        
        % Initiliase the TRANSIENTS menu item
        function InitTransientsMenu(this,control)
            % get the default transient menu setting from sys.panels
            if control.sys.panels.bdTimePortrait.transients
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
            if control.sys.panels.bdTimePortrait.markers
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
                'Label','Discrete Points', ...
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
                   'Label','Close', ...
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
            this.ax1.YLim = ylim1 + [-1e-4 +1e-4];
            this.ax2.YLim = ylim2 + [-1e-4 +1e-4];
            
            % if the TRANSIENT menu is enabled then  ...
            switch this.tranmenu.Checked
                case 'on'
                    % set the x-axes limits to the full time span
                    this.ax1.XLim = control.sys.tspan + [-1e-4 0];
                    this.ax2.XLim = control.sys.tspan + [-1e-4 0];
                case 'off'
                    % limit the x-axes to the non-transient part of the time domain
                    this.ax1.XLim = [control.sys.tval control.sys.tspan(2)] + [-1e-4 0];
                    this.ax2.XLim = [control.sys.tval control.sys.tspan(2)] + [-1e-4 0];
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
                    % Remove the foreground lines and markers only
                    delete( findobj(this.ax1,'Tag','Fgnd') );
                    delete( findobj(this.ax2,'Tag','Fgnd') );
                case 'off'
                    % Clear everything from the axes
                    cla(this.ax1);
                    cla(this.ax2);
            end          
           
            % get the solution data (including the transient part)
            this.t = control.sol.x;
            this.y1 = control.sol.y(solindx1,:);
            this.y2 = control.sol.y(solindx2,:);

            % get the indices of the non-transient time steps in this.t
            tindx = control.tindx;      % logical indices of the non-transient time steps
            indxt = find(tindx>0,1);    % numerical index of the first non-transient step (may be empty)

            % if the MODULO AXES menu is checked then ...
            switch this.modmenu.Checked
                case 'on'
                    % Modulo the plot lines into two separate bands (to avoid sawtooth effect)
                    [y1a,y1b] = mod2band(this.y1,ylim1);
                    [y2a,y2b] = mod2band(this.y2,ylim2);
                    
                    % plot the background traces as thin grey lines
                    plot(this.ax1, this.t, [y1a',y1b'], 'color',[0.75 0.75 0.75], 'HitTest','off');
                    plot(this.ax2, this.t, [y2a',y2b'], 'color',[0.75 0.75 0.75], 'HitTest','off');

                    % (re)plot the non-transient part of the variable of interest as a heavy black line
                    plot(this.ax1, this.t(tindx), [y1a(valindx1,tindx); y1b(valindx1,tindx)], 'color','k', 'Marker',markerstyle, 'LineStyle',linestyle, 'Linewidth',1.5);
                    plot(this.ax2, this.t(tindx), [y2a(valindx2,tindx); y2b(valindx2,tindx)], 'color','k', 'Marker',markerstyle, 'LineStyle',linestyle, 'Linewidth',1.5);
                    
                    % plot the pentagram marker (upper plot)
                    plot(this.ax1, this.t(1), mod1band(this.y1(valindx1,1),ylim1), ...
                        'Marker','p', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',10 , ...
                        'Visible',this.markmenu.Checked, 'Tag','Fgnd');

                    % plot the pentagram marker (lower plot)
                    plot(this.ax2, this.t(1), mod1band(this.y2(valindx2,1),ylim2), ...
                        'Marker','p', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',10 , ...
                        'Visible',this.markmenu.Checked, 'Tag','Fgnd');
                    
                    % plot the circle marker (upper plot)
                    plot(this.ax1, this.t(indxt), mod1band(this.y1(valindx1,indxt),ylim1), ...
                        'Marker','o', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',6, ...
                        'Visible',this.markmenu.Checked, 'Tag','Fgnd');

                    % plot the circle marker (lower plot)
                    plot(this.ax2, this.t(indxt), mod1band(this.y2(valindx2,indxt),ylim2), ...
                        'Marker','o', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',6, ...
                        'Visible',this.markmenu.Checked, 'Tag','Fgnd');
                    
                case 'notworkingyet'
                    % plot the background traces as thin grey lines
                    modplot(this.ax1, ...
                        this.t', this.y1', ...
                        control.sys.tspan, ylim1, ...
                        'color',[0.75 0.75 0.75], ...
                        'HitTest','off');
                    modplot(this.ax2, ...
                        this.t', this.y2', ...
                        control.sys.tspan, ylim2, ...
                        'color',[0.75 0.75 0.75], ...
                        'HitTest','off');

                    % (re)plot the non-transient part of the variable of interest as a heavy black line
                    modplot(this.ax1, ...
                        this.t(tindx)', this.y1(valindx1,tindx)', ...
                        control.sys.tspan, ylim1, ...
                        'color','k', ...
                        'Marker',markerstyle, ...
                        'LineStyle',linestyle, ...
                        'Linewidth',1.5);
                    modplot(this.ax2, this.t(tindx)', this.y2(valindx2,tindx)', ...
                        control.sys.tspan, ylim2, ...
                        'color','k', ...
                        'Marker',markerstyle, ...
                        'LineStyle',linestyle, ...
                        'Linewidth',1.5);
                    
                    % plot the pentagram marker (upper plot)
                    modplot(this.ax1, ...
                        this.t(1)', this.y1(valindx1,1)', ...
                        control.sys.tspan, ylim1, ...                        
                        'Marker','p', ...
                        'Color','k', ...
                        'MarkerFaceColor','y', ...
                        'MarkerSize',10 , ...
                        'Visible',this.markmenu.Checked, ...
                        'Tag','Fgnd');

                    % plot the pentagram marker (lower plot)
                    modplot(this.ax2, ...
                        this.t(1)', this.y2(valindx2,1)', ...
                        control.sys.tspan, ylim2, ...                        
                        'Marker','p', ...
                        'Color','k', ...
                        'MarkerFaceColor','y', ...
                        'MarkerSize',10 , ...
                        'Visible',this.markmenu.Checked, ...
                        'Tag','Fgnd');
                    
                    % plot the circle marker (upper plot)
                    modplot(this.ax1, ...
                        this.t(indxt)', this.y1(valindx1,indxt)', ...
                        control.sys.tspan, ylim1, ...                        
                        'Marker','o', ...
                        'Color','k', ...
                        'MarkerFaceColor','y', ...
                        'MarkerSize',6, ...
                        'Visible',this.markmenu.Checked, ...
                        'Tag','Fgnd');

                    % plot the circle marker (lower plot)
                    modplot(this.ax2, ...
                        this.t(indxt)', this.y2(valindx2,indxt)', ...
                        control.sys.tspan, ylim2, ...                        
                        'Marker','o', ...
                        'Color','k', ...
                        'MarkerFaceColor','y', ...
                        'MarkerSize',6, ...
                        'Visible',this.markmenu.Checked, ...
                        'Tag','Fgnd');

                case 'off'
                    % plot the background traces as thin grey lines
                    plot(this.ax1, this.t, this.y1', 'color',[0.75 0.75 0.75], 'HitTest','off');
                    plot(this.ax2, this.t, this.y2', 'color',[0.75 0.75 0.75], 'HitTest','off');

                    % (re)plot the non-transient part of the variable of interest as a heavy black line
                    plot(this.ax1, this.t(tindx), this.y1(valindx1,tindx), 'color','k', 'Marker',markerstyle, 'LineStyle',linestyle, 'Linewidth',1.5);
                    plot(this.ax2, this.t(tindx), this.y2(valindx2,tindx), 'color','k', 'Marker',markerstyle, 'LineStyle',linestyle, 'Linewidth',1.5);
 
                   % plot the pentagram marker (upper plot)
                    plot(this.ax1, this.t(1), this.y1(valindx1,1), ...
                        'Marker','p', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',10 , ...
                        'Visible',this.markmenu.Checked, 'Tag','Fgnd');
                    
                   % plot the pentagram marker (lower plot)
                    plot(this.ax2, this.t(1), this.y2(valindx2,1), ...
                        'Marker','p', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',10 , ...
                        'Visible',this.markmenu.Checked, 'Tag','Fgnd');
                    
                    % plot the circle marker (upper plot)
                    plot(this.ax1, this.t(indxt), this.y1(valindx1,indxt), ...
                        'Marker','o', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',6, ...
                        'Visible',this.markmenu.Checked, 'Tag','Fgnd');

                    % plot the circle marker (lower plot)
                    plot(this.ax2, this.t(indxt), this.y2(valindx2,indxt), ...
                        'Marker','o', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',6, ...
                        'Visible',this.markmenu.Checked, 'Tag','Fgnd');
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
            syspanel.title = bdTimePortrait.title;
            syspanel.mod = false;
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
            
            % sys.panels.bdTimePortrait.mod
            if isfield(sys.panels.bdTimePortrait,'mod')
                syspanel.mod = sys.panels.bdTimePortrait.mod;
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


function modplot(ax,y1,y2,lim1,lim2,varargin)
    % compute the spans of each limit
    span1 = lim1(2) - lim1(1);
    span2 = lim2(2) - lim2(1);

    % modulo both trajectories
    y1 = mod(y1-lim1(1), span1) + lim1(1);
    y2 = mod(y2-lim2(1), span2) + lim2(1);
    
    % find the discontinuities in each
    d1 = 2*abs(diff(y1)) > span1;
    d2 = 2*abs(diff(y2)) > span2;
    
    % combine the discontinuities within y1 and y2
    d1 = max(d1,[],2);
    d2 = max(d2,[],2);

    % combine the discontinuities between y1 and y2
    d3 = max(d1,d2);
    
    % convert the logical indexes into numerical indexes
    di = find([d3;1])';

    % plot each segment separately
    i1 = 1;
    for i2 = di
        plot(ax, y1(i1:i2,:), y2(i1:i2,:), varargin{:});
        i1=i2+1;
    end

end

function yband = mod1band(y,ylim)
    yband = mod(y-ylim(1), ylim(2)-ylim(1)) + ylim(1);
end

function [yband1,yband2] = mod2band(y,ylim)
    ylo = ylim(1);
    yhi = ylim(2);
    yspan = yhi - ylo;
    yband1 =  mod(y-ylo, 2*yspan) + ylo;
    yband2 = yband1 - yspan;
    yband1(yband1<ylo | yband1>yhi) = NaN;
    yband2(yband2<ylo | yband2>yhi) = NaN;
end
