function value = autorun(isfigures);
% Autorun function for StabFem. 
% This function will produce sample results for the wake of a cylinder with STABFEM  
%  - Base flow computation
%  - Linear stability
%  - WNL
%  - Harmonic Balance
%
% USAGE : 
% autorun(0) -> automatic check (non-regression test). Result is the
% number of unsuccessful tests
% autorun(1) -> produces the figures (in present case not yet any figures)

%% Chapter 0 : reference values for non-regression tests
np_REF = 2241;
Fx_REF =  0.6435;
ev_REF =   0.0131 + 0.7377i;
Rec_REF =   46.7338;
Lxc_REF =    3.1999;
Omegac_REF =    0.7333;

Lambda_REF = 9.1737 + 3.2631i;
nu0_REF = 3.1349e+01 - 1.0253e+02i;
nu2_REF = -1.0238 - 3.0298i;
              
Lx_HB_REF =    3.1806;
Fx_HB_REF =    0.7089;
omega_HB_REF =    0.7373;
Aenergy_HB_REF =    0.4899;
Fy_HB_REF =   0.0063 - 0.0000i;

Lx_HB2_REF =   3.1794;
Fx_HB2_REF =   0.7090;
omega_HB2_REF =    0.7376;
Aenergy_HB2_REF = 0.4950;
Fy_HB2_REF =   0.0064 + 0.0000i;
Fx2_HB2_REF = 2.3529e-06 - 4.4469e-06i;


%% ##### CHAPTER 1 : COMPUTING THE MESH WITH ADAPTMESH PROCEDURE
run('../../SOURCES_MATLAB/SF_Start.m');verbosity=0;

type = 'S';
bf = CYLINDER_MESHGENERATION(type); 
% here use 'S' for mesh M2 (converged results for all quantities except for A_E , but much faster
% or 'D' for mesh M4 (converged results for all quantities, but much slower)
value = 0;
disp('autorun : mesh and BASE FLOW');
error1 = abs(bf.Fx-Fx_REF)+abs(bf.mesh.np-np_REF)
if(error1>1e-3) 
    value = value+1 
end


%%  CHAPTER 2 : linear mode for Re=50


disp('autorun : LINEAR MODE');
bf=SF_BaseFlow(bf,'Re',50);
[ev,em] = SF_Stability(bf,'shift',+.75i,'nev',1,'type','S');

error2 = abs(ev-ev_REF)
if(error2>1e-3) 
    value = value+1 
end

%%  CHAPTER 3 : determining instability threshold


disp('autorun : COMPUTING INSTABILITY THRESHOLD');
[bf,em]=SF_FindThreshold(bf,em);

Rec = bf.Re;
Lxc=bf.Lx;    
Omegac=imag(em.lambda);

error3 = abs(Rec-Rec_REF)+abs(Lxc-Lxc_REF)+abs(Omegac-Omegac_REF)
if(error3>1e-3) 
    value = value+1
end


%% Chapter 4 : solve WNL model and uses it to generate a guess for Res (just above the threshold)
disp('autorun : WNL');

Res = 47;
[ev,em] = SF_Stability(bf,'shift',ev,'nev',1,'type','S'); % type S = direct+adjoint (adjoint is needed for WNL)
[wnl,meanflow,mode,mode2] = SF_WNL(bf,em,'Retest',Res);

error4 = abs(wnl.Lambda/Lambda_REF-1)+abs(wnl.nu0/nu0_REF-1)+abs(wnl.nu2/nu2_REF-1)
if(error4>1e-3) 
    value = value+1
end


%% CHAPTER 5 : SELF CONSISTENT (or HB1), INITIATED BY LINEAR RESULTS WITH A GUESS
%             (alternative to the method using the WNL as a guess)
%
% HERE the initial guess is for Re=47 (slightly above the instability threshold)
% The initialisation is done with the linear eigmode
% with a "small" amplitude (measured by lift force), namely Fy=0.006 .



    disp(' ');disp('###### autorun : HB1 #######');disp(' ');
    [meanflow,mode] = SF_HB1(meanflow,mode,'Re',Res);
    Lx_HB = meanflow.Lx;
    Fx_HB = meanflow.Fx;
    omega_HB = imag(mode.lambda);
    Aenergy_HB  = mode.AEnergy;
    Fy_HB = mode.Fy;
    
error5 = abs(Lx_HB-Lx_HB_REF)+abs(Fx_HB-Fx_HB_REF)+abs(omega_HB-omega_HB_REF)+abs(Aenergy_HB-Aenergy_HB_REF)+abs(Fy_HB-Fy_HB_REF)
if(error5>1e-3) 
    value = value+1
end



%% CHAPTER 6 : HARMONIC BALANCE WITH ORDER 2 


Re = 47;
[meanflow,mode,mode2] = SF_HB2(meanflow,mode,mode2,'Re',Re);
    Lx_HB2 = meanflow.Lx;
    Fx_HB2 = meanflow.Fx;
    omega_HB2 = imag(mode.lambda);
    Aenergy_HB2  = sqrt(mode.AEnergy^2+ mode2.AEnergy^2);
    Fy_HB2 = mode.Fy;
    Fx2_HB2 = mode2.Fx;
    
error6 = abs(Lx_HB2-Lx_HB2_REF)+abs(Fx_HB2-Fx_HB2_REF)+abs(omega_HB2-omega_HB2_REF)+abs(Aenergy_HB2-Aenergy_HB2_REF)+abs(Fy_HB2-Fy_HB2_REF)
if(error6>1e-3) 
    value = value+1
end

end