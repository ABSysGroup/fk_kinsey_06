%------------------------------------------------------------------------------
%- Company:        Universidad Complutense de Madrid
%- Engineer:       Juan Lanchares
%-
%- Create Date:    29/06/2015
%- Design Name:    Filtro Kalman kinsey 2006
%- Project Name:   Filtro Kalman aplicaciones biomedicina
%- MatLab version: 2014b
%%- Description:    % modelo decimal del filtro rápido del dual-rate de kinsey.
                    % lectura de glucosa intersticial mediante cgm cada 5 minutos
                    % el modelo del proceso tiene 4 estados
                        % glucosa 
                        % velocidad de la glucosa
                        % ganancia del sensor
                        % velociadad de la ganancia del sensor
                    % la H es dinámica puesto que depende de los valores 
                    % de la glucosa y de la ganancia del sensor 
                    % tal y como indica kinsey en su artículo el cálculo de
                    %  P_priori_b10 utiliza  WQWt en lugar de Q
                    
                    %no utiliza como entrada datos reales sino datos
                    %sintéticos que explico más adelante

%------------------------------------------------------------------------------

%% 0. Definicion variables de trabajo
% datapath en las que se encuentran los estimulos de entrada
dataPath   = 'K:/fk_kinsey_06/sim/stimuli/hupa';
% datapath del código matlab
scriptPath = 'K:/fk_kinsey_06/tools/matlab/code';
% datapath en el que se vuelcan los resultados
resultPath = 'K:/fk_kinsey_06/sim/Kinsey2006';

cd(scriptPath)


%% 1. Definicion de los pacientes
% se utiliza posteriormente para generar el nombre de los archivos
% hupa de entrada al fk
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

%% 2. Definicion aritmetica Q12.4

% Se establecen los parametros que definen la aritmetica a emplear
numberBits     = 32;
fractionalBits = 4;
%número de estados de la X, es decir glucosa, velocidad y aceleración
num_states      = 4;

% numerictype(s,w,f) creates a numerictype object with Fixed-point:
% binary point scaling, Signed property value s, word length w and
% fraction length f.
KF_t = numerictype( 'Signed', true, ...
    'WordLength', numberBits, ...
    'FractionLength', fractionalBits);

KFArith = fimath('RoundingMethod'   , 'nearest', ...
    'OverflowAction'   , 'Saturate', ...
    'ProductMode'      , 'SpecifyPrecision', ...
    'ProductWordLength', numberBits, ...
    'ProductFractionLength', fractionalBits, ...
    'SumMode', 'SpecifyPrecision', ...
    'SumWordLength', numberBits, ...
    'SumFractionLength', fractionalBits);
%% 3 generación parcial del nombre de los hupa

patientIdx = patients(1);

filePref = sprintf('%s_%d%.2d%.2d_%d%.2d%.2d_v2_day_', ...
    patientIdx.name, ...
    patientIdx.year, patientIdx.month, patientIdx.dayStart, ...
    patientIdx.year, patientIdx.month, patientIdx.dayEnd);


str      = sprintf('<strong>Patient</strong>: %s ... \n', patientIdx.name);
disp(str);

%disp-->Display text or array


%% generación de la entrada exponencial
 T0=723;%tiempo de decaimiento
 t = 1:5784; %tiempo de muestreo 
 BG= 100; %valor de glucosa en sangre constante
 gain=exp(-t/T0);
 de=2; %desviación estandar
%X = rand(sz1,...,szN) returns an sz1-by-...-by-szN array where sz1,...,szN
% indicates the size of each dimension. For example, rand(3,4) returns a
% 3-by-4 array of pseudorandom values.
 patientRawData=BG.*gain+ de.*rand(1,5784);

%% 6. Definicion de Time Series

glucose = timeseries(patientRawData, 'Name', 'glucose');
glucose.DataInfo.Units = 'mg/dl';
glucose.TimeInfo.Units = 'minutes';
glucose.TreatNaNasMissing = true;


dataTimeEnd_minutes = (glucose.length-1) * 5;


glucose = setuniformtime(glucose, 'StartTime', 0, 'EndTime', dataTimeEnd_minutes);

responseKFKinsey2006 = glucose;
responseKFKinsey2006.name = 'Kinsey2006';


patient = tscollection({glucose ...
    responseKFKinsey2006}, ...
    'name',patientIdx.name);
patient.TimeInfo.Units = 'minutes';

% Define events

firstDay        = tsdata.event('Midday', 0);
firstDay.Units  = 'hours';
secondDay       = tsdata.event('Midday', 24);
secondDay.Units = 'hours';
thirdDay        = tsdata.event('Midday', 48);
thirdDay.Units  = 'hours';
fourthDay       = tsdata.event('Midday', 72);
fourhtDay.Units = 'hours';

glucose = addevent(glucose,firstDay);
glucose = addevent(glucose,secondDay);
glucose = addevent(glucose,thirdDay);
glucose = addevent(glucose,fourthDay);

clear *Day dataTimeEnd_minutes dayStart dayEnd name month year patientRawData;




%% 6. Ecuaciones explicitas KF KINSEY
% Modelo de proceso
% x[n+1]=Ax[n]+Tw[n]
%
%modelo de medición
% y[n]=Hx[n]+v[n]
%donde H (nomenclatura Bishop) es C de kinsey

%------------------------------------------------------------------------------

Q_b10       = 0.125;
TQTt_b10    = [0 0 0 0; 0 Q_b10 0 0; 0 0 0 0; 0 0 0 Q_b10];
R_b10       = 1;
A_b10       = [1 1 0 0; 0 1 0 0; 0 0 1 1;0 0 0 1];
Hc_b10      = [0.5 0 0.5 0];
Hd_b10      = [1 0 1 0];


initSt_b10  = [1 1 1 1];

I_b10               = eye(num_states);
P_posteriori_b10    = ones(num_states);  % Initial error covariance
x_posteriori_b10    = initSt_b10';            % Initial condition on the state
ye_b10              = zeros(glucose.Length,1);
ycov_b10            = zeros(glucose.Length,1);
errcov_b10          = zeros(glucose.Length,1);
K_b10               = zeros(num_states,1);


responseKFKinseyModel = zeros(glucose.length,5);


for i=1:glucose.Length
    
    % predicción
    x_priori_b10        = A_b10 * x_posteriori_b10;
    P_priori_b10        = A_b10 * P_posteriori_b10 * A_b10' + TQTt_b10;
    
    %calculo de la H dinámica
    Hd_b10(1)           =  0.50 .*  x_priori_b10(3);
    Hd_b10(3)           =  0.50 .*  x_priori_b10(1);
    
    %calculo de la ganancia
    KDndo_b10           = P_priori_b10 * Hd_b10';    
    KDsor_b10           = (Hd_b10 * P_priori_b10 * Hd_b10' + R_b10);
    K_b10               = KDndo_b10 ./ KDsor_b10;
    

    %corrección
    z                   = glucose.Data(i);
    x_posteriori_b10    = x_priori_b10 + K_b10 .* (z - Hd_b10 * x_priori_b10);    
    P_posteriori_b10    = (I_b10 - K_b10 * Hd_b10) * P_priori_b10; 
    
    %depuración
    glucosa_aux         = glucose.Data(i);
    medida_estimada     = Hd_b10 * x_priori_b10;
    residual            = glucosa_aux - medida_estimada;
    K_por_residual      = K_b10 * (glucose.Data(i) - Hd_b10 * x_priori_b10);
    


    responseKFKinseyModel(i,:) = [x_posteriori_b10' medida_estimada];
end

%% 7. Representacion resultados


salida_filtro  = timeseries(responseKFKinseyModel(:,1), 'Name', 'respuesta');
salida_filtro.DataInfo.Units = 'mg/dl';
salida_filtro.TimeInfo.Units = 'minutes';
salida_filtro.TreatNaNasMissing = true;
dataTimeEnd_minutes_salida = (salida_filtro.length-1) * 5;
salida_filtro = setuniformtime(salida_filtro, 'StartTime', 0, 'EndTime', dataTimeEnd_minutes_salida);

salida_filtro_2  = timeseries(responseKFKinseyModel(:,1), 'Name', 'respuesta');
salida_filtro_2.DataInfo.Units = 'mg/dl';
salida_filtro_2.TimeInfo.Units = 'minutes';
salida_filtro_2.TreatNaNasMissing = true;
dataTimeEnd_minutes_salida = (salida_filtro.length-1) * 5;
salida_filtro_2 = setuniformtime(salida_filtro_2, 'StartTime', 0, 'EndTime', dataTimeEnd_minutes_salida);
fileFig = strcat('K:/fk_kinsey_06/sim/Kinsey2006/', 'pruebas');

fig1=figure(1);
hold on;
% h_glucosa = plot(patient.glucose);
% set(h_glucosa, 'LineStyle','--', 'LineWidth', 1.5, 'Color','blue');%,'marker','+'

h_xposteriori = plot(salida_filtro); 
set(h_xposteriori, 'LineStyle','--', 'LineWidth', 1.5, 'Color','red');%, 'marker','*'
% 
% h_xposteriori_2 = plot(salida_filtro_2); 
% set(h_xposteriori_2, 'LineStyle','--', 'LineWidth', 1.5, 'Color','green');%,'marker','<'

xlabel('Time (minutes)');
ylabel('BG (mg/dl)') % left y-axis
% legend('BG','KF Bequette2004a');
grid on;
saveas(fig1, fileFig, 'png');
%close(fig1);

%% escritura de los resultados binarios en un archivo de texto

responseKFKinseyModel_fi = fi(responseKFKinseyModel, KF_t, KFArith);
responseKFKinseyModel_bi = bin(responseKFKinseyModel_fi);

fileName = strcat('K:/fk_kinsey_06/sim/Kinsey2006/','salida_kinsey_model.txt');
fileID = fopen(fileName,'w');
for i=1:length(responseKFKinseyModel_bi)
    
    fprintf(fileID,'%16s\n',responseKFKinseyModel_bi(i,:));
end
fclose(fileID);

clear A B Hc Hd D G H prediction* str L M P idx tmp initSt timeDepth;
clear responseKFKinsey2006;





