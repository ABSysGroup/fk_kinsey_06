%------------------------------------------------------------------------------
%- Company:        Universidad Complutense de Madrid
%- Engineer:       Oscar Garnica
%-
%- Create Date:    01/11/2014
%- Design Name:    dual rate rápido
%- Project Name:   Filtro Kalman aplicaciones biomedicina
%- MatLab version: 2014a
%- Description:     % modelo en punto fijo del filtro rápido del dual-rate de kinsey.
                    % lectura deglucosa intersticial mediante cgm cada 5 minutos
                    % cc --> tiene comentarios
                    % a diferencia del tfg2015 tiene 4 estados
                        % glucosa 
                        % velocidad de la glucosa
                        % ganancia del sensor
                        % velociadad de la ganancia del sensor
                    % la H es dinámica, no estatica como en tfg2015
					%IMPORTANTE:hay que generar el directorio virtual K para que funcione
                    
                
%- Additional Comments:
% lee los 5 archivos de un paciente ejecuta la simulación y vuelca los
% resultados en un fichero y los plota en la pantalla 
% se descompone en las siguientes secciones:
    % 0.-definición de variables del trabajo
    % 1.-definición de pacientes
    % 2.- Definicion aritmetica Q12.4
    % 3.- generación parcial del nombre de los hupa
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
% PREGUNTAR A OSCAR POQUE ES NECESARIO CAMBIAR DE DIRECTORIOS EN LA
% EJECUCIÓN DE LOS PROGRAMAS
cd(scriptPath)
%No se muy bien para que sirve este comando de path. en los otros programas
%lo he comentado. supongo que sirve para no tener que poner el camino
%completo como hago yo
%path('../functions',path)

%% 1. Definicion de los pacientes
% se utiliza posteriormente para generar el nombre de los archivos
% hupa de entrada al fk
patients = struct(	'name' ,    'BG', ...
					'year' ,    2013, ...
					'month',    5   , ...
					'dayStart', 15  , ...
					'dayEnd',   20);

patients(2) = struct(	'name' ,    'Cl', ...
						'year' ,    2013, ...
						'month',    6   , ...
						'dayStart', 13  , ...
						'dayEnd',   17);

patients(3) = struct(	'name' ,    'JB', ...
						'year' ,    2013, ...
						'month',    4   , ...
						'dayStart', 3   , ...
						'dayEnd',   9);

patients(4) = struct(	'name' ,    'ME', ...
						'year' ,    2013, ...
						'month',    5   , ...
						'dayStart', 15   , ...
						'dayEnd',   20);

						
%% 2. Definicion aritmetica Q12.4
% mediante las funciones numerictype y fimath se definen el tipo de punto
% fijo ( fixed-point-FI) que se va a utilizar y como se van a implementar las
% operaciones aritméticas con ese tipo de números

% Se establecen los parametros que definen la aritmetica a emplear
numberBits     = 64;
fractionalBits = 16;



% numerictype(s,w,f) creates a numerictype object with Fixed-point:
% binary point scaling, Signed property value s, word length w and
% fraction length f.
KF_t = numerictype( 'Signed', true, ...
                    'WordLength', numberBits, ...
                    'FractionLength', fractionalBits);
                
%fimath Set fixed-point math settings, es decir se fija la forma de
%operar con los números, pe el tipo de redondeo, número de bits del
%resultado de la suma y multiplicación etc. esto es importante porque aquí
%es donde se fija que la forma de trabajar es la misma del hw
%product mode:
%     FullPrecision
%     KeepLSB
%     KeepMSB
%     SpecifyPrecision-->In SpecifyPrecision mode, you must specify both 
%      word length and fraction length for sums and products.

%A veces el numero de elementos en cada fila es muy grande y es preferible introducir una fila en
%cada linea, lo unico que hay que hacer es terminar 
%la linea con tres puntos: . . . y teclear retorno
     KFArith = fimath(	'RoundingMethod'   , 'nearest', ...
					 'OverflowAction'   , 'Saturate', ...
					 'ProductMode'      , 'SpecifyPrecision', ...
					 'ProductWordLength', numberBits, ...
					 'ProductFractionLength', fractionalBits, ...
					 'SumMode', 'SpecifyPrecision', ...
					 'SumWordLength', numberBits, ...
					 'SumFractionLength', fractionalBits);
	
	
%% 3 generación parcial del nombre de los hupa
% se genera una cadena de texto que se almacena en filepref, que será parte 
% del nombre de archivo hupa que se quiere leer

patientIdx = patients(1);

%sprintf Format data into string
%La función sprintf es similar a printf salvo que imprime en una variable.
% la función sprintf convierte su resultado en una cadena de caracteres que
%devuelve como valor de retorno, en vez de enviarlo a un fichero
%se utiliza más adelante para fijar el nombre del fichero en el que se
%escribe
% Ejemplo de nombre de fichero para entender los parámetros que vienen a
% contiuación:BG_20130515_20130520_v2_day_1.csv
filePref = sprintf('%s_%d%.2d%.2d_%d%.2d%.2d_v2_day_', ...
    patientIdx.name, ...
    patientIdx.year, patientIdx.month, patientIdx.dayStart, ...
    patientIdx.year, patientIdx.month, patientIdx.dayEnd);
%% 4 parte sin mucha importancia, simplemente saca por la consola el nombre
% del paciente con el que se está trabajando

str      = sprintf('<strong>Patient</strong>: %s ... \n', patientIdx.name);
disp(str);

%disp-->Display text or array

%% 5 .- lectura de los 5 ficheros de un paciente
%lee los datos de los 5 ficheros hupa de un paciente y genera 
%la variable patientRawData que los contiene y que más tarde será la
%entrada del FK
cd(dataPath);

%zeros crea un array de ceros
patientRawData = zeros(1,3);
% hay cinco archivos por cada paciente
for i=1:5
    % strcat concatena cadenas de caracteres. con este comandose acaba de
    % crear el nombre del archivo al que se va a
    % acceder. los archivos son del tipo .csv (comma separated values)
    %(pueden ser importados y exportados a excel)
    file = strcat(filePref, num2str(i), '.csv');
   
    
    %exists.-comprueba si existe el archivo , para ello une mediante
    %fullfile el path del archivo con el nombre del mismo
    %exist--> Check existence of variable, function, folder, or class
    %exist('name','kind') if kind ==2 :
    %name exists on your MATLAB® search path as a file with extension .m.
    %name is the name of an ordinary file on your MATLAB search path.
    %name is the full pathname to any file.
    %if kind= file Checks only for files or folders.
    %fullfile--> Build full file name from parts
    %cd--> displays the current folder.
    if exist(fullfile(cd,file), 'file') == 2
        
        %si el archivo existe lo vuelca en forma de matriz en
        %la variable patientFileData 
        %dlmread--> Read ASCII-delimited file of numeric data into matrix
        %M = dlmread(filename, delimiter) reads data from the file, using
        %the specified delimiter.
        %lee TODA LA MATRIZ DE GOLPE ALMACENANDOLA EN LA VARIABLE COMO UNA
        %MATRIZ 
        %The most general Matlab function for reading text files is dlmread,
        %which can be used to import data from a text file defining the 
        %delimiter that was used to separate numbers.It can only be used 
        %to read  numbers,
        patientFileData = dlmread(file, ';');
    
        
        %patientFileData es sólo una variable auxiliar que vamos a
        %utilizar para construir la variable total patientRawData. para
        %ello añadimos a patientRawData el contenido de patientFileData.
        %como se puede observar en los hupa las medidas están repetidas 5
        %veces, por lo tanto para generar los datos finales sólo tenemos
        %que utilizar 1 de cada 5      
        %al crear matrices, ";" indica nueva fila
        %si al referenciar los elementos de una matriz hay tres ":"-->
        %el primer número inicio, el segundo incremento, el tercero final
        %A(i,:) is the ith row of A.
        patientRawData  = [patientRawData; patientFileData(1:5:length(patientFileData),:)];
    end
end
cd(scriptPath)
%clear-->Remove items from workspace, freeing up system memory
clear str file i patientFileData;

%% 6. Definicion de Time Series
%DE OSCAR
% Creamos los objetos Time Series y los agrupamos en una coleccion
% Eliminamos el primer elemento de la serie que es todo ceros
%MIO
% Una serie temporal o cronológica es una secuencia de datos, observaciones 
% o valores, medidos en determinados momentos y ordenados cronológicamente. 
% Los datos pueden estar espaciados a intervalos iguales (como la temperatura
% en un observatorio meteorológico en días sucesivos al mediodía) o desiguales 
% (como el peso de una persona en sucesivas mediciones en el consultorio
% médico, la farmacia, etc.).


%timeseries--> crea una serie temporal usando como datos
        %--fi(patientRawData(2:end,1) ;
        %--KF_t
        %--KFArith) 
% y la va a dar el nombre de glucose
%Time series are data vectors sampled over time, in order, 
%often at regular intervals.
%represent the time-evolution of a dynamic population or process.
%The linear ordering of time series gives them a distinctive place 
%in data analysis, with a specialized set of techniques.
%fi-->Construct fixed-point numeric object
%KF_t es el tipo definido más arriba
%KFArith es la aritmética definida más arriba 
glucose = timeseries(fi(patientRawData(2:end,1), KF_t, KFArith), 'Name', 'glucose');
glucose.DataInfo.Units = 'mg/dl';
glucose.TimeInfo.Units = 'minutes';
glucose.TreatNaNasMissing = true;

%como las mediciones se realizan cada 5 minutos el tiempo total de
%ejecución es el número total de datos x 5
dataTimeEnd_minutes = (glucose.length-1) * 5;

%disp(bin(glucose.data));

%definición de setuniformtime
%ts2 = setuniformtime(ts1,'StartTime',StartTime,'EndTime',EndTime)
%donde ts1 es la time serie ya definida
%el intervalo generado es  Interval = (EndTime - StartTime)/(length(ts1) - 1). en definitiva
%asigna a cada valor de timeseries  un valor de tiempo
glucose = setuniformtime(glucose, 'StartTime', 0, 'EndTime', dataTimeEnd_minutes);

responseKFKinsey2006 = glucose;%NO SE UTILIZA PARA NADA, PREGUNTAR A OSCAR
responseKFKinsey2006.name = 'Kinsey2006';

%tscollection-->Create tscollection object
% A time series collection object is a MATLAB variable that groups several 
% time series with a common time vector. The time series that you include in
% the collection are called members of this collection.
%tsc = tscollection({count1 count2},'name','tsc')Create a tscollection 
% object named tsc and add to it two out of three time series already in the
% MATLAB workspace
patient = tscollection({glucose ...
    responseKFKinsey2006}, ...
    'name',patientIdx.name);
patient.TimeInfo.Units = 'minutes';

% Define events

%tsdata.event-->Construct event object for timeseries object
%e = tsdata.event(Name,Time) --> creates an event object with the specified
% Name that occurs at the time Time. Time can either be a real value or
% a date string.
% Events are used to describe sudden changes in model behavior.
% An event lets you specify discrete transitions in model component values 
% that occur when a user-specified condition become true. 
% You can specify that the event occurs at a particular time, 
% or specify a time-independent condition.
firstDay        = tsdata.event('Midday', 0);
firstDay.Units  = 'hours';
secondDay       = tsdata.event('Midday', 24);
secondDay.Units = 'hours';
thirdDay        = tsdata.event('Midday', 48);
thirdDay.Units  = 'hours';
fourthDay       = tsdata.event('Midday', 72);
fourhtDay.Units = 'hours';


% addevent --->Add event to timeseries object
% ts = addevent(ts,e) adds one or more tsdata.event objects, e, 
% to the timeseries object ts. e is either a single tsdata.event object or 
% an array of tsdata.event objects.
glucose = addevent(glucose,firstDay);
glucose = addevent(glucose,secondDay);
glucose = addevent(glucose,thirdDay);
glucose = addevent(glucose,fourthDay);

clear *Day dataTimeEnd_minutes dayStart dayEnd name month year patientRawData;


%

%% 6. Ecuaciones explicitas KF KINSEY
% ecuaciones del modelo
%
% x[n+1]=Ax[n]+Gw[n]
% y[n]=Hx[n]+v[n]
%------------------------------------------------------------------------------
%número de estados de la X=4 :glucosa, velocidad  de la glucosa, 
%ganancia y velocidad de la ganancia
num_states      = 4;


%Q covarianza del ruido de proceso .
%Q_b10 indica que está en base decimal
%eye genera una matriz identidad
Q_b10 = 0.125;
Q_b10 = Q_b10 * eye(num_states);
Q     = fi(Q_b10, KF_t, KFArith);

% R covarianza del ruido de la medida
%primero en decimal despúes convetido a punto fijo
R_b10 = 1;
R     = fi(R_b10, KF_t, KFArith);

% A relates the state at the previous time step to the state at the current step
A_b10 = [1 1 0 0; 0 1 0 0; 0 0 1 1;0 0 0 1];
A     = fi(A_b10, KF_t, KFArith);

%Hc se utiliza para calcular la Hd que relates the
% state to the measurement 
Hc_b10 = [0.5 0 0.5 0];
Hc     = fi(Hc_b10, KF_t, KFArith); %es la H de bishop

% VALORES INICIALES DEL FILTRO

%I es la matriz identidad utilizada en la etapa de corrección
%num_states está definida más arriba e indica el número de estados= 4
%luego estamos creando una matriz identidad de 4x4
I_b10 = eye(num_states); 
I = fi(I_b10, KF_t, KFArith);

% P covarianza del error de estimación 
% se da un valor inicial
% ones devuelve una matriz nxn de unos
P_posteriori_b10    = 1 * ones(num_states);
P_posteriori        = fi(P_posteriori_b10, KF_t, KFArith);

% estado inicial 
initSt_b10          = [1 1 1 1];
x_posteriori_b10    = initSt_b10'; 
x_posteriori        = fi(x_posteriori_b10, KF_t, KFArith);

%iniciación de la ganancia kalman K
K                   = fi(zeros(num_states,1), KF_t, KFArith);

%iniciación de la Hd dinámica que se usa en los calculos de corrección
Hd           =   fi(zeros(1,num_states), KF_t, KFArith);

% inicialización de KDndo y KDsor  que se utilizan para hallar la ganancia Kalman en
% dos partes
KDndo        = fi(zeros(num_states,1), KF_t, KFArith);
KDsor        = fi(zeros(1,1), KF_t, KFArith);

%iniciación de variables que se utilizan para depuración y obtener
%diferentes datos
ye_b10           = zeros(glucose.Length,1);
ye           = fi(ye_b10, KF_t, KFArith);

ycov_b10         = zeros(glucose.Length,1);
ycov         = fi(ycov_b10, KF_t, KFArith);

errcov_b10       = zeros(glucose.Length,1);
errcov       = fi(errcov_b10, KF_t, KFArith);

%inicialización de responseKFKinseyModel
% es la estructura de datos que recoge los resultados de la ejecución del
% filtro
% la estrucutra sera una matriz con glucose.length filas, es decir tantas 
%filas como los datos de entrada, en número de columnas es variable
%y depende de la información que queramos guardar- plotar
responseKFKinseyModel = fi(zeros(glucose.length,12), KF_t, KFArith);

%EJECUCIÓN DEL FILTRO

for i=1:glucose.Length
    % FASE DE PREDICCIÓN
    
    x_priori = A * x_posteriori;            
    P_priori = A * P_posteriori * A' + Q;    
    
    % FASE DE CORRECCIÓN
    % cálculo de la Hd dinamica
    % es dinámica porque depende de los valores de glucosa y ganancia
    % obtenidos en X_priori
       %calculo de la H dinámica
    Hd(1)=  0.50 .* x_priori(3);
    Hd(3)=  0.50 .* x_priori(1);
    % Hd_b10=Hc_b10;
    
    % Calculation of the Kalman gain has to be splitted into two
    % operations. If not (that is, if the operation is performed in one
    % single equation the fractional length of the result would be 0 and
    % the kalman gain was erroneous.
    %     K = P_priori * C'/(C * P_priori * C' + R);  <--- Erroneous
    
      
    %calcula el primer factor de K
    KDndo        = P_priori * Hd';
    % calcula el segundo factor de K
    KDsor        = (Hd * P_priori * Hd' + R);
    
    %divide 
    % c = divide(T,a,b) performs division on the elements of a by the
    % elements of b. The result c has the numerictype object T
    K            = divide(KF_t, KDndo, KDsor);
    
    % C es la H de bishop
    z=glucose.Data(i);
    x_posteriori = x_priori + K * (z - Hd * x_priori);      
    P_posteriori = (I - K * Hd) * P_priori;  
    
    %ye(i) es la medida predicha 
    ye(i) = Hd * x_posteriori;
    errcov(i) = Hd * P_posteriori * Hd';
    %la diez columnas de la respuesta son las siguientes:
    % ye es la medición predicha que es un valor
    %x tanto posteriori como a priori tienen tres valores cada uno
    % la ganancia kalman tiene 3 valores
    %por eso en total se definen 10 coumnas
    %responseKFKinseyModel(i,:) = [ye(i) x_posteriori' x_priori' K'];
   responseKFKinseyModel(i,:) = [x_posteriori' x_priori' K'];
%      disp('este es el cálculo');
%      disp(i);
%      disp(bin(glucose.Data(i)));
   
end

%bin-->Binary representation of stored integer of fi object
responseKFKinseyModel_fi = bin(responseKFKinseyModel);
%fileName = strcat('../results/', patientIdx.name, 'Glucose_KF_MatLab_Q12.4.txt');
fileName = strcat('K:/fk_kinsey_06/sim/Kinsey2006/','KinseyFilter_Q12_4_CC.txt');
fileID = fopen(fileName,'w');
for i=1:length(responseKFKinseyModel_fi)
    % s-->string de caracteres
    % \n --> New line
    % parece que 16 indica el mínimo número de caracteres a imprimir
   fprintf(fileID,'%16s\n',responseKFKinseyModel_fi(i,:));
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
fileFig = strcat('K:/fk_kinsey_06/sim/Kinsey2006/', 'KinseyFilter_Q12_4_CC');

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

