
close all;
run('../../SOURCES_MATLAB/SF_Start.m');verbosity=10;
system('mkdir FIGURES');
figureformat = 'png';

%% CHAPTER 0
gamma=0.002;
rhog=1;
R = 1;
L =2;


density=100;
 %creation of an initial mesh 
 
ffmesh = SF_Mesh('MeshInit_Vessel.edp','Params',[L density]);
ffmesh = SF_Mesh_Deform(ffmesh,'P',0,'gamma',gamma,'rhog',rhog,'typestart','pined','typeend','axis');
%figure();plot(ffmesh.xsurf,ffmesh.ysurf);hold on;quiver(ffmesh.xsurf,ffmesh.ysurf,ffmesh.N0r,ffmesh.N0z); % to plot normal vectors
 
%% CHAPTER 1 : flat surface, free condition, INVISCID
disp('###first test : flat surface, free condition')


[evm1,emm1] =  SF_Stability(ffmesh,'nev',10,'m',1,'shift',2.1i,'typestart','freeV','typeend','axis');
% NB with this value of the shift the modes number n=1,2,3 will be found with index (2,1,3)

evTheory = [1.3606    2.3737    3.1274]; % see script Analytical solution
error1 = abs(imag(evm1(2))/evTheory(1)-1)+abs(imag(evm1(1))/evTheory(2)-1)+abs(imag(evm1(3))/evTheory(3)-1)

figure(1);
plot(imag(evm1),0*real(evm1),'r+');hold on;
legend('flat, free');

figure(2);suptitle('m=1 sloshing modes : Horizontal surface, free condition');hold on;
subplot(1,3,1);
plotFF(emm1(2),'phi.im','title',{'Mode (m,n)= (1,1)',['freq = ',num2str(imag(evm1(2)))]},'symmetry','YA');hold on;plotFF_ETA(emm1(2),'symmetry','YA');
subplot(1,3,2);
plotFF(emm1(1),'phi.im','title',{'Mode (m,n)= (1,2)',['freq = ',num2str(imag(evm1(1)))]},'symmetry','YA');hold on;plotFF_ETA(emm1(1),'symmetry','YA');
subplot(1,3,3);
plotFF(emm1(3),'phi.im','title',{'Mode (m,n)= (1,3)',['freq = ',num2str(imag(evm1(3)))]},'symmetry','YA');hold on;plotFF_ETA(emm1(3),'symmetry','YA');
pos = get(gcf,'Position'); pos(3)=pos(4)*2.6;set(gcf,'Position',pos); % resize aspect ratio

pause;

%% CHAPTER 2 : flat surface, pined condition

disp('### Second test : flat surface, pined condition')

[evm1,emm1] =  SF_Stability(ffmesh,'nev',10,'m',1,'shift',2.1i,'typestart','pined','typeend','axis');

evTheory = [1.4444    2.4786    3.2671]; % There is a paper by Miles with analytical solution... 
error2 = abs(imag(evm1(2))/evTheory(1)-1)+abs(imag(evm1(1))/evTheory(2)-1)+abs(imag(evm1(3))/evTheory(3)-1)

figure(1);
plot(imag(evm1),0*real(evm1),'b+');hold on;
legend('flat, pined');

figure(3);suptitle('m=1 sloshing modes : Horizontal surface, H/R = 2, Bo = 500, pined condition');hold on;
subplot(1,3,1);
plotFF(emm1(2),'phi.im','title',{'Mode (m,n)= (1,1)',['freq = ',num2str(imag(evm1(2)))]},'symmetry','YA');hold on;plotFF_ETA(emm1(2),'symmetry','YA');
subplot(1,3,2);
plotFF(emm1(1),'phi.im','title',{'Mode (m,n)= (1,2)',['freq = ',num2str(imag(evm1(1)))]},'symmetry','YA');hold on;plotFF_ETA(emm1(1),'symmetry','YA');
subplot(1,3,3);
plotFF(emm1(3),'phi.im','title',{'Mode (m,n)= (1,3)',['freq = ',num2str(imag(evm1(3)))]},'symmetry','YA');hold on;plotFF_ETA(emm1(3),'symmetry','YA');
pos = get(gcf,'Position'); pos(3)=pos(4)*2.6;set(gcf,'Position',pos); % resize aspect ratio

pause;



%% Chapter 3 : meniscus (theta = 45?), free conditions

% This case is the same as in Viola, Gallaire & Brun

% first compute equilibrium shape and corresponding mesh
gamma = 0.002;
thetaE = pi/4;
hmeniscus = sqrt(2*gamma*(1-sin(thetaE))); % this is the height of the meniscus (valid for large Bond)
%ffmesh = SF_Mesh('MeshInit_Vessel.edp','Params',[L+hmeniscus, density]);
ffmesh = SF_Mesh('MeshInit_Vessel.edp','Params',[L, density]);
P = -rhog*hmeniscus; % pressure in the liquid at z=0 (altitude of the contact line) ; the result will be to lower the interface by this ammount 
ffmesh = SF_Mesh_Deform(ffmesh,'P',P,'gamma',gamma,'rhog',rhog,'typestart','pined','typeend','axis');
Vol0 = ffmesh.Vol % volume
alphastart = ffmesh.alpha(1)*180/pi % this should be 225 degrees (angle with respect to vertical = 45 degrees)


[evm1,emm1] =  SF_Stability(ffmesh,'nev',10,'m',1,'shift',2.1i,'typestart','freeV','typeend','axis');

evTheory = [1.3587    2.3630    3.1118]; 
error3 = abs(imag(evm1(2))/evTheory(1)-1)+abs(imag(evm1(1))/evTheory(2)-1)+abs(imag(evm1(3))/evTheory(3)-1)

figure(1);
plot(imag(evm1),0*real(evm1),'g+');hold on;
legend('meniscus, free');

figure(4);suptitle('m=1 sloshing modes : Meniscus (45?), H/R = 2, Bo = 500, free condition');hold on;
subplot(1,3,1);
plotFF(emm1(2),'phi.im','title',{'Mode (m,n)= (1,1)',['freq = ',num2str(imag(evm1(2)))]},'symmetry','YA');hold on;plotFF_ETA(emm1(2),'Amp',0.05,'symmetry','YA');
subplot(1,3,2);
plotFF(emm1(1),'phi.im','title',{'Mode (m,n)= (1,2)',['freq = ',num2str(imag(evm1(1)))]},'symmetry','YA');hold on;plotFF_ETA(emm1(1),'Amp',0.05,'symmetry','YA');
subplot(1,3,3);
plotFF(emm1(3),'phi.im','title',{'Mode (m,n)= (1,3)',['freq = ',num2str(imag(evm1(3)))]},'symmetry','YA');hold on;plotFF_ETA(emm1(3),'Amp',0.05,'symmetry','YA');
pos = get(gcf,'Position'); pos(3)=pos(4)*2.6;set(gcf,'Position',pos); % resize aspect ratio


%% check if boundary condition is correctly verified
figure(51);title('eta (plain), - d eta /ds + K0a cot(alpha) eta (dashed), limit (dotted)');
DetaDs = diff(emm1(1).eta)./diff(ffmesh.S0);
plot(ffmesh.xsurf,real(emm1(1).eta),'-'); hold on; 
plot((ffmesh.xsurf(1:end-1)+ffmesh.xsurf(2:end))/2,DetaDs,'--');
plot(ffmesh.xsurf,-ffmesh.K0a.*cot(ffmesh.alpha).*(abs(cot(ffmesh.alpha))<1e2).*emm1(1).eta);


%% Chapter 4 : meniscus (theta = 45?), VISCOUS, m=1

nu = 1e-2;
m=1;sym =  'YA';% YS if m is even, YA if m is odd
[evm1,emm1] =  SF_Stability(ffmesh,'nev',10,'m',1,'nu',nu,'shift',2.1i,'typestart','freeV','typeend','axis');

%evTheory = [1.3587    2.3630    3.1118]; 
%error4 = abs(imag(evm1(2))/evTheory(1)-1)+abs(imag(evm1(1))/evTheory(2)-1)+abs(imag(evm1(3))/evTheory(3)-1)
figure(5);
suptitle(['Sloshing modes : Meniscus (45?), H/R = 2, Bo = ' num2str(1/gamma) '; Oh = ' num2str(nu)  '; m = ' num2str(m) ]);hold on;
subplot(1,3,1);
plotFF(emm1(2),'uz1.im','title',{'Mode (m,n)= (1,1)',['\omega_r = ',num2str(imag(evm1(1))),', \omega_i = ',num2str(real(evm1(1)))]},'symmetry',sym);hold on;
plotFF_ETA(emm1(2),'Amp',0.05,'symmetry',sym);xlim([-1 1]);ylim([-2,.5]);
subplot(1,3,2);
plotFF(emm1(1),'uz1.im','title',{'Mode (m,n)= (1,2)',['\omega_r = ',num2str(imag(evm1(2))),', \omega_i = ',num2str(real(evm1(2)))]},'symmetry',sym);hold on;
plotFF_ETA(emm1(1),'Amp',0.05,'symmetry',sym);xlim([-1 1]);ylim([-2,.5]);
subplot(1,3,3);
plotFF(emm1(3),'uz1.im','title',{'Mode (m,n)= (1,3)',['\omega_r = ',num2str(imag(evm1(3))),', \omega_i = ',num2str(real(evm1(3)))]},'symmetry',sym);hold on;
plotFF_ETA(emm1(3),'Amp',0.05,'symmetry',sym);xlim([-1 1]);ylim([-2,.5]);
pos = get(gcf,'Position'); pos(3)=pos(4)*2.6;set(gcf,'Position',pos); % resize aspect ratio


%% Chapter 5 : meniscus (theta = 45?), free conditions m=0

% This case is the same as in Viola, Gallaire & Brun

nu = 1e-3;
m=0;sym =  'YS';% YS if m is even, YA if m is odd
[evm1,emm1] =  SF_Stability(ffmesh,'nev',10,'m',m,'nu',nu,'shift',2.1i,'typestart','freeV','typeend','axis');


%evTheory = [1.3587    2.3630    3.1118]; 
%error4 = abs(imag(evm1(2))/evTheory(1)-1)+abs(imag(evm1(1))/evTheory(2)-1)+abs(imag(evm1(3))/evTheory(3)-1)

figure(6);hold off;
suptitle(['Sloshing modes : Meniscus (45?), H/R = 2, Bo = ' num2str(1/gamma) '; Oh = ' num2str(nu)  '; m = ' num2str(m) ]);hold on;
subplot(1,3,1);
plotFF(emm1(1),'uz1.im','title',{'Mode (m,n)= (0,1)',['\omega_r = ',num2str(imag(evm1(1))),', \omega_i = ',num2str(real(evm1(1)))]},'symmetry',sym);
hold on;plotFF_ETA(emm1(1),'Amp',0.05,'symmetry','YS');xlim([-1 1]);ylim([-2,.5]);
subplot(1,3,2);
plotFF(emm1(2),'uz1.im','title',{'Mode (m,n)= (0,2)',['\omega_r = ',num2str(imag(evm1(2))),', \omega_i = ',num2str(real(evm1(2)))]},'symmetry',sym);
hold on;plotFF_ETA(emm1(2),'Amp',0.05,'symmetry','YS');xlim([-1 1]);ylim([-2,.5]);
subplot(1,3,3);
plotFF(emm1(3),'uz1.im','title',{'Mode (m,n)= (0,3)',['\omega_r = ',num2str(imag(evm1(3))),', \omega_i = ',num2str(real(evm1(3)))]},'symmetry',sym);
hold on;plotFF_ETA(emm1(3),'Amp',0.05,'symmetry','YS');xlim([-1 1]);ylim([-2,.5]);
pos = get(gcf,'Position'); pos(3)=pos(4)*2.6;set(gcf,'Position',pos); % resize aspect ratio





%% Chapter 7 : meniscus (theta = 45?), free conditions m=2

% This case is the same as in Viola, Gallaire & Brun

nu = 1e-3;
[evm1,emm1] =  SF_Stability(ffmesh,'nev',10,'m',2,'nu',nu,'shift',2.1i,'typestart','freeV','typeend','axis');
m=2;sym =  'YS';% YS if m is even, YA if m is odd

%evTheory = [1.3587    2.3630    3.1118]; 
%error4 = abs(imag(evm1(2))/evTheory(1)-1)+abs(imag(evm1(1))/evTheory(2)-1)+abs(imag(evm1(3))/evTheory(3)-1)

figure(7);hold off;
suptitle(['Sloshing modes : Meniscus (45?), H/R = 2, Bo = ' num2str(1/gamma) '; Oh = ' num2str(nu)  '; m = ' num2str(m) ]);hold on;
subplot(1,3,1);
plotFF(emm1(1),'uz1.im','title',{'Mode (m,n)= (2,1)',['\omega_r = ',num2str(imag(evm1(1))),', \omega_i = ',num2str(real(evm1(1)))]},'symmetry',sym);
hold on;plotFF_ETA(emm1(1),'Amp',0.05,'symmetry','YS');xlim([-1 1]);ylim([-2,.5]);
subplot(1,3,2);
plotFF(emm1(2),'uz1.im','title',{'Mode (m,n)= (2,2)',['\omega_r = ',num2str(imag(evm1(2))),', \omega_i = ',num2str(real(evm1(2)))]},'symmetry',sym);
hold on;plotFF_ETA(emm1(2),'Amp',0.05,'symmetry','YS');xlim([-1 1]);ylim([-2,.5]);
subplot(1,3,3);
plotFF(emm1(3),'uz1.im','title',{'Mode (m,n)= (2,3)',['\omega_r = ',num2str(imag(evm1(3))),', \omega_i = ',num2str(real(evm1(3)))]},'symmetry',sym);
hold on;plotFF_ETA(emm1(3),'Amp',0.05,'symmetry','YS');xlim([-1 1]);ylim([-2,.5]);
pos = get(gcf,'Position'); pos(3)=pos(4)*2.6;set(gcf,'Position',pos); % resize aspect ratio









