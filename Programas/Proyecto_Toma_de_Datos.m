clear; clc; close all;

% Configuración de ThingSpeak
channelID = 2930387;
readAPIKey = 'I9M0KUIKBANVSETS';

% Variable global de control
global detener
detener = false;

% Crear figura y líneas para ambas temperaturas
fig = figure('Name', 'Monitor de Temperaturas');
ambientChart = animatedline('Color', 'b', 'DisplayName', 'Temp. Líquido (Termocupla)');
liquidChart = animatedline('Color', 'r', 'DisplayName', 'Temp. Ambiente (DHT11)');
legend;

% Configurar gráfico
title('Temperaturas: Ambiente vs. Líquido');
grid on;
xlabel('Tiempo');
ylabel('Temperatura (°C)');
ylim('auto');

% Botón de detener
uicontrol('Style', 'pushbutton', ...
          'String', 'DETENER', ...
          'FontSize', 12, ...
          'BackgroundColor', 'red', ...
          'ForegroundColor', 'white', ...
          'Position', [20 20 100 40], ...
          'Callback', @(src, event) detenerCallback());

% Lectura inicial de datos (últimos 100)
data = thingSpeakRead(channelID, 'ReadKey', readAPIKey, 'NumPoints', 100, 'Fields', [1, 2]);
tempAmbiente = data(:,1)';  % DHT11
tempLiquido = data(:,2)';   % Termocupla
x = 1:length(tempAmbiente);

% Cargar datos iniciales al gráfico
for i = 1:length(x)
    addpoints(ambientChart, x(i), tempAmbiente(i));
    addpoints(liquidChart, x(i), tempLiquido(i));
end
drawnow;

% Bucle principal
while ishandle(fig) && ~detener
    % Leer la muestra más reciente
    newData = thingSpeakRead(channelID, 'ReadKey', readAPIKey, ...
        'NumPoints', 1, 'Fields', [1, 2]);

    nuevaTempAmb = newData(1);  % DHT11
    nuevaTempLiq = newData(2);  % Termocupla

    % Acumular los datos
    tempAmbiente = [tempAmbiente, nuevaTempAmb];
    tempLiquido = [tempLiquido, nuevaTempLiq];
    x = 1:length(tempAmbiente);  % Recalcular eje X

    % Añadir nuevos puntos al gráfico
    addpoints(ambientChart, x(end), nuevaTempAmb);
    addpoints(liquidChart, x(end), nuevaTempLiq);
    drawnow limitrate;

    % Actualizar límites del eje Y
    minTemp = min([tempAmbiente, tempLiquido]);
    maxTemp = max([tempAmbiente, tempLiquido]);
    ylim([floor(minTemp)-1, ceil(maxTemp)+1]);

    % Guardado automático de respaldo cada 20 muestras
    if mod(length(tempAmbiente), 20) == 0
        save('backupTemp.mat', 'tempAmbiente', 'tempLiquido');
    end

    pause(5); % Por la política de lectura de ThingSpeak
end

% Guardar datos al finalizar
disp('Guardando datos...');

% Guardar en archivo .mat
save('datosTemperaturas.mat', 'tempAmbiente', 'tempLiquido');

% Guardar en archivo .csv
T = table((1:length(tempAmbiente))', tempAmbiente', tempLiquido', ...
    'VariableNames', {'Tiempo', 'TempAmbiente', 'TempLiquido'});
writetable(T, 'datosTemperaturas.csv');

disp('Datos guardados como "datosTemperaturas.mat" y "datosTemperaturas.csv".');

% Calcular y mostrar promedios
promedioAmb = mean(tempAmbiente);
promedioLiq = mean(tempLiquido);
disp(['Promedio temperatura ambiente: ', num2str(promedioAmb, '%.2f'), ' °C']);
disp(['Promedio temperatura líquido: ', num2str(promedioLiq, '%.2f'), ' °C']);

% Función del botón de detener
function detenerCallback()
    global detener
    detener = true;
    disp('Botón de detener presionado. Finalizando...');
end
