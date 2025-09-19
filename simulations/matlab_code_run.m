%% SolarLoRaWAN with Irradiance
modelName = 'SolarLoRaWAN';
new_system(modelName); 
open_system(modelName);

N = 3;   % Number of solar panels (change as needed)

%% Define Bus Object for Panel Data
elems(1) = Simulink.BusElement; elems(1).Name = 'ID';
elems(2) = Simulink.BusElement; elems(2).Name = 'Voltage';
elems(3) = Simulink.BusElement; elems(3).Name = 'Current';
elems(4) = Simulink.BusElement; elems(4).Name = 'Temp';
elems(5) = Simulink.BusElement; elems(5).Name = 'Irradiance';   % ✅ new
PanelBus = Simulink.Bus; 
PanelBus.Elements = elems;
assignin('base','PanelBus',PanelBus);

%% Create Panels
x0 = 30; y0 = 30; ySpacing = 220;

for i = 1:N
    yBase = y0 + (i-1)*ySpacing;

    % Voltage Source
    blkV = sprintf('%s/Panel%d_Voltage', modelName, i);
    add_block('simulink/Sources/Uniform Random Number', blkV, ...
        'Position', [x0, yBase, x0+60, yBase+30]);
    set_param(blkV,'Minimum','14','Maximum','20');

    % Current Source
    blkC = sprintf('%s/Panel%d_Current', modelName, i);
    add_block('simulink/Sources/Uniform Random Number', blkC, ...
        'Position', [x0, yBase+40, x0+60, yBase+70]);
    set_param(blkC,'Minimum','4','Maximum','8');

    % Temperature Source
    blkT = sprintf('%s/Panel%d_Temp', modelName, i);
    add_block('simulink/Sources/Uniform Random Number', blkT, ...
        'Position', [x0, yBase+80, x0+60, yBase+110]);
    set_param(blkT,'Minimum','25','Maximum','80');

    % Irradiance Source ✅ new
    blkIrr = sprintf('%s/Panel%d_Irradiance', modelName, i);
    add_block('simulink/Sources/Uniform Random Number', blkIrr, ...
        'Position', [x0, yBase+120, x0+60, yBase+150]);
    set_param(blkIrr,'Minimum','200','Maximum','1000'); % W/m² typical

    % Constant ID
    blkID = sprintf('%s/Panel%d_ID', modelName, i);
    add_block('simulink/Sources/Constant', blkID, ...
        'Position', [x0, yBase+160, x0+60, yBase+190]);
    set_param(blkID,'Value',num2str(i));

    % Bus Creator for each panel
    blkBus = sprintf('%s/Panel%dBus', modelName, i);
    add_block('simulink/Signal Routing/Bus Creator', blkBus, ...
        'Position', [x0+150, yBase, x0+200, yBase+200], ...
        'Inputs','5');

    % Connect signals to bus
    add_line(modelName, sprintf('Panel%d_ID/1', i), sprintf('Panel%dBus/1', i));
    add_line(modelName, sprintf('Panel%d_Voltage/1', i), sprintf('Panel%dBus/2', i));
    add_line(modelName, sprintf('Panel%d_Current/1', i), sprintf('Panel%dBus/3', i));
    add_line(modelName, sprintf('Panel%d_Temp/1', i), sprintf('Panel%dBus/4', i));
    add_line(modelName, sprintf('Panel%d_Irradiance/1', i), sprintf('Panel%dBus/5', i)); % ✅ new
end

%% Gateway Bus
blkGateway = sprintf('%s/GatewayBus', modelName);
add_block('simulink/Signal Routing/Bus Creator', blkGateway, ...
    'Position', [400, 100, 450, 100+N*100], 'Inputs', num2str(N));

for i = 1:N
    add_line(modelName, sprintf('Panel%dBus/1', i), sprintf('GatewayBus/%d', i));
end

%% Server Bus Selector
blkServer = sprintf('%s/ServerBusSel', modelName);
add_block('simulink/Signal Routing/Bus Selector', blkServer, ...
    'Position', [600, 100, 700, 100+N*150]);

% Dynamically set outputs (ID, V, C, T, Irr for each panel)
signals = {};
for i = 1:N
    signals = [signals, {sprintf('ID'), sprintf('Voltage'), ...
                         sprintf('Current'), sprintf('Temp'), sprintf('Irradiance')}];
end
set_param(blkServer, 'OutputSignals', strjoin(signals, ','));

add_line(modelName, 'GatewayBus/1', 'ServerBusSel/1');

%% Mux for Scope (all signals together)
blkMux = sprintf('%s/ScopeMux', modelName);
add_block('simulink/Signal Routing/Mux', blkMux, ...
    'Inputs', num2str(N*5), ...
    'Position', [800,100,820,100+N*50]);

for i = 1:N
    baseIdx = (i-1)*5;
    add_line(modelName, sprintf('ServerBusSel/%d',baseIdx+2), sprintf('ScopeMux/%d',baseIdx+1)); % Voltage
    add_line(modelName, sprintf('ServerBusSel/%d',baseIdx+3), sprintf('ScopeMux/%d',baseIdx+2)); % Current
    add_line(modelName, sprintf('ServerBusSel/%d',baseIdx+4), sprintf('ScopeMux/%d',baseIdx+3)); % Temp
    add_line(modelName, sprintf('ServerBusSel/%d',baseIdx+5), sprintf('ScopeMux/%d',baseIdx+4)); % Irradiance ✅
    % (ID is not plotted, only metadata)
end

%% Scope
blkScope = sprintf('%s/MultiScope', modelName);
add_block('simulink/Sinks/Scope', blkScope, ...
    'Position', [900, 200, 940, 300]);

add_line(modelName,'ScopeMux/1','MultiScope/1');

%% Save
save_system(modelName);
disp('✅ SolarLoRaWAN model built with Irradiance added.');
