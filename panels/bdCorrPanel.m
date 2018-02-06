classdef bdCorrPanel < bdPanel
    %bdCorrPanel - Display panel for plotting linear correlations in bdGUI.
    %   Displays the linear correlation matrix for the system variables.
    %
    %AUTHORS
    %  Stewart Heitmann (2016a,2017a,2017c,2018a)

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
        title = 'Correlation';
    end    

    properties
        t               % Time points at which the data was sampled (1 x t)
        Y               % The sampled data points (n x t)
        R               % Matrix of correlation cooefficients (n x n)
    end
    
    properties (Access=private) 
        ax              % Handle to the plot axes
        tranmenu        % handle to TRANSIENTS menu item
        submenu         % handle to subpanel selector menu item
        img             % handle to the image object
        listener        % handle to listener
    end
    
    methods
        function this = bdCorrPanel(tabgroup,control)
            % Construct a new Correlation Panel in the given tabgroup

            % initialise the base class (specifically this.menu and this.tab)
            this@bdPanel(tabgroup);

            % assign default values to missing options in sys.panels.bdTimePortrait
            control.sys.panels.bdCorrPanel = bdCorrPanel.syscheck(control.sys);

            % configure the pull-down menu
            this.menu.Label = control.sys.panels.bdCorrPanel.title;
            this.InitCalibrateMenu(control);
            this.InitTransientsMenu(control);
            this.InitExportMenu(control);
            this.InitCloseMenu(control);

            % configure the panel graphics
            this.tab.Title = control.sys.panels.bdCorrPanel.title;
            this.InitSubpanel(control);

            % listen to the control panel for redraw events
            this.listener = addlistener(control,'redraw',@(~,~) this.redraw(control));    
        end
        
        function delete(this)
            % Destructor
            delete(this.listener)
        end
        
        function redraw(this,control)
            %disp('bdCorrPanel.redraw()')
                        
            % get the details of the currently selected dynamic variable
            varname  = this.submenu.UserData.xxxname;           % generic name of variable
            varlabel = this.submenu.UserData.label;             % plot label for selected variable
            varindx  = this.submenu.UserData.xxxindx;           % index of selected variable in sys.vardef
            solindx  = control.sys.vardef(varindx).solindx;     % indices of selected entries in sol

            % if the TRANSIENT menu is enabled then  ...
            switch this.tranmenu.Checked
                case 'on'
                    % use all time steps in sol.x
                    tindx = true(size(control.tindx));  % logical indices of all time steps in this.t

                    % update the title
                    title(this.ax,['Correlation Coefficients for ',varname,' (including transients)']);

                case 'off'
                    % use only the non-transient time steps in sol.x
                    tindx = control.tindx;              % logical indices of the non-transient time steps

                    % update the title
                    title(this.ax,['Correlation Coefficients for ',varname,' (excluding transients)']);
            end

            % Cross-correlation assumes equi-spaced time steps. However
            % many of our solver are auto-steppers, so we must interpolate
            % the solution to ensure that our time steps are equi-spaced.
            % How we interpolate depends on the type of solver.
            switch control.solvertype
                case 'sde'
                    % At this time, all SDE solvers only fixed time steps
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
                        
            % interpolate the solution
            this.Y = bdEval(control.sol,this.t,solindx);
            
            % compute the correlation coefficients
            this.R = corrcoef(this.Y');
                
            % update the cross-correlation matrix (image)
            this.img.CData = this.R;
            xlim(this.ax,[0.5 size(this.R,1)+0.5]);
            ylim(this.ax,[0.5 size(this.R,1)+0.5]);  
    
            % clean up the Tick labels if n is small.
            n = size(this.R,1);
            if n<=20
                set(this.ax,'XTick',1:n);
                set(this.ax,'YTick',1:n);
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
                % adjust the color axis limits of the correlation martix
                hi = max(this.R(:));    % Get the maximum value in R
                lo = min(this.R(:));    % Get the minimum value in R
                clim = bdPanel.RoundLim(lo - 1e-4, hi + 1e-4);
                caxis(this.ax, clim);
            end

        end
        
        % Initiliase the TRANISENTS menu item
        function InitTransientsMenu(this,control)
            % get the default transient menu setting from sys.panels
            if control.sys.panels.bdCorrPanel.transients
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

                % Allow the user to hit everything in axnew
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
    
        % Initialise the subpanel
        function InitSubpanel(this,control)
            % construct the subpanel
            [this.ax,cmenu] = bdPanel.Subpanel(this.tab,[0 0 1 1],[0 0 1 1]);
            xlabel(this.ax,'node');
            ylabel(this.ax,'node');
            
            % construct an empty image
            this.img = imagesc([],'Parent',this.ax);
            axis(this.ax,'ij');

            % add the colorbar
            colorbar('peer',this.ax);
            
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
   
    end
    
    methods (Static)
        
        % Check the sys.panels struct
        function syspanel = syscheck(sys)
            % Default panel settings
            syspanel.title = bdCorrPanel.title;
            syspanel.transients = false;
            
            % Nothing more to do if sys.panels.bdCorrPanel is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdCorrPanel')
                return;
            end
            
            % sys.panels.bdCorrPanel.title
            if isfield(sys.panels.bdCorrPanel,'title')
                syspanel.title = sys.panels.bdCorrPanel.title;
            end
            
            % sys.panels.bdCorrPanel.transients
            if isfield(sys.panels.bdCorrPanel,'transients')
                syspanel.transients = sys.panels.bdCorrPanel.transients;
            end

        end
        
    end
end

