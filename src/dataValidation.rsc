module src::dataValidation

import Prelude;
import src::Logging;
import src::projectFactsRepository;
import ValueIO;
import List;

alias splitDataTuple = tuple[list[str] goodData, list[str] badData]; 

private loc logFile = openLogFile("data-validation-log");
public loc validationResultsDir = |cwd:///validation|;

private str RepositoryTypeSVN = "SvnRepository";
private str RepositoryTypeSVNSync = "SvnSyncRepository";

public list[str] readValidatedProjects() =
	readTextValueFile( #list[str], validationResultsDir + "post-project-level-validation-projects-remaining.value" );

public list[str] readValidatedProjects(int startIndex, int count) {
	list[str] projects = readValidatedProjects();
	return slice( projects, startIndex, count );
}

public list[str] validateDataOnProjectLevel () {

	list[str] projectsRemaining = getProjectNamesInRepository();
	
	logToFile(logFile,"validateData","Starting set of projects: " + toString(size(projectsRemaining)));
	
	splitData = filterProjectsWithBadRepositoryConfiguration(projectsRemaining);
	projectsRemaining = splitData[0];
	projectsExcluded = splitData[1];
	writeTextValueFile(validationResultsDir + "excluded-projects-due-to-bad-repository-config.txt", projectsExcluded);
	logToFile(logFile,"validateData","Projects with bad repository configuration: " + toString(size(projectsExcluded)));
	logToFile(logFile,"validateData","Projects remaining: " + toString(size(projectsRemaining)));
	
	splitData = filterProjectsWithMissingDataFiles(projectsRemaining);
	projectsRemaining = splitData[0];
	projectsExcluded = splitData[1];
	writeTextValueFile(validationResultsDir + "excluded-projects-due-to-missing-all-data.txt", projectsExcluded);
	logToFile(logFile,"validateData","Projects that do not have any data: " + toString(size(projectsExcluded)));
	logToFile(logFile,"validateData","Projects remaining: " + toString(size(projectsRemaining)));
		
	writeTextValueFile(validationResultsDir + "post-project-level-validation-projects-remaining.value", projectsRemaining);
	return projectsRemaining;
}

public splitDataTuple filterProjectsWithBadRepositoryConfiguration(list[str] projects) {
	list[str] goodProjects = [];
	list[str] badProjects = [];
	
	for(project <- projects) {
		repos = getRepositoryFacts(project);
		if(size(repos) == 0 || size(findInvalidSVNRepositories(repos)) > 0) {
			badProjects += project;
		}
		else {
			goodProjects += project;
		}
	};
	
	if(size(goodProjects + badProjects) != size(projects)) {
		logToFile(logFile,"filterProjectsWithMissingDataParts",
					 "WARNING input data size " + toString(size(projects)) + " " +
					 "does not match sum of good and bad data sizes: " +
					 toString(size(goodProjects)) + ", " + toString(size(badProjects))
					 );
	}
	return <goodProjects,badProjects>;	
}

public splitDataTuple filterProjectsWithMissingDataFiles(list[str] projects) {
	list[str] goodProjects = [];
	list[str] badProjects = [];
	
	for(project <- projects) {
		if(size(getActivityFacts(project)) == 0 &&
		   size(getSizeFacts(project)) == 0) {
		   	badProjects += project;
		}
		else {
			goodProjects += project;
		}
	};
	
	if(size(goodProjects + badProjects) != size(projects)) {
		logToFile(logFile,"filterProjectsWithMissingDataFiles",
					 "WARNING input data size " + toString(size(projects)) + " " +
					 "does not match sum of good and bad data sizes: " +
					 toString(size(goodProjects)) + ", " + toString(size(badProjects))
					 );
	}
	return <goodProjects,badProjects>;	
}

public repositoriesRel findInvalidSVNRepositories(repositoriesRel repositoryFacts) {
	return {
		<projectName, repositoryType, repositoryURL> |
		<str projectName, str repositoryType, str repositoryURL> <- repositoryFacts,
		repositoryType := RepositoryTypeSVN || repositoryType := RepositoryTypeSVNSync,
		!(
		 /.*\/trunk\/?/i      := repositoryURL ||
		 /.*\/head\/?/i       := repositoryURL ||
		 /.*\/sandbox\/?/i    := repositoryURL ||
		 /.*\/site\/?/i       := repositoryURL ||
		 /.*\/branches\/\w+/i := repositoryURL ||
		 /.*\/tags\/\w+/i     := repositoryURL
		)
	};
}

public repositoriesRel findAllInvalidSVNRepositories() {
	return findInvalidSVNRepositories(
	         getRepositoryFactsForProjects(
	           getProjectNamesInRepository()));
}

public bool hasInvalidSVNRepositories(str projectName) {
	return size(findInvalidSVNRepositories(
		          getRepositoryFactsForProjects([projectName])))
		   > 0;
}


