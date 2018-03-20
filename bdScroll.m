classdef bdScroll < handle
    %bdScroll - A scrolling uipanel for the Brain Dynamics Toolbox.
    %
    %EXAMPLE
    %   fig = figure('Units','pixels');
    %   scr = bdScroll(fig,300,300);
    %   ax = axes('Parent',scr.panel);
    %   imagesc(rand(100,100),'Parent',ax);
    %
    %AUTHORS
    %  Stewart Heitmann (2017b,2017c)

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
    
    properties (Access = public)
        panel        % uipanel for user-defined graphics objects
        vpanel       % viewport panel
    end
    
    properties (Access = private)
        cpanel       % container panel
        vscroll      % vertical scrollbar
        hscroll      % horizontal scrollbar
    end
    
    methods
        % Constructor
        function this = bdScroll(parent,panelw,panelh,varargin)
            % Construct a container panel at the given position within the parent 
            this.cpanel = uipanel('Parent',parent, 'BorderType','none');
            
            % construct view panel within the container (approximate position only)
            this.vpanel = uipanel('Parent',this.cpanel, ...
                'Units','pixels', ...
                'Position',[0 20 80 80], ...
                varargin{:});
            
            % construct the vertical scrollbar within the container (approximate position only)
            this.vscroll = uicontrol('Style','slider', ...
                'Value',1, ...
                'Parent',this.cpanel, ...
                'Units','pixels', ...
                'Position', [20,20,80,80] );

            % Slider callbacks are only executed when the user releases the
            % slider thumb. But we also want it to execute when the thumb
            % is being dragged. So we use a listener instead. 
            addlistener(this.vscroll,'Value','PostSet',@(~,~) this.vscrollCallback());
            
            % construct the horizontal scrollbar within the container (approximate position only)
            this.hscroll = uicontrol('Style','slider', ...
                'Parent',this.cpanel, ...
                'Units','pixels', ...
                'Position', [0 0 80,20] );
            
            % Slider callbacks are only executed when the user releases the
            % slider thumb. But we also want it to execute when the thumb
            % is being dragged. So we use a listener instead. 
            addlistener(this.hscroll,'Value','PostSet',@(~,~) this.hscrollCallback());

            % construct the users panel within the view panel.
            this.panel = uipanel('parent',this.vpanel, ...
                'Units','pixels', ...
                'Position',[2 2 panelw panelh], ...
                'BorderType','none');

            % resize the widgets within the container (to their accurate positions)
            this.SizeChanged();

            % register the SizeChanged callback for the container panel
            this.cpanel.SizeChangedFcn = @(src,evnt) this.SizeChanged();

            % register the SizeChanged callback for the user panel
            this.panel.SizeChangedFcn = @(src,evnt) this.SizeChangedUser(src);
        end
    
    end
    
    methods (Access = private)
 
        % Callback for changes to the size of the container panel.
        function SizeChanged(this)
            %disp('bdScroll.SizeChanged');
            
            % set container units to pixels
            cpanelunits = this.cpanel.Units;
            this.cpanel.Units = 'pixels';

            % get geometry of container panel (in pixels)
            cpanelw = this.cpanel.Position(3);
            cpanelh = this.cpanel.Position(4);
            
            % get geometry of our user panel
            panelw = this.panel.Position(3);
            panelh = this.panel.Position(4);

            % compute our widget geometries (assuming both scrollbars active)
            vpanelpos  = [2,23,max(cpanelw-21,0),max(cpanelh-22,0)];
            vscrollpos = [cpanelw-22,22,20,max(cpanelh-22,0)];
            hscrollpos = [3,1,max(cpanelw-23,0),20];
            
            % if the user panel is narrower than our container panel
            % then we don't need the horizontal scrollbar
            if (panelw < cpanelw)
                this.hscroll.Visible='off';
                this.hscroll.Value=0;                
                vpanelpos(2) = 2;
                vpanelpos(4) = cpanelh-1;
            else
                this.hscroll.Visible='on';
            end

            % if the user panel is shorter than our container panel
            % then we don't need the vertical scrollbar
            if (panelh < cpanelh)
                this.vscroll.Visible='off';
                this.vscroll.Value=1;                
                vpanelpos(1) = 2;
                vpanelpos(3) = cpanelw-2;
            else
                this.vscroll.Visible='on';
            end
            
            % Apply the new widget geometries
            this.vpanel.Position  = vpanelpos;
            this.vscroll.Position = vscrollpos;
            this.hscroll.Position = hscrollpos;
            
            % Apply the existing scrollbar settings
            % to the new panel geometry
            this.vscrollCallback();
            this.hscrollCallback();
            
            % restore the parent units
            this.cpanel.Units = cpanelunits;
        end

        % Callback for changes to the size of the user panel.
        % This callback is invoked when either the width or height of the
        % user panel is altered but not when the x or y positions are altered. 
        % The SizeChanged callback of the enclosing container  panel will
        % also be invoked (after this function).
        function SizeChangedUser(this,src)
            %disp('bdScroll.SizeChangedUser');

            % re-align the user panel to the top of the viewport.
            vpanely = this.vpanel.Position(2);
            vpanelh = this.vpanel.Position(4);
            panelh = this.panel.Position(4);
            this.panel.Position(2) = vpanely + vpanelh - panelh;
            
            % adjust the scrollbars using the container panel callback
            this.SizeChanged();
        end
 
        function vscrollCallback(this)
            %disp('bdScroll.vscrollCallback');
            vpanelh = this.vpanel.Position(4);
            panelh = this.panel.Position(4);
            shifth = panelh-vpanelh;
            offsety = this.vscroll.Value * shifth;
            this.panel.Position(2) = -offsety;
        end
        
        function hscrollCallback(this)
            %disp('bdScroll.hscrollCallback');
            vpanelw = this.vpanel.Position(3);
            panelw = this.panel.Position(3);
            shiftw = max(panelw-vpanelw,0);
            offsetx = this.hscroll.Value * shiftw;
            this.panel.Position(1) = -offsetx;
        end
    end
end

