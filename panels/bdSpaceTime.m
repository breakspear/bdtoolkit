classdef bdSpaceTime < bdPanel
    %bdSpaceTime Brain Dynamics GUI panel for space-time plots.
    %  The Space-Time panel plots the time trace of vector-valued dynamic 
    %  variables side-by-side as if they were arranged spatially.
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
        title = 'Space-Time';
    end    

    properties
        t               % Time steps of the solution (1 x t)
        y               % Matrix of space-time trajectories (n x t)
    end
    
    properties (Access=private)
        ax              % Handle to the plot axes
        pc              % handle to the pcolor surface object
        mk              % handle to the vertical time marker
        tranmenu        % handle to TRANSIENTS menu item
        markmenu        % handle to MARKERS menu item
        blendmenu       % handle to BLEND menu item
        submenu         % handle to subpanel selector menu item
        listener        % handle to our listener object
    end
    
    methods
        
        function this = bdSpaceTime(tabgroup,control)
            % Construct a new Space-Time Portrait in the given tabgroup

            % initialise the base class (specifically this.menu and this.tab)
            this@bdPanel(tabgroup);
            
            % assign default values to missing options in sys.panels.bdSpaceTime
            control.sys.panels.bdSpaceTime = bdSpaceTime.syscheck(control.sys);

            % configure the pull-down menu
            this.menu.Label = control.sys.panels.bdSpaceTime.title;
            this.InitCalibrateMenu(control);
            this.InitViewMenu(control);
            this.InitTransientsMenu(control);
            this.InitMarkerMenu(control);
            this.InitBlendMenu(control);
            this.InitClipMenu(control);
            this.InitExportMenu(control);
            this.InitCloseMenu(control);

            % configure the panel graphics
            this.tab.Title = control.sys.panels.bdSpaceTime.title;
            this.InitSubpanel(control);
            
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
                        % adjust the limits using all time steps
                        tindx = true(size(control.tindx));
                    case 'off'
                        % adjust the limits using the non-transient data only
                        tindx = control.tindx;
                end

                % adjust the limits to fit the data
                lo = min(min(this.y(:,tindx)));
                hi = max(max(this.y(:,tindx)));
                varindx = this.submenu.UserData.xxxindx;
                control.sys.vardef(varindx).lim = bdPanel.RoundLim(lo,hi);

                % refresh the vardef control widgets
                notify(control,'vardef');
                
                % redraw all panels (because the new limits apply to all panels)
                notify(control,'redraw');
            end

        end
        
        % Initialise the 3D VIEW menu item
        function InitViewMenu(this,control)
            % construct the menu item
            uimenu(this.menu, ...
                'Label','3D View', ...
                'Checked','off', ...
                'Callback', @ViewMenuCallback);

            % Menu callback function
            function ViewMenuCallback(menuitem,~)
                switch menuitem.Checked
                    case 'on'
                        % 3D menu state goes from 'on' to 'off'
                        menuitem.Checked='off';
                        this.ax.View = [0 90];
                    case 'off'
                        % 3D menu state goes from 'off' to 'on'
                        menuitem.Checked='on';
                        this.ax.View = [45 45];
                end
            end
        end

        % Initiliase the TRANISENTS menu item
        function InitTransientsMenu(this,control)
            % get the default transient menu setting from sys.panels
            if control.sys.panels.bdSpaceTime.transients
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
            if control.sys.panels.bdSpaceTime.markers
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
                        menuitem.Checked = 'off';
                        this.mk.Visible = 'off';
                    case 'off'
                        menuitem.Checked = 'on';
                        this.mk.Visible = 'on';
                end
            end
        end

        % Initiliase the BLEND menu item
        function InitBlendMenu(this,control)
            % get the default blend menu setting from sys.panels
            if control.sys.panels.bdSpaceTime.blend
                blendcheck = 'on';
            else
                blendcheck = 'off';
            end

            % construct the menu item
            this.blendmenu = uimenu(this.menu, ...
                'Label','Blend', ...
                'Checked',blendcheck, ...
                'Callback', @BlendMenuCallback);

            % Menu callback function
            function BlendMenuCallback(menuitem,~)
                % toggle the FaceColor and menu state
                switch menuitem.Checked
                    case 'on'
                        menuitem.Checked='off';
                        this.pc.FaceColor = 'flat';
                    case 'off'
                        menuitem.Checked='on';
                        this.pc.FaceColor = 'interp';
                end
            end
        end

        % Initiliase the CLIPPING menu item
        function InitClipMenu(this,control)
            % get the default clipping menu setting from sys.panels
            if control.sys.panels.bdSpaceTime.clipping
                clipcheck = 'on';
            else
                clipcheck = 'off';
            end

            % construct the menu item
            this.blendmenu = uimenu(this.menu, ...
                'Label','Clipping', ...
                'Checked',clipcheck, ...
                'Callback', @ClipMenuCallback);

            % Menu callback function
            function ClipMenuCallback(menuitem,~)
                % toggle the surface clipping and the menu state
                switch menuitem.Checked
                    case 'on'
                        menuitem.Checked='off';
                        this.pc.Clipping = 'off';
                    case 'off'
                        menuitem.Checked='on';
                        this.pc.Clipping = 'on';
                end
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
                axnew = copyobj(this.ax,fig);
                axnew.OuterPosition = [0 0 1 1];
                
                % Add a colorbar to the new axis
                colorbar('peer',axnew);

                % Allow the user to hit everything in the new axes
                objs = findobj(axnew,'-property', 'HitTest');
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
        function InitSubpanel(this,control)
            % construct the subpanel
            [this.ax,cmenu] = bdPanel.Subpanel(this.tab,[0 0 1 1],[0 0 1 1]);
            xlabel(this.ax,'time');
            ylabel(this.ax,'space (node)');
            
            % construct the pcolor surface object (using zero data)
            this.pc = pcolor(this.ax,zeros(2,2));
            this.pc.LineStyle = 'none';
            this.pc.Clipping = 'off';

            % add the colorbar
            colorbar('peer',this.ax);
            
            % construct the vertical line marker object
            this.mk = plot3([0 0 0 0 0],[0 1 1 0 0], [0 0 1 1 0], 'Color','k', 'LineStyle','--', 'LineWidth',1.5);

            % construct a selector menu comprising items from sys.vardef
            this.submenu = bdPanel.SelectorMenu(cmenu, ...
                control.sys.vardef, ...
                @callback, ...
                'off', 'mb1',1);
            
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
   
        % Redraw the data plots
        function redraw(this,control)
            %disp('bdSpaceTime.redraw()')
            
            % get the details of the currently selected dynamic variable
            varname  = this.submenu.UserData.xxxname;           % generic name of variable
            varlabel = this.submenu.UserData.label;             % plot label for selected variable
            varindx  = this.submenu.UserData.xxxindx;           % index of selected variable in sys.vardef
            solindx  = control.sys.vardef(varindx).solindx;     % indices of selected entries in sol
            varlim   = control.sys.vardef(varindx).lim;         % axis limits of the selected variable

            % get the solution data (including the transient part)
            this.t = control.sol.x;
            this.y = control.sol.y(solindx,:);
            
            % get the number of rows in the solution
            n = size(this.y,1);

            % if the TRANSIENT menu is enabled then  ...
            switch this.tranmenu.Checked
                case 'on'
                    % use all time steps
                    tindx = true(size(control.tindx));  % logical indices of all time steps in this.t
                    tval = control.sys.tval;            % start of the non-transient time window
                    tend = control.sys.tspan(2);        % end of simulation time window
                    tlim = control.sys.tspan;           % limit of plot time
                case 'off'
                    % use only the non-transient time steps
                    tindx = control.tindx;              % logical indices of the non-transient time steps
                    tval = control.sys.tval;            % start of the non-transient time window
                    tend = control.sys.tspan(2);        % end of simulation time window
                    tlim = [tval tend];                 % limit of plot time
            end
            
            % update the pcolor surface data
            this.pc.XData = this.t(tindx);
            this.pc.YData = 1:n+1;
            this.pc.CData = this.y([1:n,1],tindx);
            this.pc.ZData = this.y([1:n,1],tindx);

            % set the axes limits
            this.ax.YLim = [1 n+1];
            this.ax.XLim = tlim + [-1e-6 +1e-6];
            this.ax.ZLim =  varlim + [-1e-6 1e-6];

            % set the color axis limit to match the Z-axis limit
            caxis(this.ax, this.ax.ZLim);
            
            % update the time marker
            this.mk.YData = [1    n+1  n+1  1    1 ];
            this.mk.XData = [tval tval tval tval tval];
            this.mk.ZData = [varlim(1) varlim(1) varlim(2) varlim(2) varlim(1)];

            % update the title
            title(this.ax,varname);
            
            % update the zlabel
            zlabel(this.ax, varname);
        end

    end
    
    methods (Static)
        
        function syspanel = syscheck(sys)
            % Assign default values to missing fields in sys.panels.bdSpaceTime

            % Default panel settings
            syspanel.title = bdSpaceTime.title;
            syspanel.transients = true;
            syspanel.markers = true;
            syspanel.blend = false;
            syspanel.clipping = false;
            
            % Nothing more to do if sys.panels.bdSpaceTime is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdSpaceTime')
                return;
            end
            
            % sys.panels.bdSpaceTime.title
            if isfield(sys.panels.bdSpaceTime,'title')
                syspanel.title = sys.panels.bdSpaceTime.title;
            end
            
            % sys.panels.bdSpaceTime.transients
            if isfield(sys.panels.bdSpaceTime,'transients')
                syspanel.transients = sys.panels.bdSpaceTime.transients;
            end
            
            % sys.panels.bdSpaceTime.markers
            if isfield(sys.panels.bdSpaceTime,'markers')
                syspanel.markers = sys.panels.bdSpaceTime.markers;
            end
            
            % sys.panels.bdSpaceTime.blend
            if isfield(sys.panels.bdSpaceTime,'blend')
                syspanel.grid = sys.panels.bdSpaceTime.blend;
            end
            
            % sys.panels.bdSpaceTime.clipping
            if isfield(sys.panels.bdSpaceTime,'clipping')
                syspanel.grid = sys.panels.bdSpaceTime.clipping;
            end           
        end
        
    end
    
end
