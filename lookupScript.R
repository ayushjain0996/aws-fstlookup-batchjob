#This is code for batch jobs to loojup input values in the compressed FST file and get the corresponding outputs

library('aws.s3')
library('fst')
library('magrittr')
library('dplyr')
library(paws)
library(aws.ec2metadata)

#IAM role access to retrieve ACCESS KEYS
setAccessSecretKeys <- function(roleName, region = "us-west-2"){
	(role <- metadata$iam_info())
	print(paste0('IAM info is ', role))
	if(!is.null(role)){
		r = metadata$iam_role(roleName)
		Sys.setenv(
			"AWS_ACCESS_KEY_ID" = r$AccessKeyId,
			"AWS_SECRET_ACCESS_KEY" = r$SecretAccessKey,
			"AWS_SESSION_TOKEN" = r$Token,
			"AWS_DEFAULT_REGION" = region
		)
	}
}

#Function to get the object key of the latest compressed fst file
getObjectKey <- function(){
	svc <- dynamodb(
		config = list(region = "us-west-2")
	)

	queryResult <- svc$query(
		ExpressionAttributeValues = list(
			`:objectStatus` = list(
				S = "Active"
			),
			`:folderName` = list(
				S = "yusjain/output"
			)
		),
		KeyConditionExpression = "FolderName = :folderName",
		FilterExpression = "ObjectStatus = :objectStatus",
		ProjectionExpression = "FileName",
		TableName = "yusjainJobRecords"
	)
	tsvFileName = queryResult$Items[[1]]$FileName$S
	outputKey <- substr(tsvFileName, 0, 14)
	fileExt = '.fst'
	compressedFileKey = paste0(outputKey, fileExt)
	return (compressedFileKey)
}

#Function to read the file from the output bucket given the file key.
#It prints out the output values only corresponding to the given input values
printOutputs <- function(objectKey, input1Value, input2Value){
	tsvfile <- tempfile(fileext = ".fst")
	save_object(file = tsvfile, object = objectKey, bucket = "yusjainoutput")
	data <- read_fst(tsvfile)

	print("Output corresponding to given outputs:")
	result <- data %>% filter(input1 == input1Value, input2 == input2Value)
	print(result)
}

#Main function
getOutput <- function(){
	setAccessSecretKeys('IAM-RoleName')
	args <- commandArgs(TRUE)
	input1Value <- args[1]
	input2Value <- args[2]

	outputObjectKey <- getObjectKey()
	print("Compressed File Path:")
	print(outputObjectKey)

	printOutputs(outputObjectKey, input1Value, input2Value)
}

getOutput()

