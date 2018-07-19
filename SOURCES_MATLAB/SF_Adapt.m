%> @file SOURCES_MATLAB/SF_Adapt.m
%> @brief Matlab driver for Mesh Adaptation
%>
%> @param[in] baseflow: baseflow on which the adaptation is performed
%> @param[in] (eigenmode): if provided, eigenmode on which the adaptation is performed
%> @param[out] baseflow: baseflow recomputed on adapted mesh
%> @param[out] (eigenmode): if asked, eigenmode recomputed on adapted mesh
%>
%> With only one argument, adaptation will be done on base flow only.
%> With two arguments, adaptation is performed on base flow and eigen-
%> mode structures.
%> This method returns the baseflow on adapted mesh, and may return
%> the eigenmode on this new mesh if asked. The latter works fine in
%> 2D but is not recommended.
%>
%> @author David Fabre
%> @version 2.1
%> @date 02/07/2017 Release of version 2.1
function [baseflow, eigenmode] = SF_Adapt(varargin)
global ff ffdir ffdatadir sfdir verbosity

% managament of optional parameters
% NB here the parser had to be customized because input parameter number 2
% is optional and is a structure ! we should find a better way in future
p = inputParser;
if (mod(nargin, 2) == 1)
    % input mode for adaptation to base flow
    baseflow = varargin{1};
    eigenmode = 0;
    vararginopt = {varargin{2:end}};
else
    % input mode for adaptation to base flow
    baseflow = varargin{1};
    eigenmode = varargin{2};
    vararginopt = {varargin{3:end}};
end
%    addRequired(p,'baseflow');
%    addOptional(p,'eigenmode',0);
addParameter(p, 'Hmax', 10);
addParameter(p, 'Hmin', 1e-4);
addParameter(p, 'Ratio', 10.);
addParameter(p, 'InterpError', 1e-2);
addParameter(p, 'rr', 0.95);
addParameter(p, 'Splitin2', 0);
parse(p, vararginopt{:});

% mycp('mesh.msh','mesh_ans.msh');
% mycp('BaseFlow.txt','BaseFlow_ans.txt');

%%% Writing parameter file for Adapmesh
fid = fopen('Param_Adaptmesh.edp', 'w');
fprintf(fid, '// Parameters for adaptmesh (file generated by matlab driver)\n');
fprintf(fid, ['real Hmax = ', num2str(p.Results.Hmax), ' ;']);
fprintf(fid, ['real Hmin = ', num2str(p.Results.Hmin), ' ;']);
fprintf(fid, ['real Ratio = ', num2str(p.Results.Ratio), ' ;']);
fprintf(fid, ['real error = ', num2str(p.Results.InterpError), ' ;']);
fprintf(fid, ['real rr = ', num2str(p.Results.rr), ' ;']);
if (p.Results.Splitin2 == 0)
    fprintf(fid, ['bool Splitin2 = false ;']);
else
    fprintf(fid, ['bool Splitin2 = true ;']);
end
fclose(fid);

%mydisp(3,' ');


mydisp(1, ['### ENTERING SF_ADAPT'])

if (isnumeric(eigenmode) == 1) %% if no eigenmode is provided as input : adapt to base flow only
    command = ['echo BFonly | ', ff, ' ', ffdir, 'Adapt_Mode.edp'];
    error = 'ERROR : FreeFem adaptmesh aborted';
    mysystem(command, error);
    meshnp = importFFmesh('mesh.msh', 'nponly');
    mydisp(1, ['### ADAPT mesh to base flow ', ... % for Re = ' num2str(baseflow.Re)...
        ' ; InterpError = ', num2str(p.Results.InterpError), '  ; Hmax = ', num2str(p.Results.Hmax)])
    if (verbosity >= 1)
        meshinfo = importFFdata(baseflow.mesh, 'mesh.ff2m');
        mydisp(3, ['      #   Number of points np = ', num2str(meshinfo.np), ...
            ' ; Ndof = ', num2str(meshinfo.Ndof)]);
        mydisp(3, ['      #  h_min, h_max : ', num2str(meshinfo.deltamin), ' , ', ...
            num2str(meshinfo.deltamax)]);
        %  mydisp(1,['      # h_(A,B,C,D) : ',num2str(meshinfo.deltaA),' , ',...
        %        num2str(meshinfo.deltaB),' , ',num2str(meshinfo.deltaC),' , ',num2str(meshinfo.deltaD) ]);
    end
    
    
else % Adaptation to base flow + mode (or other specified field)
    if (strcmp(baseflow.mesh.problemtype, 'AxiXR') == 1)
        if (strcmp(eigenmode.type, 'D') == 1)
            command = ['echo UVWP | ', ff, ' ', ffdir, 'Adapt_Mode.edp'];
            mycp([ffdatadir, 'Eigenmode.txt'], [ffdatadir, 'AdaptField.txt']);
        elseif (strcmp(eigenmode.type, 'A') == 1)
            command = ['echo UVWP | ', ff, ' ', ffdir, 'Adapt_Mode.edp'];
            mycp([ffdatadir, 'EigenmodeA.txt'], [ffdatadir, 'AdaptField.txt']);
        else %if(strcmp(eigenmode.type,'S')==1)
            command = ['echo Sensitivity | ', ff, ' ', ffdir, 'Adapt_Mode.edp'];
            mycp([ffdatadir, 'Sensitivity.txt'], [ffdatadir, 'AdaptField.txt']);
            %        mycp([ffdatadir 'Eigenmode.txt'],[ffdatadir 'AdaptField.txt']);
            %        command = ['echo UVWP | ',ff,' ',ffdir,'Adapt_Mode.edp'];
        end
    elseif (strcmp(baseflow.mesh.problemtype, '2DComp') == 1)
        if (strcmp(eigenmode.type, 'D') == 1)
            command = ['echo Comp | ', ff, ' ', ffdir, 'Adapt_Mode.edp'];
            system(['cp ', ffdatadir, 'Eigenmode.txt ', ffdatadir, 'AdaptField.txt']);
        elseif (strcmp(eigenmode.type, 'A') == 1)
            command = ['echo Comp | ', ff, ' ', ffdir, 'Adapt_Mode.edp'];
            system(['cp ', ffdatadir, 'EigenmodeA.txt ', ffdatadir, 'AdaptField.txt']);
        else %if(strcmp(eigenmode.type,'S')==1)
            command = ['echo Sensitivity | ', ff, ' ', ffdir, 'Adapt_Mode.edp'];
            system(['cp ', ffdatadir, 'Sensitivity.txt ', ffdatadir, 'AdaptField.txt']);
        end
    elseif (strcmp(baseflow.mesh.problemtype, '2D') == 1)
        if (strcmp(eigenmode.type, 'D') == 1)
            command = ['echo UVP | ', ff, ' ', ffdir, 'Adapt_Mode.edp'];
            mycp([ffdatadir, 'Eigenmode.txt'], [ffdatadir, 'AdaptField.txt']);
        elseif (strcmp(eigenmode.type, 'A') == 1)
            command = ['echo UVP | ', ff, ' ', ffdir, 'Adapt_Mode.edp'];
            mycp([ffdatadir, 'EigenmodeA.txt'], [ffdatadir, 'AdaptField.txt']);
        else %if(strcmp(eigenmode.type,'S')==1)
            command = ['echo Sensitivity | ', ff, ' ', ffdir, 'Adapt_Mode.edp'];
            mycp([ffdatadir, 'Sensitivity.txt'], [ffdatadir, 'AdaptField.txt']);
        end
    elseif(strcmp(baseflow.mesh.problemtype,'AxiXRPOROUS')==1)
        if(strcmp(eigenmode.type,'D')==1)
            command = ['echo UVWP | ',ff,' ',ffdir,'Adapt_Mode.edp'];
            mycp([ffdatadir 'Eigenmode.txt'],[ffdatadir 'AdaptField.txt']);
        elseif(strcmp(eigenmode.type,'A')==1)
             command = ['echo UVWP | ',ff,' ',ffdir,'Adapt_Mode.edp'];
             mycp([ffdatadir 'EigenmodeA.txt'],[ffdatadir 'AdaptField.txt']);
        else %if(strcmp(eigenmode.type,'S')==1)
             command = ['echo Sensitivity | ',ff,' ',ffdir,'Adapt_Mode.edp'];
             mycp([ffdatadir 'Sensitivity.txt'],[ffdatadir 'AdaptField.txt']);
        end
        
        % elseif(..) for possible other drivers
    end
    error = 'ERROR : FreeFem adaptmesh aborted';
    status = mysystem(command, 'skip');
    if (status ~= 0 && status ~= 141)
        mymv([ffdatadir, 'mesh_ans.msh'], [ffdatadir, 'mesh.msh']);
        mymv([ffdatadir, 'BaseFlow_ans.txt'], [ffdatadir, 'BaseFlow.txt']);
        mymv([ffdatadir, 'BaseFlow_ans.txt'], [ffdatadir, 'BaseFlow_guess.txt']);
        error(' ERROR in SF_Adapt : recomputing base flow failed, going back to baseflow/mesh')
    end
    %    meshnp = importFFmesh('mesh_adapt.msh','nponly'); // old version to
    %    discard this and correct soon
    
    mydisp(1, ['### ADAPT mesh to base flow AND MODE ( type ', eigenmode.type, ... ' )  for Re = ' num2str(baseflow.Re)...
        ' ) ; InterpError = ', num2str(p.Results.InterpError), '  ; Hmax = ', num2str(p.Results.Hmax)])
    %     mydisp(1,[' ; Number of points np = ',num2str(meshinfo.np) ' ; Ndof = ' num2str(meshinfo.Ndof)]; ])
    if (verbosity >= 1)
        meshinfo = importFFdata(baseflow.mesh, 'mesh.ff2m');
        mydisp(3, ['#   Number of points np = ', num2str(meshinfo.np), ...
            ' ; Ndof = ', num2str(meshinfo.Ndof)]);
        mydisp(3, ['#  deltamin, deltapax : ', num2str(meshinfo.deltamin), ' , ', ...
            num2str(meshinfo.deltamax)]);
        %  mydisp(1,['      #  delta_(A,B,C,D) : ',num2str(meshinfo.deltaA),' , ',...
        %        num2str(meshinfo.deltaB),' , ',num2str(meshinfo.deltaC),' , ',num2str(meshinfo.deltaD) ]);
    end
end


%previous method
%    meshNew=importFFmesh([ffdatadir 'mesh.msh'])
%    baseflowNew = importFFdata(meshNew,'BaseFlow_Adapted.ff2m')
%    baseflowNew = SF_BaseFlow(baseflowNew,'Re',baseflow.Re,'type','NEW');

%new method (does not require to generate a BaseFlow.ff2m in Adapt)
baseflowNew = SF_BaseFlow(baseflow, 'type', 'POSTADAPT');

if (baseflowNew.iter > 0)
    %  Newton successful : store base flow
    baseflow = baseflowNew;
    
    % Store adapted mesh/base flow in directory "MESHES"
    baseflow.mesh.namefile = [ffdatadir, 'MESHES/mesh_adapt_Re', num2str(baseflow.Re), '.msh'];
    mycp([ffdatadir, 'mesh.msh'], [ffdatadir, 'MESHES/mesh_adapt_Re', num2str(baseflow.Re), '.msh']);
    mycp([ffdatadir, 'mesh.ff2m'], [ffdatadir, 'MESHES/mesh_adapt_Re', num2str(baseflow.Re), '.ff2m']);
    mycp([ffdatadir, 'BaseFlow.txt'], [ffdatadir, 'MESHES/BaseFlow_adapt_Re', num2str(baseflow.Re), '.txt']);
    mycp([ffdatadir, 'BaseFlow.ff2m'], [ffdatadir, 'MESHES/BaseFlow_adapt_Re', num2str(baseflow.Re), '.ff2m']);
    
    
    % clean 'BASEFLOWS' directory to avoid mesh/baseflow incompatibilities
    myrm([ffdatadir, 'BASEFLOWS/BaseFlow*']);
    mycp([ffdatadir, 'BaseFlow.txt'], [ffdatadir, 'BASEFLOWS/BaseFlow_Re', num2str(baseflow.Re), '.txt']);
    mycp([ffdatadir, 'BaseFlow.ff2m'], [ffdatadir, 'BASEFLOWS/BaseFlow_Re', num2str(baseflow.Re), '.ff2m']);
    baseflow.namefile = [ffdatadir, 'BASEFLOWS/BaseFlow_Re', num2str(baseflow.Re), '.txt'];
    
    % in case requested, recompute the eigenmode as well
    % NB IN FUTURE VERSIONS IT IS NOT RECOMMENDED ANY MORE TO RECOMPUTE
    % EIGENMODES IN AN AUTOMATICAL WAY....
    if (nargout == 2 && isnumeric(eigenmode) == 0)
        if (strcmp(baseflow.mesh.problemtype, 'AxiXR') == 1)
            [ev, eigenmode] = SF_Stability(baseflow, 'm', eigenmode.m, 'shift', eigenmode.lambda, 'nev', 1, 'type', eigenmode.type);
        elseif (strcmp(baseflow.mesh.problemtype, '2D') == 1)
            if (strcmp(eigenmode.type, 'D') == 1)
                mycp([ffdatadir, 'AdaptField_guess.txt'], [ffdatadir, 'Eigenmode_guess.txt']);
            else
                myrm([ffdatadir, 'Eigenmode_guess.txt']);
            end
            [ev, eigenmode] = SF_Stability(baseflow, 'shift', eigenmode.lambda, 'nev', 1, 'type', eigenmode.type);
        end
    end
else % Newton has probably diverged : revert to previous mesh/baseflow
    mymv([ffdatadir, 'mesh_ans.msh'], [ffdatadir, 'mesh.msh']);
    mymv([ffdatadir, 'BaseFlow_ans.txt'], [ffdatadir, 'BaseFlow_guess.txt']);
    error(' ERROR in SF_Adapt : recomputing base flow failed, going back to baseflow/mesh')
end
myrm([ffdatadir, '*_ans.* ']);
end