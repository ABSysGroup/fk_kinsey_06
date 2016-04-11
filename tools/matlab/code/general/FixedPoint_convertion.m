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
%------------------------------------------------------------------------------

%% 0.1 Variables de trabajo
dataPath   = '~/Documents/Devel/Pancreas/HUPA';
scriptPath = '~/Documents/Devel/Pancreas/MatLab/experiments';
resultPath = '~/Documents/Devel/Pancreas/MatLab/results';
cd(scriptPath)
path('../functions',path)

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

%% 1. Input data. Datos HUPA
for patientIdx = patients
    filePref = sprintf('%s_%d%.2d%.2d_%d%.2d%.2d_v2_day_', ...
        patientIdx.name, ...
        patientIdx.year, patientIdx.month, patientIdx.dayStart, ...
        patientIdx.year, patientIdx.month, patientIdx.dayEnd);
    str      = sprintf('<strong>Patient</strong>: %s ... \n', patientIdx.name);
    disp(str);
    
    cd(dataPath);
    patientRawData = zeros(1,3);
    for i=1:5
        file = strcat(filePref, num2str(i), '.csv');
        if exist(fullfile(cd,file), 'file') == 2
            patientFileData = dlmread(file, ';');
            % Solo nos quedamos con 1 de cada 5 medidas
            patientRawData  = [patientRawData; patientFileData(1:5:length(patientFileData),:)];
        end
    end
    cd(scriptPath)
    
    numberBits = 16;
    fractionalBits = 4;
    
    glucose_ufi = bin(ufi( patientRawData(:,1), numberBits , fractionalBits));
    fileName = strcat('../results/', patientIdx.name, 'Glucose_fixedPoint.txt');
    fileID = fopen(fileName,'w');
    for i=1:length(glucose_ufi)
        fprintf(fileID,'%16s\n',glucose_ufi(i,:));
    end
    fclose(fileID);
end

%% Proceso inverso. Leer archivos en punto fijo y pasarlos a reales

% Lectura del archivo
cd(resultPath);

fid = fopen('BGGlucose_KF.txt');
KFResponse = inf(1436,1);

quant.mode      = 'fixed';
quant.roundmode = 'ceiling';
quant.format    = [16 4];
KFFormat = quantizer(quant);

for idx=1:1436
    % while ischar(tline(1:16))
    tline        = fgetl(fid);
    KFResponse(idx) = bin2num(KFFormat, tline(1:16));
    % KFResponse(idx) = bin2dec(tline(1:16))/16;
end
fclose(fid);

cd(scriptPath);

% Conversion a Time Series y visualizacion

glucoseKF  = timeseries(KFResponse, 'Name', 'glucose');
glucoseKF.DataInfo.Units = 'mg/dl';
glucoseKF.TimeInfo.Units = 'minutes';
glucoseKF.TreatNaNasMissing = true;
dataTimeEnd_minutes = (glucoseKF.length-1) * 5;
glucoseKF = setuniformtime(glucoseKF, 'StartTime', 0, 'EndTime', dataTimeEnd_minutes);

fileFig = strcat('../results/', 'BGGlucose_KF');
fig1=figure(1);
h = plot(glucoseKF);
set(h, 'LineStyle','--', 'LineWidth', 1.5, 'Color','blue');
grid on;
saveas(fig1, fileFig, 'png');
close(fig1);
