function [baseflow,eigenmode] = SF_Adapt(varargin)
% 
% This is part of StabFem Project, version 2.1, D. Fabre, July 2017
% Matlab driver for Adapting Mesh 
%
% usage : [baseflow] = SF_Adapt(baseflow,eigenmode)
%
% with only one input argument the adaptation will be done only on base
% flow.
%
% with two input arguments the adaptation will be done on base flow and
% eigenmode structure.
%
%
% The base flow (and if specified the eigenmode) will be recomputed on
% adapted mesh
%
% improved usage : [baseflow,eigenmode] = SF_Adapt(baseflow,eigenmode)
% eigenmode will also be recomputed (works in 2D but nor recommended)
%
% Version 2.1 by D. Fabre, 2 july 2017

global ff ffdir ffdatadir sfdir verbosity

% managament of optional parameters
% NB here the parser had to be customized because input parameter number 2
% is optional and is a structure ! we should find a better way in future
p = inputParser;
if(mod(nargin,2)==1)
    % input mode for adaptation to base flow
    baseflow=varargin{1};
    eigenmode=0;
    vararginopt={varargin{2:end}};
else
     % input mode for adaptation to base flow
    baseflow=varargin{1};
    eigenmode=varargin{2};
    vararginopt={varargin{3:end}};
end
%    addRequired(p,'baseflow');
%    addOptional(p,'eigenmode',0);
addParameter(p,'Hmax',10);
addParameter(p,'Hmin',1e-4);
addParameter(p,'Ratio',10.);               	
addParameter(p,'InterpError',1e-2);			
addParameter(p,'rr',0.95);
addParameter(p,'Splitin2',0); 
parse(p,vararginopt{:});
    
% mycp('mesh.msh','mesh_ans.msh');
% mycp('BaseFlow.txt','BaseFlow_ans.txt');

%%% Writing parameter file for Adapmesh
fid = fopen('Param_Adaptmesh.edp','w');
fprintf(fid,'// Parameters for adaptmesh (file generated by matlab driver)\n');
fprintf(fid,['real Hmax = ',num2str(p.Results.Hmax),' ;']);
fprintf(fid,['real Hmin = ',num2str(p.Results.Hmin),' ;']);
fprintf(fid,['real Ratio = ',num2str(p.Results.Ratio),' ;']);
fprintf(fid,['real error = ',num2str(p.Results.InterpError),' ;']);
 fprintf(fid,['real rr = ',num2str(p.Results.rr),' ;']);
if(p.Results.Splitin2==0)
    fprintf(fid,['bool Splitin2 = false ;']);
else
    fprintf(fid,['bool Splitin2 = true ;']);
end
fclose(fid);

disp(' '); 



if(isnumeric(eigenmode)==1) %% if no eigenmode is provided as input : adapt to base flow only
  command = ['echo BFonly | ',ff,' ',ffdir,'Adapt_Mode.edp'];
  error = 'ERROR : FreeFem adaptmesh aborted';
  mysystem(command,error);
  meshnp = importFFmesh('mesh.msh','nponly');
  disp(['      ### ADAPT mesh to base flow ' ...% for Re = ' num2str(baseflow.Re)... 
            ' ; InterpError = ' num2str(p.Results.InterpError) '  ; Hmax = ' num2str(p.Results.Hmax) ])  
  if(verbosity>=1)
  meshinfo = importFFdata(baseflow.mesh,'mesh.ff2m');
  disp(['      #   Number of points np = ',num2str(meshinfo.np), ...
        ' ; Ndof = ', num2str(meshinfo.Ndof)]);
  disp(['      #  h_min, h_max : ',num2str(meshinfo.deltamin), ' , ',...
        num2str(meshinfo.deltamax)]);    
%  disp(['      # h_(A,B,C,D) : ',num2str(meshinfo.deltaA),' , ',...
%        num2str(meshinfo.deltaB),' , ',num2str(meshinfo.deltaC),' , ',num2str(meshinfo.deltaD) ]);    
  end
  
  
else % Adaptation to base flow + mode (or other specified field)
    if(strcmp(baseflow.mesh.problemtype,'AxiXR')==1)
        mycp([ffdatadir 'Eigenmode.txt'],[ffdatadir 'AdaptField.txt']);
        command = ['echo UVWP | ',ff,' ',ffdir,'Adapt_Mode.edp'];
        
    elseif (strcmp(baseflow.mesh.problemtype,'2D')==1)
        if(strcmp(eigenmode.type,'D')==1)
            command = ['echo UVP | ',ff,' ',ffdir,'Adapt_Mode.edp'];
            mycp([ffdatadir 'Eigenmode.txt'],[ffdatadir 'AdaptField.txt']);
        elseif(strcmp(eigenmode.type,'A')==1)
             command = ['echo UVP | ',ff,' ',ffdir,'Adapt_Mode.edp'];
            mycp([ffdatadir 'EigenmodeA.txt'],[ffdatadir 'AdaptField.txt']);
        else %if(strcmp(eigenmode.type,'S')==1)
             command = ['echo Sensitivity | ',ff,' ',ffdir,'Adapt_Mode.edp'];
            mycp([ffdatadir 'Sensitivity.txt'],[ffdatadir 'AdaptField.txt']);
        end
       
    % elseif(..) for possible other drivers
    end
   error = 'ERROR : FreeFem adaptmesh aborted';
    status=mysystem(command,'skip');
    if(status~=0)
        mymv([ffdatadir 'mesh_ans.msh'],[ffdatadir 'mesh.msh']);
        mymv([ffdatadir 'BaseFlow_ans.txt'],[ffdatadir 'BaseFlow.txt']);
        mymv([ffdatadir 'BaseFlow_ans.txt'],[ffdatadir 'BaseFlow_guess.txt']);
        error(' ERROR in SF_Adapt : recomputing base flow failed, going back to baseflow/mesh')
    end
%    meshnp = importFFmesh('mesh_adapt.msh','nponly'); // old version to
%    discard this and correct soon
     
     disp(['      ### ADAPT mesh to base flow AND MODE ( type ',eigenmode.type,... ' )  for Re = ' num2str(baseflow.Re)... 
            ' ) ; InterpError = ' num2str(p.Results.InterpError) '  ; Hmax = ' num2str(p.Results.Hmax) ])     
%     disp([' ; Number of points np = ',num2str(meshinfo.np) ' ; Ndof = ' num2str(meshinfo.Ndof)]; ])
if(verbosity>=1)    
meshinfo = importFFdata(baseflow.mesh,'mesh.ff2m');
  disp(['      #   Number of points np = ',num2str(meshinfo.np), ...
        ' ; Ndof = ', num2str(meshinfo.Ndof)]);
  disp(['      #  deltamin, deltapax : ',num2str(meshinfo.deltamin), ' , ',...
        num2str(meshinfo.deltamax)]);    
%  disp(['      #  delta_(A,B,C,D) : ',num2str(meshinfo.deltaA),' , ',...
%        num2str(meshinfo.deltaB),' , ',num2str(meshinfo.deltaC),' , ',num2str(meshinfo.deltaD) ]); 
end
 end
   
   
    % recomputing base flow after adapt
%      mycp('mesh_adapt.msh','mesh.msh');
%      mycp('BaseFlow_adaptguess.txt','BaseFlow_guess.txt');
    baseflowNew = baseflow; % initialise structure
    baseflowNew.mesh=importFFmesh([ffdatadir 'mesh.msh']);
    
    baseflowNew = SF_BaseFlow(baseflowNew,'Re',baseflow.Re,'type','NEW');
    if(baseflowNew.iter>0)
		%  Newton successful : store base flow
		baseflow=baseflowNew;
<<<<<<< HEAD
		baseflow.mesh.namefile=[ffdatadir 'BASEFLOWS/mesh_adapt_Re' num2str(baseflow.Re) '.msh'];
    	mycp([ffdatadir 'BaseFlow.txt'],[ffdatadir 'BASEFLOWS/BaseFlow_adapt_Re' num2str(baseflow.Re) '.txt']);
        baseflow.namefile = [ ffdatadir 'BASEFLOWS/BaseFlow_Re' num2str(baseflow.Re) '.txt'];
        mycp([ffdatadir 'mesh.msh'],[ffdatadir 'BASEFLOWS/mesh_adapt_Re' num2str(baseflow.Re) '.msh']);
    	 % clean 'BASEFLOWS' directory to avoid mesh/baseflow incompatibilities
         myrm([ffdatadir 'BASEFLOWS/BaseFlow_Re*']);
         mycp([ffdatadir 'BaseFlow.txt'],[ffdatadir 'BASEFLOWS/BaseFlow_Re' num2str(baseflow.Re) '.txt']);
    	 mycp([ffdatadir 'BaseFlow.ff2m'],[ffdatadir 'BASEFLOWS/BaseFlow_Re' num2str(baseflow.Re) '.ff2m']);
         
=======
		baseflow.mesh.namefile=[ffdatadir '/BASEFLOWS/mesh_adapt_Re' num2str(baseflow.Re) '.msh'];
    	system(['cp ' ffdatadir 'BaseFlow.txt ' ffdatadir '/BASEFLOWS/BaseFlow_adapt_Re' num2str(baseflow.Re) '.txt']);
    	baseflow.namefile = [ ffdatadir '/BASEFLOWS/BaseFlow_Re' num2str(baseflow.Re) '.txt'];
    	system(['cp ' ffdatadir 'mesh.msh ' ffdatadir '/BASEFLOWS/mesh_adapt_Re' num2str(baseflow.Re) '.msh']);
    	 % clean 'BASEFLOWS' directory to avoid mesh/baseflow incompatibilities
    	 system(['rm ' ffdatadir 'BASEFLOWS/BaseFlow_Re*']); 
         system(['cp ' ffdatadir 'BaseFlow.txt ' ffdatadir '/BASEFLOWS/BaseFlow_Re' num2str(baseflow.Re) '.txt']);%except last one...`
         system(['cp ' ffdatadir 'BaseFlow.ff2m ' ffdatadir '/BASEFLOWS/BaseFlow_Re' num2str(baseflow.Re) '.ff2m']);%except last one...
    	 
>>>>>>> StabFemOriginal/master
         % in case requested, recompute the eigenmode as well
         if(nargout==2&&isnumeric(eigenmode)==0)
            if(strcmp(baseflow.mesh.problemtype,'AxiXR')==1) 
                [ev,eigenmode]=SF_Stability(baseflow,'m',eigenmode.m,'shift',eigenmode.lambda,'nev',1,'type',eigenmode.type);
            elseif(strcmp(baseflow.mesh.problemtype,'2D')==1)
                if(strcmp(eigenmode.type,'D')==1) 
                      mycp([ffdatadir 'AdaptField_guess.txt'],[ffdatadir 'Eigenmode_guess.txt']);
                else
                    myrm([ffdatadir 'Eigenmode_guess.txt']);
                end
                [ev,eigenmode]=SF_Stability(baseflow,'shift',eigenmode.lambda,'nev',1,'type',eigenmode.type);
            end
         end
   	else % Newton has probably diverged : revert to previous mesh/baseflow
        mymv([ffdatadir 'mesh_ans.msh'],[ffdatadir 'mesh.msh']);
        mymv([ffdatadir 'BaseFlow_ans.txt'],[ffdatadir 'BaseFlow_guess.txt']);
        error(' ERROR in SF_Adapt : recomputing base flow failed, going back to baseflow/mesh') 
    end
<<<<<<< HEAD
        myrm([ffdatadir '*_ans.* ']);
end
=======
        %system(['rm ',ffdatadir,'mesh_ans.msh ',ffdatadir,'BaseFlow_ans.txt']);
end
>>>>>>> StabFemOriginal/master
