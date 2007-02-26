function write_htk_hmm(filename, hmms, desc)
% write_htk_hmm(filename, hmm, feature_description)
%
% Write the HMM(s) contained in hmm (hmm can be an array of HMMs) to
% an HTK formatted file.
%
% 2006-06-13 ronw@ee.columbia.edu

if nargin < 3
  desc = '<USER>';
  %desc = '<MFCC>';
end

nstates = length(hmms(1).transmat);
if strcmp(hmms(1).emission_type, 'gaussian')
  ndim = size(hmms(1).means, 1);
else
  gmm = hmms(1).gmms(1);
  ndim = size(gmm.means, 1);
end

fid = fopen(filename, 'w');

fprintf(fid, '~o\n');
fprintf(fid, '<VecSize> %d %s\n', ndim, desc);


for x = 1:length(hmms)
  hmm = hmms(x);
  
  nstates = hmm.nstates;

  if isfield(hmm, 'name')
    name = hmm.name;
  else 
    name = 'matlabhmm';
  end
  
  fprintf(fid, '~h "%s"\n', name);
  fprintf(fid, '<BeginHMM>\n');
  %fprintf(fid, '<VecSize> %d\n', ndim);
  %fprintf(fid, '  <VecSize> %d %s\n', ndim, desc);
  fprintf(fid, '  <NumStates> %d\n', nstates+2);
  
  for n = 1:nstates
    if strcmp(hmm.emission_type, 'gaussian')
      fprintf(fid, '  <State> %d\n    <Mean> %d\n     ', n+1, ndim);
      fprintf(fid, ' %f', hmm.means(:,n));
      fprintf(fid, '\n    <Variance> %d\n     ', ndim);
      fprintf(fid, ' %f', hmm.covars(:,n));
      fprintf(fid, '\n');
    else  % we have GMM emissions
      nmix = hmm.gmms(n).nmix;
      fprintf(fid, '  <State> %d\n    <NumMixes> %d\n     ', n+1, nmix);
      for m = 1:nmix
        fprintf(fid, '<MIXTURE> %d %f\n', m, exp(hmm.gmms(n).priors(m)));
        fprintf(fid, '  <MEAN> %d\n   ', length(hmm.gmms(n).means(:,m)));
        fprintf(fid, ' %f', hmm.gmms(n).means(:,m));
        fprintf(fid, '\n  <VARIANCE> %d\n   ', length(hmm.gmms(n).covars(:,m)));
        fprintf(fid, ' %f', hmm.gmms(n).covars(:,m));
        fprintf(fid, '\n');
      end
    end
  end
  
  % transmat
  fprintf(fid, '  <TransP> %d\n', nstates+2);
  
  end_prob = exp(hmm.end_prob);
  if size(end_prob, 1) == 1
    end_prob = end_prob';
  end
  % the first state is non emitting
  transmat = [0, exp(hmm.start_prob), 0; ...
        zeros(nstates, 1), exp(hmm.transmat), end_prob; ...
        % the last state is also non emitting
        zeros(1, nstates+2)];
      
  for n = 1:nstates+2
    fprintf(fid, ' %f', transmat(n,:));
    fprintf(fid, '\n'); 
  end
  
  fprintf(fid, '<EndHMM>\n');
end

fclose(fid);
      
