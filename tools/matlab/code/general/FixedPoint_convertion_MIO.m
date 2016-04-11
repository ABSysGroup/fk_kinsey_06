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

% ES IDENTICO AL DE OSCAR PERO CON LOS PATHS DE MIS DISEÑOS
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

% %% 1. Input data. Datos HUPA
% for patientIdx = patients
%     filePref = sprintf('%s_%d%.2d%.2d_%d%.2d%.2d_v2_day_', ...
%         patientIdx.name, ...
%         patientIdx.year, patientIdx.month, patientIdx.dayStart, ...
%         patientIdx.year, patientIdx.month, patientIdx.dayEnd);
%     str      = sprintf('<strong>Patient</strong>: %s ... \n', patientIdx.name);
%     disp(str);
%     
%     cd(dataPath);
%     patientRawData = zeros(1,3);
%     for i=1:5
%         file = strcat(filePref, num2str(i), '.csv');
%         if exist(fullfile(cd,file), 'file') == 2
%             patientFileData = dlmread(file, ';');
%             % Solo nos quedamos con 1 de cada 5 medidas
%             patientRawData  = [patientRawData; patientFileData(1:5:length(patientFileData),:)];
%         end
%     end
%     cd(scriptPath)
%     
%     numberBits = 16;
%     fractionalBits = 4;
%     
%     glucose_ufi = bin(ufi( patientRawData(:,1), numberBits , fractionalBits));
%     fileName = strcat('../results/', patientIdx.name, 'Glucose_fixedPoint.txt');
%     fileID = fopen(fileName,'w');
%     for i=1:length(glucose_ufi)
%         fprintf(fileID,'%16s\n',glucose_ufi(i,:));
%     end
%     fclose(fileID);
% end

%% Proceso inverso. Leer archivos en punto fijo y pasarlos a reales

% Lectura del archivo
%se cambia de directorio
cd(resultPath);

% abre un fichero
fid = fopen('BGGlucose_KF.txt');
% 1436 es el número de filas del archivo a representar
%da la sensación que lo que está haciendo a continuación es generar una
%matriz de 1436 filas y 1 columna que contiene el símbolo que representa
%infinito
KFResponse = inf(1436,1);
for idx=1:1436
    % while ischar(tline(1:16))
    %devuelve la siguiente línea de texto eliminado los caracteres de nueva
    %línea
    tline        = fgetl(fid);
    %recueda que la línea contiene 3 valores diferentes cada uno de ellos
    %expresado con 16 bits, con tline(1:16) le indico que sólo coja los 16
    %primeros caracteres
    KFResponse(idx) = bin2dec(tline(1:16))/16;
end
fclose(fid);

cd(scriptPath);

% Conversion a Time Series y visualizacion
%KFResponse va a contener la representación decimal del binario leido
%timeseries crea una serie temporal usando KFResponse como datos y la va a
%dar el nombre de glucose
glucoseKF  = timeseries(KFResponse, 'Name', 'glucose');
glucoseKF.DataInfo.Units = 'mg/dl';
glucoseKF.TimeInfo.Units = 'minutes';
%los nan son datos no determinados. true — (Default) Treats all NaN 
%values as missing data except during statistical calculations.
glucoseKF.TreatNaNasMissing = true;
dataTimeEnd_minutes = (glucoseKF.length-1) * 5;
glucoseKF = setuniformtime(glucoseKF, 'StartTime', 0, 'EndTime', dataTimeEnd_minutes);
%strcat - Concatenate strings horizontally
fileFig = strcat('T:/TFG2015/sim/Palerm2007/', 'BGGlucose_KF');
%figure - Create figure window
fig1=figure(1);
% plot  This MATLAB function creates a 2-D line plot of the data in Y versus
%the corresponding values in X.If X and Y are both vectors, 
%then they must have equal length.
h = plot(glucoseKF);
%set - Set graphics object properties
set(h, 'LineStyle','--', 'LineWidth', 1.5, 'Color','blue');
%activa el enrejillado de la figura
grid on;
%saveas - saveas(h,'filename','format') This MATLAB function saves the 
%figure or Simulink block diagram with the handle  h to the file 
%filename.ext.
saveas(fig1, fileFig, 'png');
% close(fig1);

%NOTA ,COMANDO HOLD ON PARA INCLUIR MÁS GRAFICAS EN LA MISMA FIGURA
