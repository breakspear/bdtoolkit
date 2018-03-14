classdef bdHilbert < bdPanel
    %bdHilbert  Brain Dynamics Toolbox panel for the Hilbert transfrom.
    %   This display panel applies the Hilbert transform to the output
    %   of a dynamical system.
    %
    %AUTHORS
    %  Stewart Heitmann (2017b,2018a)

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
        title = 'Hilbert';
    end    

    properties (Access=public)
        t               % equi-spaced time points
        y               % time series of the selected variable(s)
        h               % Hilbert transform of the time series
        p               % Hilbert phases of the time series
    end
    
    properties (Access=private)
        ax1             % handle to the upper axes
        ax2             % handle to the lower axes
        tranmenu        % handle to TRANSIENTS menu item
        markmenu        % handle to MARKERS menu item        
        relmenu         % handle to RELATIVE PHASE menu item        
        submenu         % handle to subpanel selector menu item
        listener        % handle to listener
        cylinder        % handle to cylinder mesh
        cylinderX       % cylinder wire frame (x-coord)
        cylinderY       % cylinder wire frame (y-coord)
        cylinderZ       % cylinder wire frame (z-coord)
    end
    
    methods
        function this = bdHilbert(tabgroup,control)
             % Construct a new Hilbert Panel in the given tabgroup

            % initialise the base class (specifically this.menu and this.tab)
            this@bdPanel(tabgroup);
            
            % assign default values to missing options in sys.panels.bdHilbert
            control.sys.panels.bdHilbert = bdHilbert.syscheck(control.sys);

            % construct the cylinder frame
            [this.cylinderY,this.cylinderZ,this.cylinderX] = cylinder(0.95*ones(1,31),31);
            
            % configure the pull-down menu
            this.menu.Label = control.sys.panels.bdHilbert.title;
            this.InitCalibrateMenu(control);
            this.InitTransientsMenu(control);
            this.InitMarkerMenu(control);
            this.InitRelPhaseMenu(control);
            this.InitExportMenu(control);
            this.InitCloseMenu(control);
            
            % configure the panel graphics
            this.tab.Title = control.sys.panels.bdHilbert.title;
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
        
        % Initialise the TRANISENTS menu item
        function InitTransientsMenu(this,control)
            % get the default transient menu setting from sys.panels
            if control.sys.panels.bdHilbert.transients
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
        
        % Initialise the MARKERS menu item
        function InitMarkerMenu(this,control)
            % get the marker menu setting from sys.panels
            if control.sys.panels.bdHilbert.markers
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
       
        % Initialise the RELATIVE PHASE menu item
        function InitRelPhaseMenu(this,control)
            % get the relative menu setting from sys.panels
            if control.sys.panels.bdHilbert.relphase
                checkflag = 'on';
            else
                checkflag = 'off';
            end

            % construct the menu item
            this.relmenu = uimenu(this.menu, ...
                'Label','Relative Phase', ...
                'Checked',checkflag, ...
                'Callback', @RelMenuCallback);

            % Menu callback function
            function RelMenuCallback(menuitem,~)
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
            title(this.ax1,'Time Series');

            % construct the second axis
            this.ax2 = axes('Parent',spanel, ...
                'Units','normal', ...
                'OuterPosition',[0 0.01 1 0.47], ...
                'NextPlot','add', ...
            ...    'PlotBoxAspectRatioMode','manual', ...
            ...    'PlotBoxAspectRatio',[3 1 1], ...
                'YDir','reverse', ...
                'XLim',[-1.1 1.1], ...
                'YLim',[-1.1 1.1], ...
                'YTick', [], ...
                'ZTick', [], ...                
                'FontSize',12, ...
                'Box','on');
            xlabel(this.ax2,'time');

            % Constuct the cylinder for the second axis
            edgecolor = 0.8*[1 1 1];
            facecolor = 1.0*[1 1 1];
            edgealpha = 0.7;
            facealpha = 0.7;
            t0 = control.sys.tspan(1);
            t1 = control.sys.tspan(2);
            this.cylinder = mesh(this.ax2, ...
                this.cylinderX.*(t1-t0) + t0, ...
                this.cylinderY, ...
                this.cylinderZ, ...
                'EdgeColor',edgecolor,'FaceColor',facecolor, 'FaceAlpha',facealpha, 'EdgeAlpha',edgealpha);

            % Set the initial view angle
            view(this.ax2,-5,0);

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
        
        function redraw(this,control)
            %disp('bdHilbert.redraw()')

            % get the details of the variable currently selected variable
            varname  = this.submenu.UserData.xxxname;          % generic name of variable
            varlabel = this.submenu.UserData.label;            % plot label for selected variable
            varindx  = this.submenu.UserData.xxxindx;          % index of selected variable in sys.vardef
            valindx  = this.submenu.UserData.valindx;          % indices of selected entries in sys.vardef.value
            solindx  = control.sys.vardef(varindx).solindx;    % indices of selected entries in sol
            ylim     = control.sys.vardef(varindx).lim;        % axis limits of the selected variable

            % Ensure we are using equi-spaced time points
            switch control.solvertype
                case 'sde'
                    % The SDE solvers use fixed time steps already
                    % so we simply use the solver's own time steps.
                    this.t = control.sol.x;

                otherwise
                    % Use interpolation to obtain fixed time steps.
                    % We choose the number of time steps of the interpolant
                    % to be similar to the number of steps chosen by the
                    % solver. This avoids over-sampling and under-sampling.
                    this.t = linspace(control.sol.x(1),control.sol.x(end),numel(control.sol.x));                        
            end
            
            % get the indices of the non-transient time steps in this.t
            tindx = (this.t >= control.sys.tval);  % logical indices of the non-transient time steps
            indxt = find(tindx>0,1);            % numerical index of the first non-transient step (may be empty)

            % interpolate the trajectory using the equi-spaced time points 
            this.y = bdEval(control.sol,this.t,solindx);
            
            % compute the Hilbert transform and its phase angles
            [this.h,this.p] = bdHilbert.hilbert(this.y);
            
            % clear the top axes
            cla(this.ax1);
            
            % clear parts of the bottom axes
            delete( findobj(this.ax2,'Tag','fgnd') );

            % if the RELATIVE PHASE menu is enabled then  ...
            switch this.relmenu.Checked
                case 'on'
                    % adjust the phase angles of the all variables relative to the first variable.
                    
                    % repeat the first row of this.p as a matrix
                    p2 = this.p(ones(1,size(this.p,1)),:);

                    % subtract the first row from all other rows
                    this.p = this.p - p2;
                    
                    % title
                    title(this.ax2,['Phase of ' varlabel ' relative to ' varname '_1']);

                case 'off'
                    % title
                    title(this.ax2,['Phase of ' varlabel]);
            end

            % set the y-axes limits on the upper plot
            this.ax1.YLim = ylim + [-1e-4 +1e-4];

            % set the y- and z-axes limits on the lower plot
            this.ax2.YLim = [-1.1 +1.1];
            this.ax2.ZLim = [-1.1 +1.1];
                    
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
            
            % update the ylabels
            ylabel(this.ax1, varlabel);

            % Plot the original signal in ax1
            % ... with the background traces in grey
            plot(this.ax1, this.t, this.y, 'color',[0.75 0.75 0.75], 'HitTest','off');              
            % ... and variable of interest in black
            plot(this.ax1, this.t(tindx), this.y(valindx,tindx), 'color','k', 'Linewidth',1.5);

            % rescale the cylinder mesh to fit the simulation time span
            t0 = control.sys.tspan(1);
            t1 = control.sys.tspan(2);
            this.cylinder.XData = this.cylinderX.*(t1-t0) + t0;
            
            % Plot the Hilbert phase superimposed on the cylinder
            sinp = sin(this.p);
            cosp = cos(this.p);   
            % ... with the background traces in grey
            plot3(this.ax2, this.t, 0.975*cosp, 0.975*sinp, 'color',[0.5 0.5 0.5], 'HitTest','off', 'Tag','fgnd');
            % ... and variable of interest in black
            plot3(this.ax2, this.t(tindx), cosp(valindx,tindx), sinp(valindx,tindx), 'color','k', 'Linewidth',1.5, 'Tag','fgnd');
            
            % if the TRANSIENT menu is enabled then  ...
            if strcmp(this.tranmenu.Checked,'on')                            
                % plot the pentagram marker on the first axes
                plot(this.ax1, this.t(1), this.y(valindx,1), ...
                    'Marker','p', ...
                    'Color','k', ...
                    'MarkerFaceColor','y', ...
                    'MarkerSize',10 , ...
                    'Visible',this.markmenu.Checked, ...
                    'Tag','fgnd');

                % plot the pentagram marker on the second axes
                plot3(this.ax2, this.t(1), cosp(valindx,1), sinp(valindx,1), ...
                    'Marker','p', ...
                    'Color','k', ...
                    'MarkerFaceColor','y', ...
                    'MarkerSize',10 , ...
                    'Visible',this.markmenu.Checked, ...
                    'Tag','fgnd');
            end

            if ~isempty(indxt)
                % plot the circle marker on teh first axes
                plot(this.ax1, this.t(indxt), this.y(valindx,indxt), ...
                    'Marker','o', ...
                    'Color','k', ...
                    'MarkerFaceColor','y', ...
                    'MarkerSize',6, ...
                    'Visible',this.markmenu.Checked, ...
                    'Tag','fgnd');

                % plot the circle marker on the second axes
                plot3(this.ax2, this.t(indxt), cosp(valindx,indxt), sinp(valindx,indxt), ...
                    'Marker','o', ...
                    'Color','k', ...
                    'MarkerFaceColor','y', ...
                    'MarkerSize',6 , ...
                    'Visible',this.markmenu.Checked, ...
                    'Tag','fgnd');
            end
            
        end        
                
        % Callback for panel resizing. 
        function SizeChanged(this,parent)
            % get new parent geometry
            parentw = parent.Position(3);
            parenth = parent.Position(4);
            
            % new width, height of each axis
            w = parentw - 65;
            h = (parenth - 110)/2;
            
            % adjust position of ax1
            this.ax1.Position = [50, 100+h, w-15, h];

            % adjust position of ax2
            this.ax2.Position = [20, 50, w+35, h];
        end
        
        % Callback for the plot variable selectors
        function selectorCallback(this,control)
            this.render(control);
        end
        
    end
    
    
    methods (Static)
        
        function syspanel = syscheck(sys)
            % Returns a copy of the sys.panels struct with all 
            % default values appropriately initialised.

            % Default panel settings
            syspanel.title = bdHilbert.title;
            syspanel.transients = true;            
            syspanel.markers = true;
            syspanel.relphase = false;

            % Nothing more to do if sys.panels.bdHilbert is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdHilbert')
                return;
            end
            
            % sys.panels.bdHilbert.title
            if isfield(sys.panels.bdHilbert,'title')
                syspanel.title = sys.panels.bdHilbert.title;
            end
            
            % sys.panels.bdHilbert.transients
            if isfield(sys.panels.bdHilbert,'transients')
                syspanel.transients = sys.panels.bdHilbert.transients;
            end
            
            % sys.panels.bdHilbert.markers
            if isfield(sys.panels.bdHilbert,'markers')
                syspanel.markers = sys.panels.bdHilbert.markers;
            end
            
            % sys.panels.bdHilbert.relphase
            if isfield(sys.panels.bdHilbert,'relphase')
                syspanel.markers = sys.panels.bdHilbert.relphase;
            end
        end
        
        function [H,P] = hilbert(Y)
            % Discrete-time anaytic signal via Hilbert Transform.
            %
            % Usage:
            %   [H,P] = bdHilbert.hilbert(Y)
            % where the real part of H is equivalent to the input signal Y
            % and the imaginary part of H is the Hilbert transform of Y.
            % The phase angles of H are returned in P.
            %
            % The algorithm [1] is similar to that used by the hilbert()
            % function provided with Matlab Signal Processing Toolbox
            % except that here it operates along the rows of Y instead
            % of the columns.
            %
            % [1] Marple S L "Computing the Discrete-Time Analytic Signal
            %     via FFT" IEEE Transactions on Signal Processing. Vol 47
            %     1999, pp 2600-2603.
            %
            % SEE ALSO
            %    hilbert
            
            % Fourier Transform along the rows of Y 
            Yfft = fft(Y,[],2);
            nfft = size(Yfft,2);
            halfn = ceil(nfft/2);

            % construct the multiplier matrix
            M = zeros(size(Yfft));
            if mod(nfft,2)
                % nfft is odd
                M(:,1) = 1;             % DC component
                M(:,2:halfn) = 2;       % positive frequencies
            else
                % nfft is even
                M(:,1) = 1;             % DC component
                M(:,2:halfn) = 2;       % positive frequencies
                M(:,halfn+1) = 1;       % Nyquist component
            end
            
            % Hilbert Transform
            H = ifft(Yfft.*M,[],2);
            
            % Return the phase angles (if requested)
            if nargout==2
                P = angle(H);
            end
        end
    end
    
end
