%------------------------------------------------------------------------------
%- Company:        Universidad Complutense de Madrid
%- Engineer:       Oscar Garnica
%-
%- Create Date:    01/11/2014
%- Design Name:    Filtro Kalman con distintas entradas y mismo modelo estados
%- Project Name:   Filtro Kalman aplicaciones biomedicina
%- MatLab version: 2014a
%- Description:    lee los archivos binarios en punto fijo generados en la
%                   simulación de questa y de matlab, los convierte a
%                   decimal y los escribe y genera un archivo .png en el
%                   que compara los dos resultados
%-                 .
%
%- Additional Comments:
% el archivo se descompone en las siguientes secciones:




%------------------------------------------------------------------------------

%% 1.- Variables de trabajo
% datapath en las que se encuentran los estimulos de entrada
dataPath   = 'K:/fk_kinsey_06/sim/stimuli'; 
% datapath del código matlab
scriptPath = 'K:/fk_kinsey_06/tools/matlab/code';
% datapath en el que se vuelcan los resultados
resultPath = 'K:/fk_kinsey_06/sim/Kinsey2006';
cd(scriptPath)
% path('../functions',path)

%% 2.- Definicion de los pacientes
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

%% TRATAMIENTO DEL ARCHIVO DE SIMULACION GENERADO POR QUESTA_DISEÑO HW
%LECTURA DEL ARCHIVO EN BINARIO PURO Y CONVERSIÓN A DECIMAL
% ESCRITURA DEL NUEVO ARCHIVO EN DECIMAL



% Lectura del archivo
%se cambia de directorio
cd(resultPath);

% opens the file, filename, for binary read access, and
%returns an integer file identifier equal to or greater than 3.
fid = fopen('BGGlucose_KF_results_of_Questa_Q12.4.txt');

% 1436 es el número de filas del archivo a representar
%da la sensación que lo que está haciendo a continuación es generar una
%matriz de 1436 filas y 1 columna que contiene el símbolo que representa
%infinito, en definitiva parece una inicialización de la variable
KFResponse_questa = inf(1436,1);

% quant.mode      = 'fixed';
% quant.roundmode = 'ceiling';
% quant.format    = [16 4];
% KFFormat = quantizer(quant);

% recorre el archivo fuente leyendo cada linea y escribiendo el resultado
% en el archivo KFRresponse
for idx=1:1436
    %fgetl lee la siguiente línea de texto eliminado los caracteres de nueva
    %línea
    tline        = fgetl(fid);
    
    %la línea contiene 3 valores diferentes cada uno de ellos
    %expresado con 16 bits, con tline(1:16) le indico que sólo coja los 16
    %primeros caracteres
    %bin2dec Convert binary number string to decimal number
   % KFResponse(idx) = bin2dec(tline(1:16));
   KFResponse_questa(idx) = typecast(uint32(bin2dec(tline(1:32))),'int32');
%     KFResponse(idx) = bin2num(KFFormat, tline(1:16));
end
display(KFResponse_questa)
% cierro el archivo
fclose(fid);
%%
%display muestra el archivo por la ventana de comandos
%para limpiar la ventana de comandos clc
%display(KFResponse)
%% 

%%ESCRIBIR UN OBJETO EN UN FICHERO DE TEXTO
%str cat function horizontally concatenates strings s1,...,sN.
%se genera el directorio y nombre del archivoa escribir
%LECTURA DEL ARCHIVO GENERADO CON LA SIMULACIÓN DE QUESTA
fileName = strcat('K:/fk_kinsey_06/sim/Kinsey2006/', 'BGGlucose_KF_results_of_Questa_DECIMAL.txt');

%'w' Open or create new file for writing. Discard existing contents, if any
fileID = fopen(fileName,'w');

%Length of largest array dimension
for i=1:length(KFResponse_questa)
    %fprintf - Write data to text file
    
    fprintf(fileID,'%d\n',KFResponse_questa(i,:));
end

%closes an open file.
fclose(fileID);

%% TRATAMIENTO DEL ARCHIVO DE SIMULACION GENERADO POR MATLAB
%LECTURA DEL ARCHIVO EN BINARIO PURO Y CONVERSIÓN A DECIMAL
% ESCRITURA DEL NUEVO ARCHIVO EN DECIMAL


fid = fopen('salida_kinsey_model.txt');
KFResponse_matlab = inf(1436,1);



for idx=1:1436
    tline        = fgetl(fid);
      KFResponse_matlab(idx) = typecast(uint32(bin2dec(tline(1:32))),'int32');
end
fclose(fid);
%display(KFResponse_O)
fileName = strcat('K:/fk_kinsey_06/sim/Kinsey2006/', 'BGGlucose_KF_results_of_matlab_DECIMAL.txt');
fileID = fopen(fileName,'w');
for i=1:length(KFResponse_matlab)
    fprintf(fileID,'%d\n',KFResponse_matlab(i,:));
end
fclose(fileID);

%% PLOTAR UN ARCHIVO
%%crea la serie temporal que quiere plotar
cd(scriptPath);
% Conversion a Time Series y visualizacion DE LA FIGURA 1

%KFResponse contiene la representación decimal del binario leido

%timeseries crea una serie temporal usando KFResponse como datos y la va a
%dar el nombre de glucose
%Time series are data vectors sampled over time, in order, 
%often at regular intervals.
%represent the time-evolution of a dynamic population or process.
%The linear ordering of time series gives them a distinctive place 
%in data analysis, with a specialized set of techniques.
glucoseKF_questa  = timeseries(KFResponse_questa, 'Name', 'glucose');
glucoseKF_matlab  = timeseries(KFResponse_matlab, 'Name', 'glucose');

glucoseKF_questa.DataInfo.Units = 'mg/dl';
glucoseKF_matlab.DataInfo.Units = 'mg/dl';

glucoseKF_questa.TimeInfo.Units = 'minutes';
glucoseKF_matlab.TimeInfo.Units = 'minutes';

%los nan son datos no determinados. true — (Default) Treats all NaN 
%values as missing data except during statistical calculations.
glucoseKF_questa.TreatNaNasMissing = true;
glucoseKF_matlab.TreatNaNasMissing = true;


dataTimeEnd_minutes_questa = (glucoseKF_questa.length-1) * 5;
dataTimeEnd_minutes_matlab = (glucoseKF_matlab.length-1) * 5;

glucoseKF_questa = setuniformtime(glucoseKF_questa, 'StartTime', 0, 'EndTime', dataTimeEnd_minutes_questa);
glucoseKF_matlab = setuniformtime(glucoseKF_matlab, 'StartTime', 0, 'EndTime', dataTimeEnd_minutes_matlab);

%% PLOTA LAS FIGURAS
fileFig = strcat('K:/fk_kinsey_06/sim/Kinsey2006', 'PLOT_COMPARA_MATLAB_QUESTA');

%figure - figure creates a new figure window using default property values
%The title of the figure is an integer value that is not already used by
%an existing figure. MATLAB® saves this integer value in 
%the figure's Number property.
fig1=figure(1);



%hold on retains plots in the current axes so that new plots added to 
%the axes do not delete existing plots. 
hold on

%plot  This MATLAB function creates a 2-D line plot of the data in Y versus
%the corresponding values in X.If X and Y are both vectors, 
%then they must have equal length.
% h_questa = plot(glucoseKF_questa);
h_matlab = plot(glucoseKF_matlab);


%set - Set graphics object properties
% el azul es questa
% set(h_questa, 'LineStyle','--', 'LineWidth', 1.5, 'Color','blue');
%el rojo es matlab
set(h_matlab, 'LineStyle','--', 'LineWidth', 1.5, 'Color','red');

%activa el enrejillado de la figura
grid on;

%saveas - saveas(h,'filename','format') This MATLAB function saves the 
%figure or Simulink block diagram with the handle  h to the file 
%filename.ext.
saveas(fig1, fileFig, 'png');
% close(fig1);


% close(fig1);
%NOTA ,COMANDO HOLD ON PARA INCLUIR MÁS GRAFICAS EN LA MISMA FIGURA

% 
%  function [y] = sbin2dec(x)
%         if(x(1)=='0')
%             y = bin2dec(x(2:end));
%         else
%             y = bin2dec(x(2:end)) - 2 ^ (length(x) - 1);
%     end
