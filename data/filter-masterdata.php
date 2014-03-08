#!/usr/bin/env php
<?php

/* This script will filter out all projects from ValidatedProjectNamesListWithIds that do not appear in sample.csv
 * and outputs the result to SampleProjectNamesListWithIds.
 */

$filterFile = 'sample.csv';
$inputFile = 'ValidatedProjectNamesListWithIds.csv';
$outputFile = 'SampleProjectNamesListWithIds.csv';

$filterHandle = fopen( $filterFile, 'r' );
$filterHeader = fgetcsv( $filterHandle ); // header
$projectData = array();

while ( !feof( $filterHandle ) ) {
	$dataLine = fgetcsv( $filterHandle );
	
	if ( empty( $dataLine ) ) {
		continue;
	}
	
	$dataLine = array_combine( $filterHeader, $dataLine );
	$projectData[ $dataLine[ 'new.projects.id' ] ] = $dataLine[ 'new.projects.name' ];
}
fclose( $filterHandle );

$inputHandle = fopen( $inputFile, 'r' );
$outputHandle = fopen( $outputFile, 'w' );

$header = fgetcsv( $inputHandle, null, ';' );
fputcsv( $outputHandle, $header, ';' );

$projectIds = array();
$totalProjects = 0;

while ( !feof( $inputHandle ) ) {
	$dataLine = fgetcsv( $inputHandle, null, ';' );
	
	if ( empty( $dataLine ) ) {
		continue;
	}
	
	$totalProjects++;
	$dataLine = array_combine( $header, $dataLine );
	
	$projectId = $dataLine[ 'project_id' ];
	
	if ( !isset( $projectData[ $projectId ] ) ) {
		continue;
	}
	
	fputcsv( $outputHandle, $dataLine, ';' );

	if ( !isset( $projectIds[ $projectId ] ) ) {
		$projectIds[ $projectId ] = 1;
	}
	else {
		$projectIds[ $projectId ]++;
	}
}

fclose( $outputHandle );
fclose( $inputHandle );

$projects = count( $projectIds );
fwrite( STDERR, "Filtered {$totalProjects} projects to a sample of {$projects} projects." . PHP_EOL );
