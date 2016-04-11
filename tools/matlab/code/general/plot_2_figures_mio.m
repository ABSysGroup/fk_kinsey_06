%------------------------------------------------------------------------------
%- Company:        Universidad Complutense de Madrid
%- Engineer:       Oscar Garnica
%-
%- Create Date:    01/11/2014
%- Design Name:    Filtro Kalman con distintas entradas y mismo modelo estados
%- Project Name:   Filtro Kalman aplicaciones biomedicina
%- MatLab version: 2014a
%- Description:    Estudiamos la respuesta de un filtro de Kalman usados en pancreas artificial para los
%-                 presentes en la literatura.
%
%- Additional Comments:
%                  En el archivo vamos a usar distintos tipos de objetos para representar los datos
%dependiendo del tipo de analisis que se realice. El tipo
%base sera time series pero en el caso de utilizar
%metodos del DSP Toolbox lo convertiremos a la clase Signal %Source.
% MUESTRA DOS GRAFICAS EN LA MISMA FIGURA
% 
%------------------------------------------------------------------------------

%% 0.1 Variables de trabajo
% datapath en las que se encuentran los estimulos de entrada
dataPath   = 'T:/TFG2015/sim/stimuli'; 
% datapath del código matlab
scriptPath = 'T:/TFG2015/tools/matlab/code';
% datapath en el que se vuelcan los resultados
resultPath = 'T:/TFG2015/sim/Palerm2007';
cd(scriptPath)
% path('../functions',path)

%% 0.1. Definicion de los pacientes
patients = struct('name' ,    'BG', ...
    'year' ,    2013, ...
    'month',    5   , ...
    'dayStart', 15  , ...
    'dayEnd',   20);

patients(2) = struct('name' ,    'Cl', ...
    'year' ,    2013, ...
    'month',    6   , ...
    'dayStart', 13  , ...
    'dayEnd',   17);

patients(3) = struct('name' ,    'JB', ...
    'year' ,    2013, ...
    'month',    4   , ...
    'dayStart', 3   , ...
    'dayEnd',   9);

patients(4) = struct('name' ,    'ME', ...
    'year' ,    2013, ...
    'month',    5   , ...
    'dayStart', 15   , ...
    'dayEnd',   20);



%% Leer archivos en punto fijo representado en binario y pasarlos a reales Y PLOTARLOS

% Lectura del archivo
%se cambia de directorio en el que se quiere guardar el archivo
cd(resultPath);

% abre un fichero 1
%This MATLAB function opens the file, filename, for binary read access, and
%returns an integer file identifier equal to or greater than 3.
fid = fopen('BGGlucose_KF.txt');

% inf es la representación de infinito
% 1436 es el número de filas del archivo
% la linea genera una matriz de 1436 filas y 1 columna que contiene el símbolo que representa
%infinito
KFResponse = inf(1436,1);


for idx=1:1436

    % fgetl returns the next line of the specified file, removing the
    %newline characters.
    tline        = fgetl(fid);
    
    %tline(1:16) le indica que tome las columnas de la 1 a la 16 de tline
    KFResponse(idx) = bin2dec(tline(1:16));
end
fclose(fid);
%display(KFResponse)

% abre un fichero 2
fid = fopen('BGGlucose_KF_MatLab_Q12.4_Native.txt');
KFResponse_O = inf(1436,1);
for idx=1:1436
    tline        = fgetl(fid);
    KFResponse_O(idx) = bin2dec(tline(20:35));
end
fclose(fid);
display(KFResponse_O)

cd(scriptPath);

% Conversion a Time Series y visualizacion DE LA FIGURA 1
%KFResponse va a contener la representación decimal del binario leido
%timeseries crea una serie temporal usando KFResponse como datos y la va a
%dar el nombre de glucose
glucoseKF  = timeseries(KFResponse, 'Name', 'glucose');
glucoseKF_O  = timeseries(KFResponse_O, 'Name', 'glucose');
glucoseKF.DataInfo.Units = 'mg/dl';
glucoseKF_O.DataInfo.Units = 'mg/dl';
glucoseKF.TimeInfo.Units = 'minutes';
glucoseKF_O.TimeInfo.Units = 'minutes';
%los nan son datos no determinados. true — (Default) Treats all NaN 
%values as missing data except during statistical calculations.
glucoseKF.TreatNaNasMissing = true;
glucoseKF_O.TreatNaNasMissing = true;
dataTimeEnd_minutes = (glucoseKF.length-1) * 5;
dataTimeEnd_minutes_O = (glucoseKF_O.length-1) * 5;

%Assigns a uniform time vector to a time series object
glucoseKF = setuniformtime(glucoseKF, 'StartTime', 0, 'EndTime', dataTimeEnd_minutes);
glucoseKF_O = setuniformtime(glucoseKF_O, 'StartTime', 0, 'EndTime', dataTimeEnd_minutes_O);
%strcat - Concatenate strings horizontally, esta fijando el nombre y ubicación del archivo de salida
fileFig = strcat('T:/TFG2015/sim/Palerm2007/', 'AMBOS_DOS');
%figure - Create figure window
fig1=figure(1);
% plot  This MATLAB function creates a 2-D line plot of the data in Y versus
%the corresponding values in X.If X and Y are both vectors, 
%then they must have equal length.
hold on
h = plot(glucoseKF);
h_O = plot(glucoseKF_O);
%set - Set graphics object properties
set(h, 'LineStyle','--', 'LineWidth', 1.5, 'Color','blue');
set(h_O, 'LineStyle','--', 'LineWidth', 1.5, 'Color','red');
%activa el enrejillado de la figura
grid on;
%saveas - saveas(h,'filename','format') This MATLAB function saves the 
%figure or Simulink block diagram with the handle  h to the file 
%filename.ext.
saveas(fig1, fileFig, 'png');
% close(fig1);


% close(fig1);
%NOTA ,COMANDO HOLD ON PARA INCLUIR MÁS GRAFICAS EN LA MISMA FIGURA
