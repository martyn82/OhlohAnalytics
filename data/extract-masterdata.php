#!/usr/bin/env php
<?php

const CSV_DELIMITER = ';';
const CSV_ENCLOSURE = '"';

$projectNamesList = 'ProjectNamesList.txt';
$projectDataFolder = 'projects/';
$finalProjectsFile = 'projects.csv';

if ( !file_exists( $projectNamesList ) ) {
	fwrite( STDERR, "ERROR: File not found: {$projectNamesList}." . PHP_EOL );
	exit( 1 );
}

$finalFileHandle = fopen( $finalProjectsFile, 'w' );
fputcsv( $finalFileHandle, array( 'project_id', 'project_name' ), CSV_DELIMITER, CSV_ENCLOSURE );

$projectNamesHandle = fopen( $projectNamesList, 'rb' );

$count = 0;
$failed = 0;

while ( !feof( $projectNamesHandle ) ) {
	$projectName = trim( fgets( $projectNamesHandle ) );
	
	if ( empty( $projectName ) ) {
		continue;
	}
		
	fwrite( STDERR, "Project: {$projectName}" . PHP_EOL );
	
	$projectDataFile = $projectDataFolder . $projectName . '/MetaData.xml';
	
	if ( !file_exists( $projectDataFile ) ) {
		fwrite( STDERR, "WARNING: No metdata found for project: '{$projectName}'." . PHP_EOL );
		$failed++;
		continue;
	}
	
	$xmlString = file_get_contents( $projectDataFile );
	$xml = new SimpleXMLElement( $xmlString );
	$values = $xml->xpath( '/response/result/project/id' );
	$projectId = (string) reset( $values );
	
	$data = array( $projectId, $projectName );
	fputcsv( $finalFileHandle, $data, CSV_DELIMITER, CSV_ENCLOSURE );
	
	$count++;
}

fclose( $projectNamesHandle );
fclose( $finalFileHandle );

fwrite(
	STDERR,
	"{$count} projects"
		. PHP_EOL
		. "{$failed} failed"
		. PHP_EOL
		. "Done"
		. PHP_EOL
);
