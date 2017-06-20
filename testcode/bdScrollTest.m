% construct figure
fig = figure('Units','pixels','Position',[randi(100,1,1),randi(100,1,1),600,400]);

container = uipanel('Parent', fig, ...
    'Units','pixels', ...
    'Position',[10 50 300 300], ...
    'BorderType','line');

scrollpane = bdScroll(container,900,900);
ax = axes('Parent',scrollpane.panel);
imagesc(rand(100,100),'Parent',ax);
