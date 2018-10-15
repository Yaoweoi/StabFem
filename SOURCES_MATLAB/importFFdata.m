function pdestruct = importFFdata(varargin)
%  function importFFdata
%  Imports data generated by freefem
%  Usage :
%  1/ pdestruct=importFFdata(fileToRead1 [,fileToRead2,..] )
%      to import files in ff2m format containing only scalar data (int,real,complex)
%
%  2/ pdestruct=importFFdata(mesh,fileToRead1 [,fileToRead2,..] )
%      to import files in ff2m format containing mesh-related data (P1, ..)
%      Here mesh is a structure previously imported through importFFmesh.
%
%      imported data may comprise several pde fields and scalar values,
%      as defined in header (2nd line of file) with has the form :
%      typedata1 namedata1 typedata2 namedata2 (...)
%      typedata may be of the following types :
%           - real -> one real scalar
%           - complex -> complex number read as two reals
%           - P1 -> P1 field (compatible with the mesh)
%           - P1c -> P1 complex field
%      (to be implemented : P1L -> 1D P1 field along a boundary of the mesh)
%
%  Result is stored in a structure pdestruct
%


global ff ffdir ffdatadir sfdir verbosity

mydisp(15, ['  ENTERING FUNCTION  importFFdata.m']);

if (ischar(varargin{1}) == 0)
    % if first argument is a mesh structure, take dimension np from it
    mesh = varargin{1};
    pdestruct.mesh = mesh;
    istart = 2;
    np = mesh.np;
    if (isfield(mesh, 'nsurf')) nsurf = mesh.nsurf;
    else nsurf = 0;
    end
    %  if(isfield(mesh,'nsurfFOU')) nsurfFOU = mesh.nsurfFOU; else nsurfFOU=0; end
else
    % if all arguments are file names, only real,int,complex data are expected
    istart = 1;
    np = 0;
    nsurf = 0;
    %    nsurfFOU=0;
end

%pdestruct.filename=varargin{istart:nargin};
for i = istart:nargin
    fileToRead = varargin{i};
    
    if(exist(fileToRead) == 0)
    if (exist([ffdatadir, fileToRead]) == 2)
        fileToRead = [ffdatadir, fileToRead];
    else
        error(['Error in importFFdata : file ', fileToRead, ' does not exist !!']); 
    end
    end
    
    mydisp(15, ['      Function importFFdata : reading file ', fileToRead]);
    rawData1 = importdata(fileToRead);
    mydisp(15, ['      FUNCTION  importFFdata.m : reading file ', fileToRead]);
    data = rawData1.data;
    
    if (np > 0) %% && i == istart) DAVID
        % file contains mesh-related data and is likely associated to a .txt
        % file containing plain freefem data
        [filepath, name, ext] = fileparts(fileToRead);
        pdestruct.filename = [filepath, '/', name, '.txt'];
    end
    %interprets the first four lines in the file
    Datadescription = rawData1.textdata{2};
    pdestruct.DataDescription = Datadescription;
    keawords = rawData1.textdata{3};
    header = rawData1.textdata{4};
    description = textscan(header, '%s');
    numfields = length(description{1}) / 2;
    if(mod(numfields,1)~=0)
        error(['Error in importFFdata : wrong number of words at line 4 of header of file ',fileToRead]);
    end
    words = textscan(keawords, '%s');
    
    numkeywords = length(words{1});
    K1 = words{1}{1};
    
    if sum(strcmp(lower(K1), {'format','format:'}))
        mydisp(0, 'Warning : third line or data file is "Format :" ; this is obsolete ! please modify your Macro_StabFem.edp to fit to new format (see manual)');
        mydisp(0,' you may replace by something like (for a baseflow) ''file << "datatype BaseFlow datastoragemode ReP2P2P1.1 " << endl'' ;');
        mydisp(0,'                                   (for a eigenmode) ''file << "datatype Eigenmode datastoragemode CxP2P2P1.2 " << endl'' ;');
        mydisp(0,'                                   (for a mesh) ''file << "datatype mesh meshtype 2D " << endl;'' ;');
        mydisp(0,'                                   (for file SF_Geom.ff2m) ''file << "problemtype 2D " << endl;'' ;');
        pdestruct.datatype = Datadescription;
    else
        if mod(numkeywords, 2)
            error('Error in importFFdata : number of words at third line of file should be an even number')
        else
            for i = 1:2:numkeywords - 1
                keywordname = words{1}{i};
                keywordvalue = words{1}{i + 1};
                pdestruct = setfield(pdestruct, keywordname, keywordvalue);
                mydisp(15, ['      Function importFFdata : setting keyword ''', keywordname, ' '' =  ''', keywordvalue, '''']);
                
            end
        end
    end
    if (isfield(pdestruct,'datatype')&&((strcmp(lower(pdestruct.datatype),'timestatistics')==1)...
                                        ||(strcmp(lower(pdestruct.datatype),'forcedlinear')==1)))
    %% the data file is a time series (most likely coming from DNS)
    indexdata = 1;
    Ndata = 0;    
    for ifield = 1:numfields
        typefield = description{1}{2 * ifield - 1};
        namefield = description{1}{2 * ifield};
            switch (typefield)
            case ('real')
                value = data(:,indexdata);
                indexdata = indexdata + 1;
                pdestruct = setfield(pdestruct, namefield, value);
                mydisp(15, ['      Function importFFdata : reading real tab. in TimeStatistics data']);
  
            case ('complex')
                valuer = data(:,indexdata);
                indexdata = indexdata + 1;
                valuei = data(:,indexdata);
                indexdata = indexdata + 1;
                pdestruct = setfield(pdestruct, namefield, valuer+1i*valuei);
                mydisp(15, ['      Function importFFdata : reading complex tab. in TimeStatistics data']);

            
             case(default)
                    error('wrong type of data in file !')
        end
    end
    
    
    else    
    %% the data is a usual file
    
    
    %determines the kind of numerical data to be read in the file,
    % and checks if the number of numerical data is consistent
    indexdata = 1;
    Ndata = 0;
    for ifield = 1:numfields
        typefield = description{1}{2 * ifield - 1};
        namefield = description{1}{2 * ifield};
        [dumb, typefield, suffix] = fileparts(typefield);
        if (length(suffix) == 0)
            sizefield(ifield) = 1;
        else
            sizefield(ifield) = str2num(suffix(2:end));
        end
        
        switch (typefield)
            case ('real')
                Ndata = Ndata + sizefield(ifield);
            case ('int')
                Ndata = Ndata + sizefield(ifield);
            case ('complex')
                Ndata = Ndata + 2 * sizefield(ifield);
            case ('P1')
                if (np == 0) error('ERROR in importFFdata : to import P1 data a mesh must be specified as first argument to the function');
                end
                Ndata = Ndata + np;
            case ('P1c')
                if (np == 0) error('ERROR in importFFdata : to import P1c data a mesh must be specified as first argument to the function');
                end
                Ndata = Ndata + 2 * np;
            case ('P1surf')
                Ndata = Ndata + nsurf;
            case ('P1surfc')
                Ndata = Ndata + 2 * nsurf;
        end
    end
    
    if (istart == 2 && Ndata ~= length(data))
         disp(['### Error in importFFdata : wrong data number ; expecting ', num2str(Ndata), ' reading ', num2str(length(data)), ...
            '  (Mesh may be incompatible)']);
         disp(['### When reading  data file : ',fileToRead]);
         disp(['### Associated to mesh file : ',mesh.filename]);
         error('stop here');
    end
    
    for ifield = 1:numfields
        typefield = description{1}{2 * ifield - 1};
        [dumb, typefield, suffix] = fileparts(typefield);
        namefield = description{1}{2 * ifield};
        switch (typefield)
            case ('real')
                value = data(indexdata:indexdata+sizefield(ifield)-1);
                indexdata = indexdata + sizefield(ifield);
                pdestruct = setfield(pdestruct, namefield, value);
                mydisp(15, ['      Function importFFdata : reading real(', num2str(sizefield(ifield)), ') field : ', namefield, ' = ', num2str(value(1))]);
            case ('int')
                value = data(indexdata:indexdata+sizefield(ifield)-1);
                indexdata = indexdata + sizefield(ifield);
                pdestruct = setfield(pdestruct, namefield, value);
                mydisp(15, ['      Function importFFdata : reading int(', num2str(sizefield(ifield)), ') field : ', namefield, ' = ', num2str(value(1))]);
            case ('complex')
                valueR = data(indexdata:2:indexdata+2*sizefield(ifield)-2);
                valueI = data(indexdata+1:2:indexdata+2*sizefield(ifield)-1);
                indexdata = indexdata + 2 * sizefield(ifield);
                pdestruct = setfield(pdestruct, namefield, valueR+1i*valueI);
                mydisp(15, ['      Function importFFdata : reading complex(', num2str(sizefield(ifield)), ') field : ', namefield, ' = ', num2str(valueR(1)+1i*valueI(1))]);
            case ('P1')
                value = data(indexdata:indexdata+np-1);
                indexdata = indexdata + np;
                pdestruct = setfield(pdestruct, namefield, value);
                mydisp(15, ['      Function importFFdata : reading P1 field : ', namefield, ' (dimension = ', num2str(np), ' )']);
            case ('P1c')
                value = data(indexdata:indexdata+2*np-1);
                valueC = value(1:2:end-1) + 1i * value(2:2:end);
                indexdata = indexdata + 2 * np;
                pdestruct = setfield(pdestruct, namefield, valueC);
                mydisp(15, ['      Function importFFdata : reading P1c field : ', namefield, ' (dimension = ', num2str(np), ' )']);
            case ('P1surf')
                if (istart == 2 && isfield(mesh, 'nsurf') == 1)
                    nsurf = mesh.nsurf;
                elseif (istart == 1 && isfield(pdestruct, 'nsurf') == 1)
                    nsurf = pdestruct.nsurf;
                else
                    error('ERROR in importFFdata : trying to import P1surf field but nsurf is not defined !')
                end
                value = data(indexdata:indexdata+nsurf-1);
                indexdata = indexdata + nsurf;
                pdestruct = setfield(pdestruct, namefield, value);
                mydisp(15, ['      Function importFFdata : reading P1surf field : ', namefield, ' (dimension = ', num2str(nsurf), ' )']);
                
            case ('P1surfc')
                if (istart == 2 && isfield(mesh, 'nsurf') == 1)
                    nsurf = mesh.nsurf;
                elseif (istart == 1 && isfield(pdestruct, 'nsurf') == 1)
                    nsurf = pdestruct.nsurf;
                else
                    error('ERROR in importFFdata : trying to import P1surf field but nsurf is not defined !')
                end
                value = data(indexdata:indexdata+2*nsurf-1);
                valueC = value(1:2:end-1) + 1i * value(2:2:end);
                indexdata = indexdata + 2 * nsurf;
                pdestruct = setfield(pdestruct, namefield, valueC);
                mydisp(15, ['      Function importFFdata : reading P1surfC field : ', namefield, ' (dimension = ', num2str(nsurf), ' )']);
        end
    end
    end
    
    mydisp(15, ['  END FUNCTION  importFFdata.m']);
    
end
