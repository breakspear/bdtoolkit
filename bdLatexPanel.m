classdef bdLatexPanel < handle
    %bdLatexPanel - a GUI tab panel for displaying latex equations.
    %   Displays mathematical equations in the Brain Dynamics Toolbox GUI
    %   using the MATLAB built-in latex interpreter.
    
    % Copyright (c) 2016, Stewart Heitmann <heitmann@ego.id.au>
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

    methods        
        function this = bdLatexPanel(tabgroup,title,latexstr)
            % Construct a new tab panel in the parent tabgroup.
            % Usage:
            %    bdLatexPanel(tabgroup,title,latexstr)
            % where 
            %    tabgroup is a handle to the parent uitabgroup object.
            %    title is a string defining the name given to the new tab.
            %    latexstr is a cell array of single-line strings that are
            %       formatted for the MATLAB built-in latex interpreter.

            % construct the uitab
            tab = uitab(tabgroup, 'title',title);

            % construct the axes
            ax = axes('Parent',tab, ...
                'Units','normal', ...
                'Position', [0 0 1 1], ...
                'XTick', [], ...
                'YTick', [], ...
                'XColor', [1 1 1], ...
                'YColor', [1 1 1]);
            %axis 'off';
            
            % construct the latex text
            text(0.01,0.98,latexstr, 'interpreter','latex', 'Parent',ax, 'FontSize',16, 'VerticalAlignment','top');
            
            % No need to listen for changes because everything on this
            % panel is fixed at creation time.
        end
        
    end
    
end

