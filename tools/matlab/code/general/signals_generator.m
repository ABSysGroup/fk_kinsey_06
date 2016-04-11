


% y = x + 2*rand(size(t));
% 
% wgn(): 
% awgn (mi_señal, snr);

% EXPONENCIAL DECRECIENTE-.El siguiente programa genera y grafica una
% exponencial decreciente . ver figura 1-9


% t es la variable tiempo, el tíempo total que queremos estudiar
% en este caso lo fijamos a 1446 que es el número total de muestras que
% tenemos
%T0 es el tiempo de decamiento, en este caso lo fijamos a la mitad de las
%muestras
 t = 0:1440; %se van a graficar 51 muestras
 T0=723;
 v = exp(-t/T0);
 stem(n,v); 
 disp(v);
 plot(v);


% generación de una señal exponencial discreta 
% Genere una Señal Exponencial Decreciente en Tiempo Discreto, la cual tendrá una A (amplitud)
% de 1, Un intervalo de tiempo de n= -0:25 , y un ancho de 0.85
% Para generar una Señal Exponencial Decreciente en Tiempo Discreto, empleamos el siguiente conjunto
% completo de comandos, tomando en cuenta que para la representación de la señal exponencial en
% Tiempo Discreto utilizamos la siguiente formula x = A(altura)*r(ancho).^n(tiempo Discreto):
% 
% %parametros de la exponencial
% A = 1;  %amplitud
% t0 = 0.999;%tiempo de decaimiento
% t = -0:1435;%numero de muestras
% 
% %generación de la exponencial
% x = A*t0.^(t);
% %valor de glucosa en sangre
% BG=100;
% 
% % desviación estandar
% de=2;
% 
% 
% %señal leida
%  z=BG.*x+ de.*rand(1,1436)
%  
%  plot(z);

% stem(n,z,'c') % Para Graficar el t y tri
% title('Exponencial decreciente'); %Titulo de la hoja grafica
% xlabel('Tiempo t'); %personifica el eje X
% ylabel('x(t)'); %Personifica el eje Y
% legend('Señal'); %personifica la señal 


clear r;


