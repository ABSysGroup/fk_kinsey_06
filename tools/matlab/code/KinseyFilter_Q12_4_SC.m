%------------------------------------------------------------------------------
%- Company:        Universidad Complutense de Madrid
%- Engineer:       Juan Lanchares
%-
%- Create Date:    29/06/2015
%- Design Name:    Filtro Kalman kinsey 2006
%- Project Name:   Filtro Kalman aplicaciones biomedicina
%- MatLab version: 2014b
%- Description:    modelo en punto fijo del modelo rápido de kinsey_2006
%-                
%
%- Additional Comments:
%   -lee los 5 archivos de un paciente
%   -ejecuta la simulación 
%   -vuelca los resultados en un fichero
%   -los plota en  pantalla el x_posteriri y el valor de la glucosa
% se descompone en las siguientes secciones:
    % 0.- definición de variables del trabajo
    % 1.- definición de pacientes
    % 2.- Definicion aritmetica Q12.4
    % 3.- generación parcial del nombre de los hupa
    % 4.- lectura de los 5 ficheros de un paciente
    % 5.- Definicion de Time Series
    % 6.- Ecuaciones explicitas KF KINSEY
    % 7.- Representacion resultados
    % 4.- saca por consola el nombre del paciente
    % 5.- lectura de los 5 ficheros de un paciente
    % 6.- definición de time series
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
no_states      = 4;

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

%disp-->Display text or array

%% 4 .- lectura de los 5 ficheros de un paciente

cd(dataPath);
patientRawData = zeros(1,3);

for i=1:5
    file = strcat(filePref, num2str(i), '.csv');
    if exist(fullfile(cd,file), 'file') == 2        
        patientFileData = dlmread(file, ';');   
        patientRawData  = [patientRawData; patientFileData(1:5:length(patientFileData),:)];
    end
end
cd(scriptPath)
%clear-->Remove items from workspace, freeing up system memory
clear str file i patientFileData;

%% 5. Definicion de Time Series

glucose = timeseries(fi(patientRawData(2:end,1), KF_t, KFArith), 'Name', 'glucose');
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

glucose         = addevent(glucose,firstDay);
glucose         = addevent(glucose,secondDay);
glucose         = addevent(glucose,thirdDay);
glucose         = addevent(glucose,fourthDay);

clear *Day dataTimeEnd_minutes dayStart dayEnd name month year patientRawData;




%% 6. Ecuaciones explicitas KF KINSEY
% Given the discrete plant:
%
% x[n+1]=Ax[n]+Bu[n]+Gw[n]
% y[n]=Cx[n]+Du[n]+Hw[n]+v[n]
%------------------------------------------------------------------------------

Q_b10                   = 0.125;
Q_b10                   = Q_b10 * eye(no_states);   % matriz diagonal
R_b10                   = 1;
A_b10                   = [1 1 0 0; 0 1 0 0; 0 0 1 1;0 0 0 1];
Hc_b10                  = [0.5 0 0.5 0];
I_b10                   = eye(no_states);           % matriz identidad
initSt_b10              = [1 1 1 1];                % Estado inicial del filtro
P_posteriori_b10        = 1 * ones(no_states);      % Initial error covariance
x_posteriori_b10        = initSt_b10';              % Initial condition on the state
ye_b10                  = zeros(glucose.Length,1);
ycov_b10                = zeros(glucose.Length,1);
errcov_b10              = zeros(glucose.Length,1);


%fi-->Construct fixed-point numeric objec
Q                       = fi(Q_b10, KF_t, KFArith);
R                       = fi(R_b10, KF_t, KFArith);
A                       = fi(A_b10, KF_t, KFArith);
Hc                      = fi(Hc_b10, KF_t, KFArith); 
I                       = fi(I_b10, KF_t, KFArith);
P_posteriori            = fi(P_posteriori_b10, KF_t, KFArith);
x_posteriori            = fi(x_posteriori_b10, KF_t, KFArith);
ye                      = fi(ye_b10, KF_t, KFArith);
ycov                    = fi(ycov_b10, KF_t, KFArith);
errcov                  = fi(errcov_b10, KF_t, KFArith);
K                       = fi(zeros(no_states,1), KF_t, KFArith);
KDndo                   = fi(zeros(no_states,1), KF_t, KFArith);
KDsor                   = fi(zeros(1,1), KF_t, KFArith);
responseKFKinseyModel   = fi(zeros(glucose.length,12), KF_t, KFArith);


for i=1:glucose.Length

    % Time update
    
    x_priori = A * x_posteriori;            
    P_priori = A * P_posteriori * A' + Q;              
   
   
    %calcula el primer factor de K
    KDndo        = P_priori * Hc';
    % calcula el segundo factor de K
    KDsor        = (Hc * P_priori * Hc' + R);
    
    %divide 
    % c = divide(T,a,b) performs division on the elements of a by the
    % elements of b. The result c has the numerictype object T
    K            = divide(KF_t, KDndo, KDsor);
  
    x_posteriori = x_priori + K * (glucose.Data(i) - Hc * x_priori);      
    P_posteriori = (I - K * Hc) * P_priori; 
    
    %ye(i) es la medida predicha 
    ye(i) = Hc * x_posteriori;
    errcov(i) = Hc * P_posteriori * Hc';
   responseKFKinseyModel(i,:) = [x_posteriori' x_priori' K'];
end

%bin-->Binary representation of stored integer of fi object
responseKFKinseyModel_bi = bin(responseKFKinseyModel);
fileName = strcat('K:/fk_kinsey_06/sim/Kinsey2006/','salida_kinsey_model.txt');
fileID = fopen(fileName,'w');
for i=1:length(responseKFKinseyModel_bi)
   fprintf(fileID,'%16s\n',responseKFKinseyModel_bi(i,:));
end
fclose(fileID);

clear A B Hc Hd D G H prediction* str L M P idx tmp initSt timeDepth;
clear responseKFKinsey2006;

%% 7. Representacion resultados
salida_filtro  = timeseries(responseKFKinseyModel(:,1), 'Name', 'respuesta');
salida_filtro.DataInfo.Units = 'mg/dl';
salida_filtro.TimeInfo.Units = 'minutes';
salida_filtro.TreatNaNasMissing = true;

dataTimeEnd_minutes_salida = (salida_filtro.length-1) * 5;

salida_filtro = setuniformtime(salida_filtro, 'StartTime', 0, 'EndTime', dataTimeEnd_minutes_salida);
fileFig = strcat('K:/fk_kinsey_06/sim/Kinsey2006/', 'BG_vs_Kinsey2006_bueno');

fig1=figure(1);
hold on;
h_glucosa = plot(patient.glucose);
h_xposteriori = plot(salida_filtro);
set(h_glucosa, 'LineStyle','--', 'LineWidth', 1.5, 'Color','blue');
set(h_xposteriori, 'LineStyle','--', 'LineWidth', 1.5, 'Color','red');

xlabel('Time (minutes)');
ylabel('BG (mg/dl)') % left y-axis
% legend('BG','KF Bequette2004a');
grid on;
saveas(fig1, fileFig, 'png');
%close(fig1);

