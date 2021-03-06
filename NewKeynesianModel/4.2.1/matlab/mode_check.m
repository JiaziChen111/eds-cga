function mode_check(x,fval,hessian,gend,data,lb,ub,data_index,number_of_observations,no_more_missing_observations)

% function mode_check(x,fval,hessian,gend,data,lb,ub)
% Checks the maximum likelihood mode 
% 
% INPUTS
%    x:       mode
%    fval:    value at the maximum likelihood mode
%    hessian: matrix of second order partial derivatives
%    gend:    scalar specifying the number of observations
%    data:    matrix of data
%    lb:      lower bound
%    ub:      upper bound
%
% OUTPUTS
%    none
%        
% SPECIAL REQUIREMENTS
%    none

% Copyright (C) 2003-2010 Dynare Team
%
% This file is part of Dynare.
%
% Dynare is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Dynare is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

global bayestopt_ M_ options_

TeX = options_.TeX;
if ~isempty(hessian);
    [ s_min, k ] = min(diag(hessian));
end
if options_.dsge_var
    fval = DsgeVarLikelihood(x,gend);
else
    fval = DsgeLikelihood(x,gend,data,data_index,number_of_observations,no_more_missing_observations);    
end    
bayestopt_.penalty=fval;

if ~isempty(hessian);
    disp(' ')
    disp('MODE CHECK')
    disp(' ')
    disp(sprintf('Fval obtained by the minimization routine: %f', fval))
    disp(' ')
    if s_min<eps
        disp(sprintf('Most negative variance %f for parameter %d (%s = %f)', s_min, k , bayestopt_.name{k}, x(k)))
    end
end

[nbplt,nr,nc,lr,lc,nstar] = pltorg(length(x));

if TeX
    fidTeX = fopen([M_.fname '_CheckPlots.TeX'],'w');
    fprintf(fidTeX,'%% TeX eps-loader file generated by mode_check.m (Dynare).\n');
    fprintf(fidTeX,['%% ' datestr(now,0) '\n']);
    fprintf(fidTeX,' \n');
end

for plt = 1:nbplt,
    if TeX
        NAMES = [];
        TeXNAMES = [];
    end
    hh = figure('Name','Check plots');
    for k=1:min(nstar,length(x)-(plt-1)*nstar)
        subplot(nr,nc,k)
        kk = (plt-1)*nstar+k;
        [name,texname] = get_the_name(kk,TeX);
        if TeX
            if isempty(NAMES)
                NAMES = name;
                TeXNAMES = texname;
            else
                NAMES = char(NAMES,name);
                TeXNAMES = char(TeXNAMES,texname);
            end
        end
        xx = x;
        l1 = max(lb(kk),0.5*x(kk));
        l2 = min(ub(kk),1.5*x(kk));
        z = [l1:(l2-l1)/20:l2];
        if options_.mode_check_nolik==0,
            y = zeros(length(z),2);
            dy = priordens(xx,bayestopt_.pshape,bayestopt_.p6,bayestopt_.p7,bayestopt_.p3,bayestopt_.p4);
        end
        for i=1:length(z)
            xx(kk) = z(i);
            if options_.dsge_var
                [fval,cost_flag] = DsgeVarLikelihood(xx,gend);
                if cost_flag
                    y(i,1) = fval;
                else
                    y(i,1) = NaN;
                end               
            else
                [fval,cost_flag] = DsgeLikelihood(xx,gend,data,data_index,number_of_observations,no_more_missing_observations);
                if cost_flag
                    y(i,1) = fval;
                else
                    y(i,1) = NaN;
                end               
            end
            if options_.mode_check_nolik==0
                lnprior = priordens(xx,bayestopt_.pshape,bayestopt_.p6,bayestopt_.p7,bayestopt_.p3,bayestopt_.p4);
                y(i,2)  = (y(i,1)+lnprior-dy);
            end
        end
        plot(z,-y);
        hold on
        yl=get(gca,'ylim');
        plot( [x(kk) x(kk)], yl, 'c', 'LineWidth', 1)
        NaN_index = find(isnan(y(:,1)));
        zNaN = z(NaN_index);
        yNaN = yl(1)*ones(size(NaN_index));
        plot(zNaN,yNaN,'o','MarkerEdgeColor','r','MarkerFaceColor','r','MarkerSize',6);
        title(name,'interpreter','none')
        hold off
        axis tight
        drawnow
    end
    if options_.mode_check_nolik==0,
        if exist('OCTAVE_VERSION'),
            axes('outerposition',[0.3 0.93 0.42 0.07],'box','on'),
        else
            axes('position',[0.3 0.01 0.42 0.05],'box','on'),
        end
        plot([0.48 0.68],[0.5 0.5],'color',[0 0.5 0])
        hold on, plot([0.04 0.24],[0.5 0.5],'b')
        set(gca,'xlim',[0 1],'ylim',[0 1],'xtick',[],'ytick',[])
        text(0.25,0.5,'log-post')
        text(0.69,0.5,'log-lik kernel')
    end
    eval(['print -depsc2 ' M_.fname '_CheckPlots' int2str(plt) '.eps']);
    if ~exist('OCTAVE_VERSION')
        eval(['print -dpdf ' M_.fname '_CheckPlots' int2str(plt)]);
        saveas(hh,[M_.fname '_CheckPlots' int2str(plt) '.fig']);
    end
    if options_.nograph, close(hh), end
    if TeX
        % TeX eps loader file
        fprintf(fidTeX,'\\begin{figure}[H]\n');
        for jj = 1:min(nstar,length(x)-(plt-1)*nstar)
            fprintf(fidTeX,'\\psfrag{%s}[1][][0.5][0]{%s}\n',deblank(NAMES(jj,:)),deblank(TeXNAMES(jj,:)));
        end
        fprintf(fidTeX,'\\centering \n');
        fprintf(fidTeX,'\\includegraphics[scale=0.5]{%s_CheckPlots%s}\n',M_.fname,int2str(plt));
        fprintf(fidTeX,'\\caption{Check plots.}');
        fprintf(fidTeX,'\\label{Fig:CheckPlots:%s}\n',int2str(plt));
        fprintf(fidTeX,'\\end{figure}\n');
        fprintf(fidTeX,' \n');
    end
end