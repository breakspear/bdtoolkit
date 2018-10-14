classdef bdSpace2D < bdPanel
    %bdSpace2D Brain Dynamics GUI panel for 2D spatial plots.
    %  The Space2D panel plots a snapshot of a matrix-based (2D) state variable.
    %
    %AUTHORS
    %  Stewart Heitmann (2018b)

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
        title = 'Space 2D';
    end    

    properties
        t               % Time steps of the solution (1 x t)
        y               % Matrix of space-time trajectories (n x t)
    end
    
    properties (Access=private)
        ax              % handle to the plot axes
        img             % handle to the image object
        submenu         % handle to subpanel selector menu item
        listener        % handle to our listener object
    end
    
    methods
        
        function this = bdSpace2D(tabgroup,control)
            % Construct a new Space-Time Portrait in the given tabgroup

            % initialise the base class (specifically this.menu and this.tab)
            this@bdPanel(tabgroup);
            
            % assign default values to missing options in sys.panels.bdSpace2D
            control.sys.panels.bdSpace2D = bdSpace2D.syscheck(control.sys);

            % configure the pull-down menu
            this.menu.Label = control.sys.panels.bdSpace2D.title;
            this.InitCalibrateMenu(control);
            this.InitExportMenu(control);
            this.InitCloseMenu(control);

            % configure the panel graphics
            this.tab.Title = control.sys.panels.bdSpace2D.title;
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
                % adjust the limits to fit the current data
                lo = min(this.y(:));
                hi = max(this.y(:));
                varindx = this.submenu.UserData.xxxindx;
                control.sys.vardef(varindx).lim = bdPanel.RoundLim(lo,hi);

                % refresh the vardef control widgets
                notify(control,'vardef');
                
                % redraw all panels (because the new limits apply to all panels)
                notify(control,'redraw');
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
            xlabel(this.ax,'column');
            ylabel(this.ax,'row');
            
            % construct the image data object (using zero data)
            this.img = imagesc(0,'Parent',this.ax);
            this.img.Clipping='off';             % Clipping is not necessary

            axis(this.ax,'tight','ij');
            
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
   
        % Redraw the data plots
        function redraw(this,control)
            %disp('bdSpace2D.redraw()')
            
            % get the details of the currently selected dynamic variable
            varname  = this.submenu.UserData.xxxname;           % generic name of variable
            varlabel = this.submenu.UserData.label;             % plot label for selected variable
            varindx  = this.submenu.UserData.xxxindx;           % index of selected variable in sys.vardef
            solindx  = control.sys.vardef(varindx).solindx;     % indices of selected entries in sol
            varlim   = control.sys.vardef(varindx).lim;         % axis limits of the selected variable
            [nr nc]  = size(control.sys.vardef(varindx).value); % size of the selected variable

            % get the time slider value
            this.t = control.sys.tval;                          % current time point
            
            % interpolate the solution at the current time value
            this.y = reshape( bdEval(control.sol,this.t,solindx), nr, nc);

            % update the image data
            this.img.CData = this.y;
            caxis(this.ax,varlim);

            % update the axes limits
            this.ax.XLim = [0.5 nc+0.5];
            this.ax.YLim = [0.5 nr+0.5];

            % update the title
            title(this.ax,num2str(this.t,['Variable ' varname ' at time t=%g']));
        end

    end
    
    methods (Static)
        
        function syspanel = syscheck(sys)
            % Assign default values to missing fields in sys.panels.bdSpace2D

            % Default panel settings
            syspanel.title = bdSpace2D.title;
            
            % Nothing more to do if sys.panels.bdSpace2D is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdSpace2D')
                return;
            end
            
            % sys.panels.bdSpace2D.title
            if isfield(sys.panels.bdSpace2D,'title')
                syspanel.title = sys.panels.bdSpace2D.title;
            end
        end
        
    end
    
end
